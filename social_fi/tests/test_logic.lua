-- Initialize state
s = s or {
    tokenContractId = nil,   -- Process ID of our NFT token contract
    useCount = {},           -- tracks how many times each NFT was used
    pairUsedCount = {},      -- tracks how many times each pair was used
    nftRevenues = {},        -- stores revenue addresses for each NFT
    lastUsedTime = {},       -- tracks last use time for cooldown
    nftCdSec = 2,        -- cooldown period in seconds (2 secs for tests)
    maxUseCount = 5,        -- maximum times an NFT can be used
    pairingLimit = 1,       -- maximum times two NFTs can be paired
    rewardManager = nil,     -- address of reward manager
    nftBuyPrice = 100,        -- price in credits to purchase NFT
    -- Queue Implementation
    queue = {
        items = {},     -- Array to store items
        head = 0,       -- Index of the first element
        tail = 0,       -- Index where next element will be inserted
        count = 0       -- Number of elements in queue
    }
}

-- Helper function for error responses
function replyError(msg, action, errorMessage)
    return msg.reply({
        Action = action .. '-Error',
        Data = {
            Error = errorMessage
        }
    })
end

-- Initialize contract
Handlers.add('initialize', 'Initialize', function(msg)
    if msg.From ~= ao.id then
        return replyError(msg, 'Initialize', 'Only owner can initialize')
    end
    if not msg.TokenContractId then
        return replyError(msg, 'Initialize', 'Token contract ID is required')
    end
    if not msg.NewRewardManager then
        return replyError(msg, 'Initialize', 'New reward manager address is required')
    end
    
    s.tokenContractId = msg.TokenContractId
    s.rewardManager = msg.NewRewardManager
    
    msg.reply({
        Action = 'Initialize-Success',
        Data = {
            TokenContractId = msg.TokenContractId,
            RewardManager = msg.NewRewardManager
        }
    })
end)

-- Helper function to call token contract
function callTokenContract(action, params)
    local result = ao.send({
        Target = s.tokenContractId,
        Action = action,
        Params = params
    })
    
    if not result then
        error("Token contract call failed: no response received")
    end
    
    if result.Error then
        error(string.format("Token contract error: %s (Action: %s)", result.Error, action))
    end
    
    return result
end

-- Helper function to generate pair key
function generatePairKey(id1, id2)
    local elem1, elem2
    if id1 < id2 then
        elem1, elem2 = id1, id2
    else
        elem1, elem2 = id2, id1
    end
    return elem1 .. ":" .. elem2
end

-- Queue Operations
function enqueue(id)
    s.queue.items[s.queue.tail] = id
    s.queue.tail = s.queue.tail + 1
    s.queue.count = s.queue.count + 1
end

function dequeue()
    if s.queue.count <= 0 then
        return nil
    end
    
    local item = s.queue.items[s.queue.head]
    s.queue.items[s.queue.head] = nil  -- Clear reference
    s.queue.head = s.queue.head + 1
    s.queue.count = s.queue.count - 1
    
    -- Reset indices when queue is empty to prevent integer overflow
    if s.queue.count == 0 then
        s.queue.head = 0
        s.queue.tail = 0
    end
    
    return item
end

function peek()
    if s.queue.count <= 0 then
        return nil
    end
    return s.queue.items[s.queue.head]
end

function getQueueSize()
    return s.queue.count
end

function clearQueue()
    s.queue.items = {}
    s.queue.head = 0
    s.queue.tail = 0
    s.queue.count = 0
end

function validateQueue()
    while s.queue.count > 0 do
        local id = peek()
        local ownerResult = callTokenContract("ownerOf", { NFT_ID = id })
        
        if ownerResult.Data.Owner == ao.id then
            return -- Found valid NFT owned by contract
        end
        
        dequeue() -- Remove invalid entry
    end
end
-- End Queue Operations --

