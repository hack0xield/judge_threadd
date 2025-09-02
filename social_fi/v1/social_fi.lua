s = s or {
    paymentToken = nil,
    credited = {},

    -- Nft related
    tokenOwners = {},        -- nft id to owner map
    tokensByOwner = {},      -- owner to array of nft ids map
    nextNftID = 0,           -- tokens total counter

    -- Breeding
    useCount = {},           -- tracks how many times each NFT was used
    pairUsedCount = {},      -- tracks how many times each pair was used
    nftParents = {},         -- stores revenue addresses for each NFT
    lastUsedTime = {},       -- tracks last use time for cooldown

    nftCdSec = 2,           -- cooldown period in seconds (2 secs for tests)
    maxUseCount = 5,        -- maximum times an NFT can be used
    pairingLimit = 1,       -- maximum times two NFTs can be paired
    rewardManager = nil,    -- address of reward manager
    nftBuyPrice = 100,      -- price in credits to purchase NFT

    -- LinkedList Implementation
    list = {
        nodes = {},         -- Map to store nodes: {value, next, prev}
        head = nil,         -- First node id
        tail = nil,         -- Last node id
        count = 0          -- Number of elements in list
    }
}

-- LinkedList Operations
function enqueue(id)
    local node = {
        value = id,
        next = nil,
        prev = s.list.tail
    }
    s.list.nodes[id] = node

    if s.list.count == 0 then
        s.list.head = id
    else
        s.list.nodes[s.list.tail].next = id
    end

    s.list.tail = id
    s.list.count = s.list.count + 1
end

function dequeue()
    if s.list.count == 0 then
        return nil
    end

    local headId = s.list.head
    local headNode = s.list.nodes[headId]

    s.list.head = headNode.next
    if s.list.head then
        s.list.nodes[s.list.head].prev = nil
    else
        s.list.tail = nil  -- List is now empty
    end

    s.list.nodes[headId] = nil
    s.list.count = s.list.count - 1

    return headId
end

function peek()
    if s.list.count == 0 then
        return nil
    end
    return s.list.head
end

function removeFromList(id)
    local node = s.list.nodes[id]
    if not node then
        return false
    end

    if node.prev then
        s.list.nodes[node.prev].next = node.next
    else
        s.list.head = node.next
    end

    if node.next then
        s.list.nodes[node.next].prev = node.prev
    else
        s.list.tail = node.prev
    end

    s.list.nodes[id] = nil
    s.list.count = s.list.count - 1
    return true
end

function getListSize()
    return s.list.count
end

function isInList(id)
    return s.list.nodes[id] ~= nil
end
-- End LinkedList Operations

-- Helper function for error responses
function replyError(msg, action, errorMessage)
    return msg.reply({
        Action = action .. '-Error',
        Data = {
            Error = errorMessage
        }
    })
end

-- Helper function to generate nft pair key
function generatePairKey(id1, id2)
    local elem1, elem2
    if id1 < id2 then
        elem1, elem2 = id1, id2
    else
        elem1, elem2 = id2, id1
    end
    return elem1 .. ":" .. elem2
end

-- Helper functions to manage token ownership
function addTokenToOwner(nftId, owner)
    if not owner then return end

    -- Update tokenOwners map
    s.tokenOwners[nftId] = owner

    -- Update tokensByOwner map
    s.tokensByOwner[owner] = s.tokensByOwner[owner] or {}
    table.insert(s.tokensByOwner[owner], nftId)
end

function removeTokenOwnership(nftId)
    local owner = s.tokenOwners[nftId]
    if not owner then return end

    -- Remove from tokenOwners map
    s.tokenOwners[nftId] = nil

    -- Remove from tokensByOwner map
    if s.tokensByOwner[owner] then
        for i, id in ipairs(s.tokensByOwner[owner]) do
            if id == nftId then
                table.remove(s.tokensByOwner[owner], i)
                break
            end
        end
        -- Clean up empty arrays
        if #s.tokensByOwner[owner] == 0 then
            s.tokensByOwner[owner] = nil
        end
    end
end

function passOwnership(nftId, newOwner)
    if not newOwner then return end

    removeTokenOwnership(nftId)
    addTokenToOwner(nftId, newOwner)
end

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

    if s.tokenOwners[id1] ~= rev1 then
        error("rev1 is not owner of id1")
    end
    if s.tokenOwners[id2] ~= rev2 then
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

function mintWithParents(rev1, rev2)
    local mintedId = s.nextNftID
    s.nextNftID = s.nextNftID + 1

    addTokenToOwner(mintedId, ao.id)
    s.nftParents[mintedId] = {rev1, rev2}

    enqueue(mintedId)
    return mintedId
end

function incrementUseCount(id)
    s.useCount[id] = (s.useCount[id] or 0) + 1

    if s.useCount[id] >= s.maxUseCount then
        removeTokenOwnership(id) -- Burn token by removing ownership
    end
end

Handlers.add('mint', 'Mint', function(msg)
    local tags = msg.Tags
    if msg.From ~= ao.id and msg.Owner ~= s.rewardManager then
        return replyError(msg, 'Mint', 'Only internal use')
    end
    if not (tags.Rev1 and tags.Id1 and tags.Rev2 and tags.Id2) then
        return replyError(msg, 'Mint', 'Missing parameters')
    end
    local id1 = tonumber(tags.Id1)
    local id2 = tonumber(tags.Id2)

    local success, result = pcall(function()
        local pairKey = checkMintAllowness(tags.Rev1, id1, tags.Rev2, id2)
        local newId = mintWithParents(tags.Rev1, tags.Rev2)

        incrementUseCount(id1)
        incrementUseCount(id2)

        local currentTime = os.time()
        s.lastUsedTime[id1] = currentTime
        s.lastUsedTime[id2] = currentTime
        s.pairUsedCount[pairKey] = (s.pairUsedCount[pairKey] or 0) + 1

        return newId
    end)

    if not success then
        return replyError(msg, 'Mint', result)
    end

    msg.reply({
        Action = 'Mint-Success',
        Data = {
            ParentId1 = tags.Id1,
            ParentId2 = tags.Id2,
            Rev1 = tags.Rev1,
            Rev2 = tags.Rev2,
            NewID = result
        }
    })
end)

