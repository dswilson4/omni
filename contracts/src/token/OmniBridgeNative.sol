// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IOmniPortal } from "../interfaces/IOmniPortal.sol";
import { OmniBridgeL1 } from "./OmniBridgeL1.sol";
import { ConfLevel } from "../libraries/ConfLevel.sol";
import { XTypes } from "../libraries/XTypes.sol";

/**
 * @title OmniBridgeNative
 * @notice The Omni side of Omni's native token bridge. Partner to OmniBridgeL1, which is deployed to Ethereum.
 *         This contract is predeployed to Omni's EVM, prefunded with native OMNI tokens to match totalL1Supply, such
 *         that each L1 token has a "sibling" native token on Omni.
 * @dev This contract is predeployed, and requires storage slots to be set in genesis.
 *      Genesis storage slots must:
 *          - set _owner on proxy
 *          - set _initialized on proxy to 1, to disable the initializer
 *          - set _initialized on implementation to 255, to disabled all initializers
 *      We currently do now have any onlyOwner methods, but we inherit from OwnableUpgradeable let us
 *      add them in the future.
 */
contract OmniBridgeNative is OwnableUpgradeable {
    /**
     * @notice Emitted when an account Deposits OMNI tokens to this contract.
     */
    event Deposit(address indexed from, uint256 amount);

    /**
     * @notice Emitted when OMNI tokens are withdrawn for an account.
     *         If success is false, the amount is claimable by the account.
     */
    event Withdraw(address indexed to, uint256 amount, bool success);

    /**
     * @notice Emitted when an account claims OMNI tokens that failed to be withdrawn.
     */
    event Claimed(address indexed to, uint256 amount);

    /**
     * @notice Total supply of OMNI tokens minted on L1.
     */
    uint256 public constant totalL1Supply = 100_000_000 * 10 ** 18;

    /**
     * @notice xcall gas limit for OmniBridgeL1.withdraw
     */
    uint64 public constant XCALL_WITHDRAW_GAS_LIMIT = 150_000;

    /**
     * @notice L1 chain id, configurable so that this contract can be used on testnets.
     * @dev We do not use immutable to avoid requiring setting immutable variables in
     *      predeploys, which is currently not supported.
     */
    uint64 public l1ChainId;

    /**
     * @notice The OmniPortal contract.
     * @dev We do not use immutable to avoid requiring setting immutable variables in
     *      predeploys, which is currently not supported.
     */
    IOmniPortal public omni;

    /**
     * @notice Total OMNI tokens deposited to OmniBridgeL1.
     *         If l1BridgeBalance == totalL1Supply, all OMNI tokens are on Omni's EVM.
     *         If l1BridgeBalance == 0, then withdraws to L1 are blocked. Without validator rewards totalL1Deposits == 0
     *         would mean all OMNI tokens are on Ethereum. However with validator rewards, some OMNI may remain on Omni.
     */
    uint256 public l1BridgeBalance;

    /**
     * @notice The address of the OmniBridgeL1 contract deployed to Ethereum.
     */
    address public l1Bridge;

    /**
     * @notice Track claimable amount per address. Claimable amount increases when withdraw transfer failes.
     */
    mapping(address => uint256) public claimable;

    /**
     * @notice Withdraw `amount` native OMNI to `to`. Onyl callable via xcall from OmniBridgeL1.
     */
    function withdraw(address to, uint256 amount) external {
        XTypes.MsgShort memory xmsg = omni.xmsg();

        require(msg.sender == address(omni), "OmniBridge: not xcall"); // this protects against reentrancy
        require(xmsg.sender == l1Bridge, "OmniBridge: not bridge");
        require(xmsg.sourceChainId == l1ChainId, "OmniBridge: not L1");

        l1BridgeBalance += amount;

        (bool success,) = to.call{ value: amount }("");

        if (!success) claimable[to] += amount;

        emit Withdraw(to, amount, success);
    }

    /**
     * @notice Bridge `amount` OMNI to msg.sender on L1.
     */
    function bridge(uint256 amount) external payable {
        _bridge(msg.sender, amount);
    }

    /**
     * @notice Bridge `amount` OMNI to `to` on L1.
     */
    function bridge(address to, uint256 amount) external payable {
        _bridge(to, amount);
    }

    /**
     * @dev Trigger a withdraw of `amount` OMNI to `to` on L1, via xcall.
     */
    function _bridge(address to, uint256 amount) internal {
        require(amount > 0, "OmniBridge: amount must be > 0");
        require(amount <= l1BridgeBalance, "OmniBridge: no liquidity");

        uint256 fee = bridgeFee(to, amount);
        require(msg.value == amount + fee, "OmniBridge: insufficient funds");

        omni.xcall{ value: fee }(
            l1ChainId,
            ConfLevel.Finalized,
            l1Bridge,
            abi.encodeWithSelector(OmniBridgeL1.withdraw.selector, to, amount),
            XCALL_WITHDRAW_GAS_LIMIT
        );
    }

    /**
     * @notice Return the xcall fee required to bridge `amount` to `to`.
     */
    function bridgeFee(address to, uint256 amount) public view returns (uint256) {
        return omni.feeFor(
            l1ChainId, abi.encodeWithSelector(OmniBridgeL1.withdraw.selector, to, amount), XCALL_WITHDRAW_GAS_LIMIT
        );
    }

    /**
     * @notice Claim OMNI tokens that failed to be withdrawn via xmsg from OmniBridgeL1.
     * @dev We require this be made by xcall, because an account on Omni may not be authorized to
     *      claim for that address on L1. Consider the case wherein the address of the L1 contract that initiated the
     *      withdraw is the same as the address of a contract on Omni deployed and owned by a malicious actor.
     */
    function claim(address to) external {
        XTypes.MsgShort memory xmsg = omni.xmsg();

        require(msg.sender == address(omni), "OmniBridge: not xcall");
        require(xmsg.sourceChainId == l1ChainId, "OmniBridge: not L1");

        address claimant = xmsg.sender;
        require(claimable[claimant] > 0, "OmniBridge: nothing to reclaim");

        uint256 amount = claimable[claimant];
        claimable[claimant] = 0;

        (bool success,) = to.call{ value: amount }("");
        require(success, "OmniBridge: transfer failed");

        emit Claimed(to, amount);
    }
}