package evmgovernance

import (
	"context"

	"github.com/omni-network/omni/contracts/bindings"
	"github.com/omni-network/omni/halo/genutil/evm/predeploys"
	"github.com/omni-network/omni/lib/errors"
	"github.com/omni-network/omni/lib/ethclient"
	evmenginetypes "github.com/omni-network/omni/octane/evmengine/types"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
)

const ModuleName = "evmgovernance"

var (
	governanceABI       = mustGetABI(bindings.GovernanceMetaData)
	submitProposalEvent = mustGetEvent(governanceABI, "SubmitProposal")
	voteEvent           = mustGetEvent(governanceABI, "Vote")
	depositEvent        = mustGetEvent(governanceABI, "Deposit")
)

type EventProcessor struct {
	contract *bindings.Governance
	ethCl    ethclient.Client
	address  common.Address
}

func New(ethCl ethclient.Client) (EventProcessor, error) {
	address := common.HexToAddress(predeploys.Governance)
	contract, err := bindings.NewGovernance(address, ethCl)
	if err != nil {
		return EventProcessor{}, errors.Wrap(err, "new governance")
	}

	return EventProcessor{
		contract: contract,
		ethCl:    ethCl,
		address:  address,
	}, nil
}

func (p EventProcessor) Prepare(ctx context.Context, blockHash common.Hash) ([]*evmenginetypes.EVMEvent, error) {
	logs, err := p.ethCl.FilterLogs(ctx, ethereum.FilterQuery{
		BlockHash: &blockHash,
		Addresses: p.Addresses(),
		Topics:    [][]common.Hash{{submitProposalEvent.ID, voteEvent.ID, depositEvent.ID}},
	})
	if err != nil {
		return nil, errors.Wrap(err, "filter logs")
	}

	resp := make([]*evmenginetypes.EVMEvent, 0, len(logs))
	for _, l := range logs {
		topics := make([][]byte, 0, len(l.Topics))
		for _, t := range l.Topics {
			topics = append(topics, t.Bytes())
		}
		resp = append(resp, &evmenginetypes.EVMEvent{
			Address: l.Address.Bytes(),
			Topics:  topics,
			Data:    l.Data,
		})
	}

	return resp, nil
}

func (EventProcessor) Name() string {
	return ModuleName
}

func (p EventProcessor) Addresses() []common.Address {
	return []common.Address{p.address}
}

func (p EventProcessor) Deliver(ctx context.Context, _ common.Hash, elog *evmenginetypes.EVMEvent) error {
	ethlog := elog.ToEthLog()

	switch ethlog.Topics[0] {
	case submitProposalEvent.ID:
		ev, err := p.contract.ParseSubmitProposal(ethlog)
		if err != nil {
			return errors.Wrap(err, "parse submit proposal")
		}
		return p.deliverSubmitProposal(ctx, ev)
	case voteEvent.ID:
		ev, err := p.contract.ParseVote(ethlog)
		if err != nil {
			return errors.Wrap(err, "parse vote")
		}
		return p.deliverVote(ctx, ev)
	case depositEvent.ID:
		ev, err := p.contract.ParseDeposit(ethlog)
		if err != nil {
			return errors.Wrap(err, "parse deposit")
		}
		return p.deliverDeposit(ctx, ev)
	default:
		return errors.New("unknown event")
	}
}

func (p EventProcessor) deliverSubmitProposal(ctx context.Context, ev *bindings.GovernanceSubmitProposal) error {
	// Handle the submit proposal event
	return nil
}

func (p EventProcessor) deliverVote(ctx context.Context, ev *bindings.GovernanceVote) error {
	// Handle the vote event
	return nil
}

func (p EventProcessor) deliverDeposit(ctx context.Context, ev *bindings.GovernanceDeposit) error {
	// Handle the deposit event
	return nil
}

func mustGetABI(metadata *bind.MetaData) *abi.ABI {
	abi, err := metadata.GetAbi()
	if err != nil {
		panic(err)
	}
	return abi
}

func mustGetEvent(abi *abi.ABI, name string) abi.Event {
	event, ok := abi.Events[name]
	if !ok {
		panic("event not found")
	}
	return event
}