Handlers.add('purchaseNft', 'Credit-Notice', function(msg)
    local tags = msg.Tags
    if msg.From ~= s.paymentToken then
        return ao.send({
            Target = tags.Sender,
            Action = 'PurchaseNft-Error',
            Data = {
                Error = 'Wrong token credit!',
                Token = msg.From
            }
        })
    end
    if tonumber(tags.Quantity) < s.nftBuyPrice then
        s.credited[tags.Sender] = (s.credited[tags.Sender] or 0) + tonumber(tags.Quantity)
        return ao.send({
            Target = tags.Sender,
            Action = 'PurchaseNft-Error',
            Data = {
                Error = 'Insufficient credits sent!',
                Quantity = tags.Quantity
            }
        })
    end
    if getListSize() <= 0 then
        s.credited[tags.Sender] = (s.credited[tags.Sender] or 0) + tonumber(tags.Quantity)
        return ao.send({
            Target = tags.Sender,
            Action = 'PurchaseNft-Error',
            Data = {
                Error = 'Minted nfts queue is empty',
            }
        })
    end

    local nftId = peek()
    passOwnership(nftId, tags.Sender)
    dequeue()

    local totalRevenue = tonumber(tags.Quantity)
    local revenueShare = math.floor(totalRevenue * 0.4)
    --local contractShare = totalRevenue - (revenueShare * 2)

    -- Only send revenue if parents exist
    if s.nftParents[nftId][1] then
        ao.send({
            Target = s.paymentToken,
            Action = 'Transfer',
            Recipient = s.nftParents[nftId][1],
            Quantity = tostring(revenueShare)
        })
    end

    if s.nftParents[nftId][2] then
        ao.send({
            Target = s.paymentToken,
            Action = 'Transfer',
            Recipient = s.nftParents[nftId][2],
            Quantity = tostring(revenueShare)
        })
    end

    ao.send({
        Target = tags.Sender,
        Action = 'Purchase-Success',
        Data = {
            NftId = tostring(nftId),
            Rev1 = s.nftParents[nftId][1] or "",
            Rev2 = s.nftParents[nftId][2] or ""
        }
    })
end)

Handlers.add('addToQueue', 'AddToQueue', function(msg)
    if msg.From ~= ao.id and msg.Owner ~= s.rewardManager then
        return replyError(msg, 'AddToQueue', 'Only internal use')
    end

    msg.reply({
        Action = 'AddToQueue-Success',
        Data = {
            NewID = mintWithParents(nil, nil)
        }
    })
end)

-- Getter Handlers
Handlers.add('getUseCount', 'GetUseCount', function(msg)
    local tags = msg.Tags
    if not tags.NftId then
        return replyError(msg, 'GetUseCount', 'NftId is required')
    end

    msg.reply({
        Action = 'GetUseCount-Response',
        Data = {
            Count = s.useCount[tags.NftId] or 0
        }
    })
end)

Handlers.add('getPairUsedCount', 'GetPairUsedCount', function(msg)
    local tags = msg.Tags
    if not tags.Id1 then
        return replyError(msg, 'GetPairUsedCount', 'Id1 is required')
    end
    if not tags.Id2 then
        return replyError(msg, 'GetPairUsedCount', 'Id2 is required')
    end

    local key = generatePairKey(tags.Id1, tags.Id2)

    msg.reply({
        Action = 'GetPairUsedCount-Response',
        Data = {
            Count = s.pairUsedCount[key] or 0
        }
    })
end)

Handlers.add('getNftRevenues', 'GetNftRevenues', function(msg)
    local tags = msg.Tags
    if not tags.NftId then
        return replyError(msg, 'GetNftRevenues', 'NftId is required')
    end

    msg.reply({
        Action = 'GetNftRevenues-Response',
        Data = {
            Revenues = s.nftParents[tags.NftId] or {nil, nil}
        }
    })
end)

Handlers.add('getTimeUntilNextMint', 'GetTimeUntilNextMint', function(msg)
    local tags = msg.Tags
    if not tags.NftId then
        return replyError(msg, 'GetTimeUntilNextMint', 'NftId is required')
    end

    local lastUsed = s.lastUsedTime[tags.NftId] or 0
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
    local tags = msg.Tags
    if not tags.NftId then
        return replyError(msg, 'IsInCd', 'NftId is required')
    end

    local lastUsed = s.lastUsedTime[tags.NftId] or 0
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
    msg.reply({
        Action = 'GetNextIdInQueue-Response',
        Data = {
            NextId = peek()
        }
    })
end)

Handlers.add('getTokensByOwner', 'GetTokensByOwner', function(msg)
    local tags = msg.Tags
    if not tags.TokenOwner then
        return replyError(msg, 'GetTokensByOwner', 'TokenOwner address is required')
    end

    msg.reply({
        Action = 'GetTokensByOwner-Response',
        Data = {
            Tokens = s.tokensByOwner[tags.TokenOwner] or {}
        }
    })
end)
