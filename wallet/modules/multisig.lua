local json = require 'json'
local ao = require 'ao'
local customUtils = require 'modules.utils'

local multisig = {}

multisig.HandleAddTransaction = function(msg)
    multisig.cleanTransactionQueue(tonumber(msg["Block-Height"]))
    customUtils.assertSigner(msg)
    local transaction = TransactionQueue[msg.Id]
        assert(transaction ~= nil, "Transaction already exists")

    local callData, callTags = json.decode(msg.Data)
    local target = msg.Tags.To 
        assert(target, "No target address specified")
        assert(callData, "No call data specified")
        assert(callTags, "No call tags specified")

    transaction = {
        to = target,
        from = msg.From,
        call = {data = callData, tags = callTags},
        approvals = {msg.From},
        originalMessage = msg
    }
    TransactionQueue[msg.Id] = transaction
    -- check threshold and send if necessary
    if MultiSigSettings.threshold == 1 then
        SendTransaction(msg.Id)
        return
    end
    -- notify signers of new transaction
    customUtils.notifySigners("New transaction added by " .. msg.From, json.encode({callData, callTags}))

end


function assertBlockedAsset(asset)
    assert(not BlockList[asset], "Asset is blocked")
end

function assertApprovals(transaction, threshold)

    local approvalCount = 0
    for k, v in pairs(transaction.approvals) do
        approvalCount = approvalCount + 1
    end
    assert(approvalCount >= threshold, "Not enough approvals")
end
function SendTransaction(id)
    local transaction = TransactionQueue[id]
        assert(transaction, "Transaction does not exist")

        assertApprovals(transaction, MultiSigSettings.threshold)

    ao.send({
        Target = transaction.to,
        Data = json.encode(transaction.call.data),
        Tags = transaction.call.tags
    })
    TransactionQueue[id] = nil

end
multisig.HandleApproveTransaction = function(msg)
    local transaction = TransactionQueue[msg.Tags.TransactionId]
        assert(transaction, "Transaction does not exist")
        --[[
            Blocked assets can be queued but not signed
            This allows signers to go get the asset unblocked and then sign.
            ]]
        assertBlockedAsset(transaction.to)
    local signer = msg.From
        assert(signer, "No signer specified")
    local signers = MultiSigSettings.signers
        assert(signers[signer], "Signer not authorized")
    local approvals = transaction.approvals
        assert(not approvals[signer], "Signer has already approved this transaction")
    approvals[signer] = true

    local approvalCount = 0
    for k, v in pairs(approvals) do
        approvalCount = approvalCount + 1
    end
    if approvalCount >= MultiSigSettings.threshold then
        SendTransaction(msg.Tags.TransactionId)
    end
end

multisig.HandleAddSigner = function(msg)
    customUtils.assertOwner(msg)
    local signer = msg.Tags.Signer
        assert(signer, "No signer specified")
    local signers = MultiSigSettings.signers
        assert(signers[signer], "Signer already exists")
    
        table.insert(MultiSigSettings.signers, signer)

    ao.send({
        Target = RegistryID,
        Data = json.encode(MultiSigSettings),
        Tags = {
            Action = "UpdateMultisigSettings",
        }
    })
end

multisig.HandleRemoveSigner = function(msg)
    customUtils.assertOwner(msg)
    local signer = msg.Tags.Signer
        assert(signer, "No signer specified")
    local signers = MultiSigSettings.signers
        assert(signers[signer], "Signer does not exist")

    local signerCount = 0
    for index, existingSigner in ipairs(MultiSigSettings.signers) do
        if existingSigner == existingSigner then
            MultiSigSettings.signers[index] = nil
            return
        end
        signerCount = signerCount + 1
    end
    -- if a signer is removed, the threshold must be updated to remain valid
    if signerCount < MultiSigSettings.threshold then
        MultiSigSettings.threshold = signerCount
    end

    ao.send({
        Target = RegistryID,
        Data = json.encode(MultiSigSettings),
        Tags = {
            Action = "UpdateMultisigSettings",
        }
    })
    
end

multisig.HandleSetThreshold = function(msg)
    customUtils.assertOwner(msg)
    local threshold = msg.Tags.Threshold and tonumber(msg.Tags.Threshold)
    assert(threshold, "No threshold specified")
    local signerCount = 0

    for index, signer in ipairs(MultiSigSettings.signers) do
        signerCount = signerCount + 1
    end

    assert(signerCount < threshold, "Threshold cannot be greater than the number of signers")
    assert(threshold >= 1, "Threshold must be at least 1")

    MultiSigSettings.threshold = threshold
    ao.send({
        Target = RegistryID,
        Data = json.encode(MultiSigSettings),
        Tags = {
            Action = "UpdateMultisigSettings",
        }
    })
end

-- Renounces ownership of the contract, locking in the signer list and threshold
multisig.HandleRenounceOwnership = function(msg)
    customUtils.assertOwner(msg)
    Owner = nil
end

multisig.HandleGetMultisigSettings = function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(MultiSigSettings),
    })
end

multisig.HandleGetTransactionQueue = function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(TransactionQueue),
    })
end

multisig.HandleGetTransaction = function(msg)
    local transaction = TransactionQueue[msg.Tags.TransactionId]
    assert(transaction, "Transaction does not exist")
    ao.send({
        Target = msg.From,
        Data = json.encode(transaction),
    })
end

multisig.HandleGetTransactionHistory = function(msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(TransactionHistory),
    })
end

multisig.cleanTransactionQueue = function(currentBlockHeight)
    for id, transaction in pairs(TransactionQueue) do
        if currentBlockHeight - tonumber(transaction.originalMessage["Block-Height"]) > 50 then
            TransactionQueue[id] = nil
        end
    end
end



return multisig