package bindings

import (
    _ "embed"
)

const (
    Create3DeployedBytecode = "0x6080604052600436106100295760003560e01c806350f1c4641461002e578063cdcb760a1461006a575b600080fd5b34801561003a57600080fd5b5061004e610049366004610344565b61007d565b6040516001600160a01b03909116815260200160405180910390f35b61004e610078366004610392565b6100c9565b6040516001600160601b0319606084901b166020820152603481018290526000906054016040516020818303038152906040528051906020012091506100c28261010f565b9392505050565b6040516001600160601b03193360601b166020820152603481018390526000906054016040516020818303038152906040528051906020012092506100c28383346101e9565b604080518082018252601081526f67363d3d37363d34f03d5260086018f360801b60209182015290516001600160f81b0319918101919091526001600160601b03193060601b166021820152603581018290527f21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f605582015260009081906101ae906075015b6040516020818303038152906040528051906020012090565b6040516135a560f21b60208201526001600160601b0319606083901b166022820152600160f81b60368201529091506100c290603701610195565b6000806040518060400160405280601081526020016f67363d3d37363d34f03d5260086018f360801b81525090506000858251602084016000f590506001600160a01b0381166102745760405162461bcd60e51b81526020600482015260116024820152701111541313d65351539517d19052531151607a1b60448201526064015b60405180910390fd5b61027d8661010f565b92506000816001600160a01b0316858760405161029a919061044d565b60006040518083038185875af1925050503d80600081146102d7576040519150601f19603f3d011682016040523d82523d6000602084013e6102dc565b606091505b505090508080156102f657506001600160a01b0384163b15155b61033a5760405162461bcd60e51b815260206004820152601560248201527412539255125053125690551253d397d19052531151605a1b604482015260640161026b565b5050509392505050565b6000806040838503121561035757600080fd5b82356001600160a01b038116811461036e57600080fd5b946020939093013593505050565b634e487b7160e01b600052604160045260246000fd5b600080604083850312156103a557600080fd5b82359150602083013567ffffffffffffffff808211156103c457600080fd5b818501915085601f8301126103d857600080fd5b8135818111156103ea576103ea61037c565b604051601f8201601f19908116603f011681019083821181831017156104125761041261037c565b8160405282815288602084870101111561042b57600080fd5b8260208601602083013760006020848301015280955050505050509250929050565b6000825160005b8181101561046e5760208186018101518583015201610454565b8181111561047d576000828501525b50919091019291505056fea26469706673582212201b2ee9a5662f944e145941ebc26c5c9dedacdb8387f70a8f9530100d519fe41c64736f6c634300080c0033"
)

//go:embed create3_storage_layout.json
var create3StorageLayoutJSON []byte

var Create3StorageLayout = mustGetStorageLayout(create3StorageLayoutJSON)
