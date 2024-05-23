local json = require("json")
local ao = require("ao")

Owner = Owner or ao.process.Owner

SmartWalletModule = SmartWalletModule or ao.process.Tags.SmartWalletModule


-- { [wallet]: { multisig = { signers = {} threshold = 1} } }
Wallets = Wallets or {}

-- { [address]: {wallet, wallet2, wallet 3}}
Signers = Signers or {}

Handlers.add("GetWallets", Handlers.utils.hasMatchingTag("Action", "GetWallets"), function(msg)
    local target = msg.Tags.Address or msg.From
    local wallets = Wallets[target]
    assert(wallets, "No wallets found for address: " .. target)
    ao.send({
        Target = msg.From,
        Data = json.encode(wallets)
    })
end)

Handlers.add("CreateWallet", Handlers.utils.hasMatchingTag("Action", "CreateWallet"), function(msg)
    local name = msg.Tags.Name or ""
    local description = msg.Tags.Description or ""
    local owner = msg.Tags.Owner or msg.From

    local wallet = {
        name = name,
        description = description,
        multisig = {
            signers = { owner },
            threshold = 1
        }
    }

    Wallets[msg.Id] = wallet

    ao.spawn(SmartWalletModule, {
        Tags = {
            Owner = owner,
            Name = name,
            Description = description,
            ["App-Name"] = "Mercurius",
            Type = "Wallet",
        }
    })

    Signers[owner] = Signers[owner] or {}
    table.insert(Signers[owner], msg.Id)

end)

-- Utility used by the wallet process to updat the registry with new signers and threshold
Handlers.add("UpdateMultisigSettings", Handlers.utils.hasMatchingTag("Action", "UpdateMultisigSettings"), function(msg)
    local wallet = msg.From
    local settings = json.decode(msg.Data)
    assert(Wallets[wallet], "Wallet not found: " .. wallet)
    assert(settings.signers, "No signers found in multisig settings")
    assert(settings.threshold, "No threshold found in multisig settings")

    -- remove old signers
    -- just remove them all, then add the new ones back in
    for i, w in ipairs(Wallets[wallet].multisig.signers) do
        Signers[w] = nil
        
    end

    Wallets[wallet].multisig = settings

    -- update signer list in registry with new wallets
    for i, s in ipairs(settings.signers) do
        table.insert(Signers[s], s)
    end

end)

Handlers.add("RemoveWallet", Handlers.utils.hasMatchingTag("Action", "RemoveWallet"), function(msg)
    local wallet = msg.Wallet
    local signer = msg.From
    assert(Wallets[wallet], "Wallet not found in the callers list of wallets: " .. wallet)
    assert(Signers[signer], "No signer found in message")
    
    for i, w in ipairs(Signers[signer]) do
        if w == wallet then
            Signers[signer][i] = nil
        end
    end

end)

Handlers.add("SetSmartWalletModule", Handlers.utils.hasMatchingTag("Action", "SetSmartWalletModule"), function(msg)
    local id = msg.SmartWalletModule
    local signer = msg.From
    assert(id, "No SmartWalletModule found in message")
    assert(signer == Owner, "Only the owner can set the SmartWalletModule")
    
    SmartWalletModule = id
end)