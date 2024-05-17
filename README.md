# AO smart wallet featuring multi-sig and asset tracking
This repository store a spawner and wallet contract.

The Spawner, or Registry, is used to create and track association of wallets
to signers and owners, and can be queried for a users wallets.

## The Spawner
The spawner is responsible for the creation and tracking of smart wallets. It receives events from smart wallets when a signer is added or removed.

Only wallets spawned by the spawner can interact with them, and the spawner address is tagged on the wallet's ID.

### APIs

#### `CreateWallet(options)`
Creates a new wallet with the provided name and description.

These tags are added to the spawn message as tags to make the wallet, along with some Mercurius tags to make the wallet indexable on gateways on the Mercurius data protocol:
```lua
  ao.spawn(SmartWalletModule, {
        Tags = {
            Owner = owner,
            Name = name,
            Description = description,
            ["App-Name"] = "Mercurius",
            Type = "Wallet",
        }
    })
```

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Name`        | String or undefined | The name of the wallet.                               |
| `Description` | String or undefined | The description of the wallet.                        |
| `Owner`       | String or undefined | The address of the wallet owner.                      |

#### `GetWallets(options)`
Gets all the wallet IDs for the user. If no user is provided, returns wallets associated with the caller's (msg.From) address.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Address`     | String | The address of the user.                              |

#### `UpdateMultisigSettings()`
Updates the signers list and threshold of the specified wallet.

##### Data schema:
| Key           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `signers`     | Array  | A list of signers' addresses.                         |
| `threshold`   | Number | The threshold for multisig approval.                  |

#### `RemoveWallet()`
Removes a wallet from a signer's list of wallets.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Wallet`      | String | The ID of the wallet.                                 |



## The Wallet
Wallets are responsible for handling multisig security and asset management.

Asset management is done by way of a personalized ledger of token process ID's with the smart wallet's balance. This is powered by Debit and Credit notices in conjunction with the `Balance` API exposed by token processes.

When a Debit or Credit notice is received by the smart wallet it requests the balance and upon receiving it, sets the balance for the asset in its ledger.

Alternatively, assets can be manually added and manually updated using the `Update-Asset-List` API for contracts that do not support credit or debit notices - it's good practice to call this method regardless of the Credit and Debit API existing.

> This is due to the optional `Cast` property that can sometimes be added, which prevents debit or credit notices, causing a loss of parity with the target asset. Calling `Update-Asset-List` will always get the correct balance - so long as the `Balance` API follows the supported spec.



### Registry APIs
API's for interacting with the registry the wallet is connected to - by default, the registry that spawned the wallet.



#### `Balance-Response(msg)`
Handles the response from a balance request by updating the asset list. Has a handler that matches a balance tag - this is internally triggered by a credit or debit notice.

##### Data schema:
| Key           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Balance`     | Number | The balance of the asset.                             |

#### `Set-Registry-ID(msg)`
Sets the registry ID for the wallet.

TODO: make multiple registries able to be registered. 

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `RegistryID`  | String | The new registry ID.                                  |


### Multisig APIs


#### `AddTransaction(msg)`
Adds a new transaction to the multisig wallet.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `To`          | String | The target address for the transaction.               |

##### Data schema:
| Key           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `callData`    | Object | The data for the transaction call.                    |
| `callTags`    | Object | The tags for the transaction call.                    |


#### `GetTransactionQueue(msg)`
Returns the transaction queue for the contract


#### `GetTransaction(msg)`
Gets an individual transaction from the transaction queue.

#### `GetTransactionHistory()`
Returns the transaction history of the wallet.

#### `ApproveTransaction(msg)`
Approves a transaction added by another signer.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `TransactionId` | String | The ID of the transaction to approve.                  |

#### `AddSigner(msg)`
Adds a new signer to the multisig wallet. Owner only.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Signer`      | String | The address of the new signer.                        |

#### `RemoveSigner(msg)`
Removes an existing signer from the multisig wallet. Owner only.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Signer`      | String | The address of the signer to remove.                  |

#### `SetThreshold(msg)`
Sets the approval threshold for multisig transactions. Owner only.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Threshold`   | Number | The new approval threshold.                           |

#### `RenounceOwnership(msg)`
Renounces ownership of the contract, locking in the signer list and threshold.

The disables all owner functions.

#### `GetMultisigSettings(msg)`
Retrieves the current multisig settings.

Returns stringified json in data:
```json
{
    "signers": array,
    "threshold": number
}
```

### Asset Management APIs

#### `Credit-Notice(msg)`
Handles a credit notice by requesting the balance of the asset.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Action`      | String | Must be "Credit-Notice".                              |

#### `Debit-Notice(msg)`
Handles a debit notice by requesting the balance of the asset.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Action`      | String | Must be "Debit-Notice".                               |

#### `Update-Asset-List(msg)`
Updates the asset list by requesting the balance of each asset.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Action`      | String | Must be "Update-Asset-List".                          |

#### `AddAsset(msg)`
Adds a new asset to the asset list.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Asset`       | String | The ID of the asset to add.                           |

#### `AddAssetToBlocklist(msg)`
Adds a new asset to the blocklist, preventing updates from that assets and removing it from the assets list.

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Asset`       | String | The ID of the asset to block.                         |

#### `RemoveAssetFromBlocklist(msg)`
Removes an asset from the blocklist

##### Tag arguments:
| Tag           | Type   | Description                                           |
|---------------|--------|-------------------------------------------------------|
| `Asset`       | String | The ID of the asset to remove from blocklist          |

#### `GetAssets(msg)`
Retrieves the current list of assets.

Returns stringified json in the data key:
```json
{
    [id of asset]: balance of asset,
    ...
}
```

#### `GetBlockList(msg)`
Retrieves the current blocklist of assets.

Returns stringified json in the data key:
```json
{
    [id of asset]: boolean,
    ...
}
```