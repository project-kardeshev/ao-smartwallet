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
    description: string
  }): Promise<WriteInteractionResult>
  getWallets(params: {
    address: string
  }): Promise<WriteInteractionResult<{wallets: string[]}>>
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
  async createWallet(params: {name: string, description: string}): Promise<WriteInteractionResult> {
    const { id } = this.ao.message({
      process: this.registryId,
      tags: [
        {name: 'Action', value: 'CreateWallet'},
        {name: 'Name', value: params.name},
        {name: 'Description', value: params.description}
      ]
    })
    return { id }
}

async getWallets(params: {address: string}): Promise<WriteInteractionResult<{wallets: string[]}>> {
  const { id, Data } = this.ao.dryrun({
    process: this.registryId,
    tags: [
      {name: 'Action', value: 'GetWallets'},
      {name: 'Address', value: params.address}
    ]
  })
  return {id ,wallets: JSON.parse(Data)}
}

async removeWallet(params: { walletId: string }): Promise<WriteInteractionResult<Record<string, string>>> {
  return this.ao.message({
    process: this.registryId,
    tags: [
      {name: 'Action', value: 'RemoveWallet'},
      {name: 'Wallet', value: params.walletId}
    ]
  })
}

// wallet methods

async addTransaction(params: {wallet: string, to:string; callData: Record<string, any>, callTags: Array<Tag>}): Promise<WriteInteractionResult> {
  return this.ao.message({
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
}

}