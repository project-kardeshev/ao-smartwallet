local json = require("json")
local ao = require("ao")

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
end)

-- Utility used by the wallet process to updat the registry with new signers and threshold
Handlers.add("UpdateMultisigSettings", Handlers.utils.hasMatchingTag("Action", "UpdateMultisigSettings"), function(msg)
    local wallet = msg.From
    local settings = json.decode(msg.Data)
    assert(Wallets[wallet], "Wallet not found: " .. wallet)
    assert(settings.signers, "No signers found in multisig settings")
    assert(settings.threshold, "No threshold found in multisig settings")
    Wallets[wallet].multisig = settings
end)

Handlers.add("RemoveWallet", Handlers.utils.hasMatchingTag("Action", "RemoveWallet"), function(msg)
    local wallet = msg.Wallet
    local signer = msg.From
    assert(Wallets[wallet], "Wallet not found: " .. wallet)
    assert(Signers[signer], "No signer found in message")
    
    for i, w in ipairs(Signers[signer]) do
        if w == wallet then
            Signers[signer][i] = nil
        end
    end

end)