-- Getter Handlers
Handlers.add('getUseCount', 'GetUseCount', function(msg)
    if not msg.NFT_ID then
        return replyError(msg, 'GetUseCount', 'NFT_ID is required')
    end
    
    msg.reply({
        Action = 'GetUseCount-Response',
        Data = {
            Count = s.useCount[msg.NFT_ID] or 0
        }
    })
end)

Handlers.add('getPairUsedCount', 'GetPairUsedCount', function(msg)
    if not msg.Id1 then
        return replyError(msg, 'GetPairUsedCount', 'Id1 is required')
    end
    if not msg.Id2 then
        return replyError(msg, 'GetPairUsedCount', 'Id2 is required')
    end
    
    local key = generatePairKey(msg.Id1, msg.Id2)
    
    msg.reply({
        Action = 'GetPairUsedCount-Response',
        Data = {
            Count = s.pairUsedCount[key] or 0
        }
    })
end)

Handlers.add('getNftRevenues', 'GetNftRevenues', function(msg)
    if not msg.NFT_ID then
        return replyError(msg, 'GetNftRevenues', 'NFT_ID is required')
    end
    
    msg.reply({
        Action = 'GetNftRevenues-Response',
        Data = {
            Revenues = s.nftRevenues[msg.NFT_ID] or {nil, nil}
        }
    })
end)

Handlers.add('getTimeUntilNextMint', 'GetTimeUntilNextMint', function(msg)
    assert(msg.NFT_ID, "NFT_ID is required")
    
    local lastUsed = s.lastUsedTime[msg.NFT_ID] or 0
    local currentTime = os.time()
    local passedTime = currentTime - lastUsed
    
    local timeLeft = 0
    if passedTime < s.nftCdSec then
        timeLeft = s.nftCdSec - passedTime
    end
    
    msg.reply({
        Action = 'GetTimeUntilNextMint-Response',
        Data = {
            TimeLeft = timeLeft
        }
    })
end)

Handlers.add('isInCd', 'IsInCd', function(msg)
    assert(msg.NFT_ID, "NFT_ID is required")
    
    local lastUsed = s.lastUsedTime[msg.NFT_ID] or 0
    local currentTime = os.time()
    local passedTime = currentTime - lastUsed
    
    msg.reply({
        Action = 'IsInCd-Response',
        Data = {
            InCooldown = passedTime < s.nftCdSec
        }
    })
end)

Handlers.add('getNextIdInQueue', 'GetNextIdInQueue', function(msg)
    validateQueue()
    
    msg.reply({
        Action = 'GetNextIdInQueue-Response',
        Data = {
            NextId = peek()
        }
    })
end)

-- Administrative Handlers
Handlers.add('setNftMaxUseCount', 'SetNftMaxUseCount', function(msg)
    if msg.From ~= s.rewardManager then
        return replyError(msg, 'SetNftMaxUseCount', 'Only reward manager can set max use count')
    end
    if not msg.Limit then
        return replyError(msg, 'SetNftMaxUseCount', 'Limit parameter is required')
    end
    
    s.maxUseCount = msg.Limit
    
    msg.reply({
        Action = 'SetNftMaxUseCount-Success',
        Data = {
            NewLimit = msg.Limit
        }
    })
end)

Handlers.add('setNftBuyPrice', 'SetNftBuyPrice', function(msg)
    if msg.From ~= s.rewardManager then
        return replyError(msg, 'SetNftBuyPrice', 'Only reward manager can set buy price')
    end
    if not msg.Price then
        return replyError(msg, 'SetNftBuyPrice', 'Price parameter is required')
    end
    
    s.nftBuyPrice = msg.Price
    
    msg.reply({
        Action = 'SetNftBuyPrice-Success',
        Data = {
            NewPrice = msg.Price
        }
    })
end)

