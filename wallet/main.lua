local customUtils = require 'modules.utils'
local multisig = require 'modules.multisig'
local assets = require 'modules.assets'

Owner = Owner or ao.env.Process.Tags.Owner
--[[
    The Registry ID is the ID of the parent wallet process that either spawned this wallet,
    or is the registry that the user wants to subscribe their wallet to.
]]
RegistryID = RegistryID or ao.env.Process.Tags.RegistryID

TransactionQueue = TransactionQueue or {}
TransactionHistory = TransactionHistory or {}

MultiSigSettings = MultiSigSettings or {
    signers = { Owner },
    threshold = 1, -- min 1
}

AssetList = AssetList or {}

-- Assets on the block list will not be allowed to be added to the AssetList - this is a security feature
BlockList = BlockList or {}

customUtils.AddModuleHandlingFunctions(assets)
customUtils.AddModuleHandlingFunctions(customUtils)
customUtils.AddModuleHandlingFunctions(multisig)

Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg)
    ao.send({
        Target = msg.From,
        Data = {
            Owner = Owner,
            RegistryID = RegistryID,
            MultiSigSettings = json.encode(MultiSigSettings),
        }  
    })
end)

-- Ledger maintenance
Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg)
    assertBlockedAsset(msg.From)
    customUtils.requestBalance(msg.From, ao.id)
    -- Asset is only added or removed in balance response
end)

Handlers.add("Debit-Notice", Handlers.utils.hasMatchingTag("Action", "Debit-Notice"), function(msg)
   assertBlockedAsset(msg.From)
    -- Asset is only added or removed in balance response
    customUtils.requestBalance(msg.From, ao.id)
end)


Handlers.add("Update-Asset-List", 
Handlers.utils.hasMatchingTag("Action", "Update-Asset-List")
, function(msg)
    local assetList = AssetList
    for asset, quantity in pairs(assetList) do     
        -- request balance for each asset
        -- this will trigger a Balance-Response when the asset process responds
        customUtils.requestBalance(asset, ao.id)
    end
end)

Handlers.add('Balance-Response', customUtils.isBalanceResponse, function(msg)
    print("Balance-Response from: " .. msg.From .. " Balance: " .. msg.Tags.Balance)
    local asset = msg.From
    assertBlockedAsset(asset)
    local balance = tonumber(msg.Tags.Balance)
    local assetList = AssetList
        if balance <= 0 then
            assetList[asset] = nil
        return
    end
    assetList[asset] = balance
    AssetList = assetList
    customUtils.notifySigners("Asset " .. msg.From .. " balance updated: ", msg.Tags.Balance)
end)

-- Registry maintenance
Handlers.add("Set-Registry-ID", Handlers.utils.hasMatchingTag("Action", "Set-Registry-ID"), function(msg)
    customUtils.assertOwner(msg)
    local registryID = msg.Tags.RegistryID
    assert(registryID, "No registry ID specified")
    RegistryID = registryID
end)