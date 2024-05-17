local json = require 'json'
local ao = require 'ao'
local customUtils = require 'modules.utils'


local assets = {}

assets.HandleAddAsset = function(msg)
    print("Adding asset")
    --customUtils.assertSigner(msg)
    local asset = msg.Tags.Asset
        assert(asset, "No asset specified")
    local assets = AssetList
        assert(not assets[asset], "Asset already exists")

    assets[asset] = true
    AssetList = assets
end

assets.HandleAddAssetToBlocklist = function (msg)
    customUtils.assertSigner(msg)
    local asset = msg.Tags.Asset
    assert(asset, "No asset specified")
    local blockList = BlockList
    assert(not blockList[asset], "Asset already exists in blocked asset list")
    blockList[asset] = true
    BlockList = blockList
end

assets.HandleRemoveAssetFromBlocklist = function (msg)
    customUtils.assertSigner(msg)
    local asset = msg.Tags.Asset
    assert(asset, "No asset specified")
    local blockList = BlockList
    assert(not blockList[asset], "Asset is not in blocklist")
    blockList[asset] = nil
    BlockList = blockList
end

assets.HandleGetAssets = function (msg)
    local assetList = AssetList
    print("Sending asset list: " .. json.encode(assetList))
    ao.send({
        Target = msg.From,
        Data = json.encode(assetList)
    })
end

assets.HandleGetBlockList = function (msg)
    ao.send({
        Target = msg.From,
        Data = json.encode(BlockList),
    })
end






return assets