Handlers.add('setMintCdSec', 'SetMintCdSec', function(msg)
    if msg.From ~= s.rewardManager then
        return replyError(msg, 'SetMintCdSec', 'Only reward manager can set cooldown')
    end
    if not msg.CdSec then
        return replyError(msg, 'SetMintCdSec', 'CdSec parameter is required')
    end
    
    s.nftCdSec = msg.CdSec
    
    msg.reply({
        Action = 'SetMintCdSec-Success',
        Data = {
            NewCdSec = msg.CdSec
        }
    })
end)

Handlers.add('setPairingLimit', 'SetPairingLimit', function(msg)
    if msg.From ~= s.rewardManager then
        return replyError(msg, 'SetPairingLimit', 'Only reward manager can set pairing limit')
    end
    if not msg.Limit then
        return replyError(msg, 'SetPairingLimit', 'Limit parameter is required')
    end
    
    s.pairingLimit = msg.Limit
    
    msg.reply({
        Action = 'SetPairingLimit-Success',
        Data = {
            NewLimit = msg.Limit
        }
    })
end)

Handlers.add('setLastUsedTime', 'SetLastUsedTime', function(msg)
    assert(msg.From == s.rewardManager, "Only reward manager can set last used time")
    assert(msg.NFT_ID, "NFT_ID parameter is required")
    assert(msg.Time, "Time parameter is required")
    s.lastUsedTime[msg.NFT_ID] = msg.Time
    
    msg.reply({
        Action = 'SetLastUsedTime-Success',
        Data = {
            NFT_ID = msg.NFT_ID,
            NewTime = msg.Time
        }
    })
end)

-- Main Operation Handlers
function checkMintAllowness(rev1, id1, rev2, id2)
    if not rev1 or rev1 == "" then
        error("rev1 invalid address")
    end
    if not rev2 or rev2 == "" then
        error("rev2 invalid address")
    end
    if rev1 == rev2 then
        error("rev1 and rev2 should be different")
    end
    
    local owner1 = callTokenContract("ownerOf", { NFT_ID = id1 })
    local owner2 = callTokenContract("ownerOf", { NFT_ID = id2 })
    
    if owner1.Data.Owner ~= rev1 then
        error("rev1 is not owner of id1")
    end
    if owner2.Data.Owner ~= rev2 then
        error("rev2 is not owner of id2")
    end
    
    local currentTime = os.time()
    local lastUsed1 = s.lastUsedTime[id1] or 0
    local lastUsed2 = s.lastUsedTime[id2] or 0
    
    if currentTime - lastUsed1 < s.nftCdSec then
        error("id1 Nft is in cooldown")
    end
    if currentTime - lastUsed2 < s.nftCdSec then
        error("id2 Nft is in cooldown")
    end
    
    local key = generatePairKey(id1, id2)
    local pairCount = s.pairUsedCount[key] or 0
    if pairCount >= s.pairingLimit then
        error("pairing limit reached for these nfts")
    end
    
    return key
end

function makePairedNft(rev1, rev2)
    local mintResult = callTokenContract("mint", {
        To = ao.id
    })
    assert(mintResult, "Mint failed")
    
    local newId = mintResult.Data.NFT_ID
    
    s.nftRevenues[newId] = {rev1, rev2}
    
    enqueue(newId)
    return newId
end

function incrementUseCount(rev, id)
    local newCount = (s.useCount[id] or 0) + 1
    
    if newCount >= s.maxUseCount then
        local burnResult = callTokenContract("burn", { NFT_ID = id })
        assert(burnResult, "Burn failed")
    end
    
    s.useCount[id] = newCount
end

