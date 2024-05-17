local ao = require 'ao'
local json = require 'json'
local utils = {}
utils.AddAction = function (action, handler)
    local actionName = string.gsub(action, "Handle", "")
  Handlers.add(actionName, Handlers.utils.hasMatchingTag("Action", actionName), handler)
end

utils.AddModuleHandlingFunctions = function (module)
    for key, value in pairs(module) do
        if type(value) == "function" and string.match(key, "Handle") then
            utils.AddAction(key, value)
        end
end
end

utils.assertOwner = function (msg)
    assert(msg.From == Owner, "Sender must be the owner, which is: " .. Owner)
end

utils.assertSigner = function (msg)
    assert(MultiSigSettings.signers[msg.From], "Sender not authorized to add transactions")
end

utils.notifySigners = function (title, msg)
    for signer in pairs(MultiSigSettings.signers) do
        ao.send({
            Target = signer,
            Data = msg,
            Tags = {
                Action = "Notify-Signer",
                Title = title
            }
        })
end
end

-- this will send the balance request which will then need to be handled by the balance notification handler
utils.requestBalance = function (assetId, target)
    print("requesting balance for: " .. assetId)
local res = ao.send({
    Target = assetId,
    Tags = {
        Action = "Balance",
        Target = target
    }
})
end

utils.isBalanceResponse = function (msg)
local balance = tonumber(msg.Tags.Balance)
    if balance then
        return true
    end
 return false
 end

utils.HandleGetMethods = function (msg)
   local methods = Handlers.list
    ao.send({
        Target = msg.From,
        Data = json.encode(methods),
    })
end

return utils