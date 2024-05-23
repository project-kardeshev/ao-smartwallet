import { Tag } from "arbundles"
import { AoProvider } from "./ao-provider"

export type WriteInteractionResult<T extends Record<string, unknown> = Record<string, string>> = {
  id: string
} & T

export type InteractionCall = {
  callData: Record<string, any>
  callTags: Array<Tag>
}

export interface MercuriusRegistry {
  createWallet(params: {
    name: string, 
    description: string,
    owner: string
  }): Promise<WriteInteractionResult>
  getWallets(params: {
    address: string
  }): Promise<string[]>
  removeWallet(params: {
    walletId: string
  }): Promise<WriteInteractionResult> 
}

export interface MercuriusWallet {
  addTransaction(params: {
    wallet: string, // smart wallet to interact with (process id) 
    to: string, // contract to interact with
    callData: Record<string, any>, 
    callTags: Array<Tag>
  }): Promise<WriteInteractionResult> // txid of the transaction that can be used to monitor its state in the contract
  approveTransaction(params: {
    wallet: string, // smart wallet to interact with (process id)
    txid: string
  }): Promise<WriteInteractionResult> // txid of the transaction that can be used to monitor its state in the contract
  addSigner(params: {
    wallet: string, // smart wallet to interact with (process id)
    address: string
  }): Promise<WriteInteractionResult> // txid of the transaction that can be used to monitor its state in the contract
  removeSigner(params: {
    wallet: string, // smart wallet to interact with (process id)
    address: string
  }): Promise<WriteInteractionResult> // txid of the transaction that can be used to monitor its state in the contract
  setThreshold(params: {
    wallet: string, // smart wallet to interact with (process id)
    threshold: number
  }): Promise<WriteInteractionResult> // txid of the transaction that can be used to monitor its state in the contract
  getMultisigSettings(params: {wallet: string}): Promise<WriteInteractionResult<{threshold: number, signers: string[]}>> // txid of the transaction that can be used to monitor its state in the contract
  getTransaction(params: {wallet: string, txid: string}): Promise<WriteInteractionResult<{tx: InteractionCall}>>
  getTransactionQueue(params: {wallet: string}): Promise<WriteInteractionResult<{transactions: Record<string, InteractionCall>}>>
  getTransactionHistory(params: {wallet: string}): Promise<WriteInteractionResult<{transactions: string[]}>>
  renounceOwnership(params: {wallet: string}): Promise<WriteInteractionResult>
  updateAssetList(params: {wallet: string}): Promise<WriteInteractionResult>
  addAsset(params: {wallet: string, asset: string}): Promise<WriteInteractionResult>
  removeAsset(params: {wallet: string, asset: string}): Promise<WriteInteractionResult>
  addAssetToBlockList(params: {wallet: string, asset: string}): Promise<WriteInteractionResult>
  removeAssetFromBlockList(params: {wallet: string, asset: string}): Promise<WriteInteractionResult>
  setRegistryId(params: {wallet: string, registryId: string}): Promise<WriteInteractionResult>
  getAssets(params: {wallet: string}): Promise<WriteInteractionResult<{assets: string[]}>>
  getBlockList(params: {wallet: string}): Promise<WriteInteractionResult<{blockList: string[]}>>
}

export default class MercuriusProvider extends AoProvider implements MercuriusRegistry, MercuriusWallet {
registryId: string

  constructor({
    registryId,
    aoOptions
    }:{
    registryId: string
    aoOptions?: any
  }) {
    super(aoOptions)
    this.registryId = registryId
  }
// registry methods
  async createWallet(params: {name?: string, description?: string, owner: string}): Promise<WriteInteractionResult> {

    const { id } = await this.ao.message({
      process: this.registryId,
      tags: [
        {name: 'Action', value: 'CreateWallet'},
        {name: 'Name', value: params.name},
        {name: 'Description', value: params.description}
      ]
    })
    return { id }
}

async getWallets(params: {address: string}): Promise<string[]> {
  const { id, Data } = await this.readData({
    process: this.registryId,
    Action: 'GetWallets',
    Address: params.address
  })
  return JSON.parse(Data)
}

async removeWallet(params: { walletId: string }): Promise<WriteInteractionResult<Record<string, string>>> {
  const { id } = await this.ao.message({
    process: this.registryId,
    tags: [
      {name: 'Action', value: 'RemoveWallet'},
      {name: 'Wallet', value: params.walletId}
    ]
  })
  return { id }
}

// wallet methods

async addTransaction(params: {wallet: string, to:string; callData: Record<string, any>, callTags: Array<Tag>}): Promise<WriteInteractionResult> {
  const { id } = await this.ao.message({
    process: params.wallet,
    data: JSON.stringify({
      callData: params.callData,
      callTags: params.callTags
    }),
    tags: [
      {name: 'Action', value: 'AddTransaction'},
      {name: 'To', value: params.to}
    ]
  })
  return { id }
}

async approveTransaction(params: {wallet: string, txid: string}): Promise<WriteInteractionResult> {
  const { id } = await this.ao.message({
    process: params.wallet,
    tags: [
      {name: 'Action', value: 'ApproveTransaction'},
      {name: 'TransactionId', value: params.txid}
    ]
  })
  return { id }
}

async addSigner(params: {wallet: string, address: string}): Promise<WriteInteractionResult> {
  const { id } = await this.ao.message({
    process: params.wallet,
    tags: [
      {name: 'Action', value: 'AddSigner'},
      {name: 'Signer', value: params.address}
    ]
  })
  return { id }
}

async removeSigner(params: {wallet: string, address: string}): Promise<WriteInteractionResult> {
  const { id } = await this.ao.message({
    process: params.wallet,
    tags: [
      {name: 'Action', value: 'RemoveSigner'},
      {name: 'Signer', value: params.address}
    ]
  })
  return { id }
}

async setThreshold(params: {wallet: string, threshold: number}): Promise<WriteInteractionResult> {
  const { id } = await this.ao.message({
    process: params.wallet,
    tags: [
      {name: 'Action', value: 'SetThreshold'},
      {name: 'Threshold', value: params.threshold}
    ]
  })
  return { id }

}

async getMultisigSettings(params: { wallet: string }): Promise<WriteInteractionResult<{ threshold: number; signers: string[] }>> {
  const { id, Data } = await this.ao.dryrun({
    process: params.wallet,
    tags: [
      {name: 'Action', value: 'GetMultisigSettings'}
    ]
  })
  return { id, ...JSON.parse(Data) }
}


}