Handlers.add('mint', 'Mint', function(msg)
    if msg.From ~= s.rewardManager then
        return replyError(msg, 'Mint', 'Only reward manager can mint')
    end
    if not (msg.Rev1 and msg.Id1 and msg.Rev2 and msg.Id2) then
        return replyError(msg, 'Mint', 'Missing parameters')
    end
    if not s.tokenContractId then
        return replyError(msg, 'Mint', 'Token contract not initialized')
    end
    
    local success, result = pcall(function()
        local pairKey = checkMintAllowness(msg.Rev1, msg.Id1, msg.Rev2, msg.Id2)
        local newId = makePairedNft(msg.Rev1, msg.Rev2)
        
        incrementUseCount(msg.Rev1, msg.Id1)
        incrementUseCount(msg.Rev2, msg.Id2)
        
        local currentTime = os.time()
        s.lastUsedTime[msg.Id1] = currentTime
        s.lastUsedTime[msg.Id2] = currentTime
        s.pairUsedCount[pairKey] = (s.pairUsedCount[pairKey] or 0) + 1
        
        return newId
    end)
    
    if not success then
        return replyError(msg, 'Mint', result)
    end
    
    msg.reply({
        Action = 'Mint-Success',
        Data = {
            ID1 = msg.Id1,
            ID2 = msg.Id2,
            NewID = result
        }
    })
end)

Handlers.add('mintIdle', 'MintIdle', function(msg)
    assert(msg.From == s.rewardManager, "Only reward manager can mint idle")
    assert(msg.Rev1 and msg.Id1 and msg.Rev2 and msg.Id2, "Missing parameters")
    assert(s.tokenContractId, "Token contract not initialized")
    
    checkMintAllowness(msg.Rev1, msg.Id1, msg.Rev2, msg.Id2)
    
    local currentTime = os.time()
    s.lastUsedTime[msg.Id1] = currentTime
    s.lastUsedTime[msg.Id2] = currentTime
    
    msg.reply({
        Action = 'MintIdle-Success',
        Data = {
            ID1 = msg.Id1,
            ID2 = msg.Id2
        }
    })
end)

Handlers.add('purchaseNft', 'PurchaseNft', function(msg)
    if s.queue.count <= 0 then
        return replyError(msg, 'PurchaseNft', 'Minted nfts queue is empty')
    end
    if not msg.Quantity or msg.Quantity < s.nftBuyPrice then
        return replyError(msg, 'PurchaseNft', 'Insufficient credits sent')
    end
    
    validateQueue()
    local nftId = peek()
    if not nftId then
        return replyError(msg, 'PurchaseNft', 'No NFT available after queue validation')
    end
    
    local success, result = pcall(function()
        callTokenContract("transfer", {
            From = ao.id,
            Recipient = msg.FromMocked,
            NFT_ID = nftId
        })
        dequeue()
        
        local totalRevenue = msg.Quantity
        local revenueShare = math.floor(totalRevenue * 0.4)
        local contractShare = totalRevenue - (revenueShare * 2)
        
        local sendResult = ao.send({
            Target = s.nftRevenues[nftId][1],
            Quantity = revenueShare
        })
        if not sendResult then
            error('Revenue transfer 1 failed!')
        end
        
        sendResult = ao.send({
            Target = s.nftRevenues[nftId][2],
            Quantity = revenueShare
        })
        if not sendResult then
            error('Revenue transfer 2 failed!')
        end
        
        if revenueShare * 2 + contractShare ~= totalRevenue then
            error("Revenue distribution error")
        end
        
        s.nftRevenues[nftId] = nil
        return nftId
    end)
    
    if not success then
        return replyError(msg, 'PurchaseNft', result)
    end
    
    msg.reply({
        Action = 'Purchase-Success',
        Data = {
            NFT_ID = result,
            Owner = msg.FromMocked
        }
    })
end)

Handlers.add('withdraw', 'Withdraw', function(msg)
    if msg.From ~= s.rewardManager then
        return replyError(msg, 'Withdraw', 'Only reward manager can withdraw')
    end
    
    local balance = ao.balance()
    if balance <= 0 then
        return replyError(msg, 'Withdraw', 'No balance to withdraw')
    end
    
    local sendResult = ao.send({
        Target = msg.From,
        Quantity = balance
    })
    if not sendResult then
        return replyError(msg, 'Withdraw', 'Withdraw transfer failed!')
    end
    
    msg.reply({
        Action = 'Withdraw-Success',
        Data = {
            Amount = balance
        }
    })
end)
