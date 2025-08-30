-- test-logic-contract.lua

s = s or {
    parentTest = nil,  -- Logic contract test instance
    tokenContract = nil,
    nativeToken = nil,
    user1 = "Ah2Rd3LFTHszeGBKdZY3tm2YBOH7uV6MlyVZ-ZQg36Q",
    user2 = "W-1ZqdttEYx9oIdvU130m2z8GxYSHqtjzU-qMoRFcD4",
    id1 = 0,
    id2 = 1,
    id3 = 2,
    id4 = 3,
    nftBuyPrice = 100   -- Constant for NFT purchase price
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

-- Helper functions
local function getBalance(target)
    local result = ao.send({
        Target = s.nativeToken,
        Action = "Balance",
        Target = target
    })
    
    if not result or result.Error then
        return replyError(msg, 'GetBalance', 'Failed to get balance: ' .. (result.Error or "no response"))
    end
    
    return tonumber(result.Data.Balance)
end

local function transferNft(from, to, tokenId)
    local result = ao.send({
        Target = s.tokenContract,
        Action = "Transfer",
        From = from,
        To = to,
        NFT_ID = tokenId
    })
    
    if not result or result.Error then
        return replyError(msg, 'TransferNft', 'Transfer failed: ' .. (result.Error or "no response"))
    end
    
    return result
end

-- Initialize test environment
Handlers.add("before", "Before", function(msg)
    if not msg.ParentTest then
        return replyError(msg, 'Before', 'Parent test contract ID required')
    end
    if not msg.TokenContract then
        return replyError(msg, 'Before', 'Token contract ID required')
    end
    if not msg.NativeToken then
        return replyError(msg, 'Before', 'Native token process ID required')
    end
    if not msg.User1 then
        return replyError(msg, 'Before', 'User1 address required')
    end
    if not msg.User2 then
        return replyError(msg, 'Before', 'User2 address required')
    end
    
    s.parentTest = msg.ParentTest
    s.tokenContract = msg.TokenContract
    s.nativeToken = msg.NativeToken
    s.user1 = msg.User1
    s.user2 = msg.User2
    
    msg.reply({
        Action = "Before-Success",
        Data = {
            State = s
        }
    })
end)

-- Test "Mint Initial"
Handlers.add("testMintInitial", "TestMintInitial", function(msg)
    if not s.parentTest then
        return replyError(msg, 'TestMintInitial', 'Test environment not initialized')
    end

    print("hello1")
    -- Test 1: mint with empty address rev1
    local tx1 = ao.send({
        Target = s.parentTest,
        Action = "Mint",
        From = ao.id,
        Rev1 = "",  -- zero address
        Id1 = s.id1,
        Rev2 = s.user2,
        Id2 = s.id2
    })
    print("hello11")
    
    -- Test 2: mint with empty address rev2
    local tx2 = ao.send({
        Target = s.parentTest,
        Action = "Mint",
        From = ao.id,
        Rev1 = s.user1,
        Id1 = s.id1,
        Rev2 = "",  -- zero address
        Id2 = s.id2
    })
    
    -- Test 3: mint with same addresses
    local tx3 = ao.send({
        Target = s.parentTest,
        Action = "Mint",
        From = ao.id,
        Rev1 = s.user1,
        Id1 = s.id1,
        Rev2 = s.user1,
        Id2 = s.id2
    })
    
    -- Test 4: mint without ownership
    local tx4 = ao.send({
        Target = s.parentTest,
        Action = "Mint",
        From = ao.id,
        Rev1 = s.user1,
        Id1 = s.id1,
        Rev2 = s.user2,
        Id2 = s.id2
    })
    print("hello2")
    print(tx1)

    -- Check responses for expected errors
    if not (tx1.Data and tx1.Data.Error and tx1.Data.Error:find("rev1 invalid address")) then
        return replyError(msg, 'TestMintInitial', 'Test 1 failed: Should fail with invalid address')
    end
    
    if not (tx2.Data and tx2.Data.Error and tx2.Data.Error:find("rev2 invalid address")) then
        return replyError(msg, 'TestMintInitial', 'Test 2 failed: Should fail with invalid address')
    end
    
    if not (tx3.Data and tx3.Data.Error and tx3.Data.Error:find("should be different")) then
        return replyError(msg, 'TestMintInitial', 'Test 3 failed: Should fail with same addresses')
    end
    
    if not (tx4.Data and tx4.Data.Error and tx4.Data.Error:find("not owner")) then
        return replyError(msg, 'TestMintInitial', 'Test 4 failed: Should fail with ownership check')
    end

    -- Transfer NFTs to test users
    local transferResult = transferNft(ao.id, s.user1, s.id1)
    if not transferResult then
        return replyError(msg, 'TestMintInitial', 'Failed to transfer NFT to user1')
    end
    
    transferResult = transferNft(ao.id, s.user2, s.id2)
    if not transferResult then
        return replyError(msg, 'TestMintInitial', 'Failed to transfer NFT to user2')
    end

    -- Test 5: successful mint
    local tx5 = ao.send({
        Target = s.parentTest,
        Action = "Mint",
        From = ao.id,
        Rev1 = s.user1,
        Id1 = s.id1,
        Rev2 = s.user2,
        Id2 = s.id2
    })
    
    if not tx5.Data.Success then
        return replyError(msg, 'TestMintInitial', 'Test 5 failed: Mint should succeed')
    end
    
    msg.reply({
        Action = "TestMintInitial-Results",
        Data = {
            Tests = {tx1, tx2, tx3, tx4, tx5}
        }
    })
end)

-- Test "Try Mint In CoolDown"
Handlers.add("testMintInCoolDown", "TestMintInCoolDown", function(msg)
    -- Try immediate mint (should fail)
    local tx1 = ao.send({
        Target = s.parentTest,
        Action = "Mint",
        From = ao.id,
        Rev1 = s.user1,
        Id1 = s.id1,
        Rev2 = s.user2,
        Id2 = s.id2
    })
    
    if not (tx1.Data and tx1.Data.Error and tx1.Data.Error:find("in cooldown")) then
        return replyError(msg, 'TestMintInCoolDown', 'Test 1 failed: Should fail with cooldown')
    end
    
    -- Wait for cooldown
    os.sleep(2.1)
    
    -- Try mint again (should fail due to pairing limit)
    local tx2 = ao.send({
        Target = s.parentTest,
        Action = "Mint",
        From = ao.id,
        Rev1 = s.user1,
        Id1 = s.id1,
        Rev2 = s.user2,
        Id2 = s.id2
    })
    
    if not (tx2.Data and tx2.Data.Error and tx2.Data.Error:find("pairing limit")) then
        return replyError(msg, 'TestMintInCoolDown', 'Test 2 failed: Should fail with pairing limit')
    end
    
    msg.reply({
        Action = "TestMintInCoolDown-Results",
        Data = {
            Tests = {tx1, tx2}
        }
    })
end)

-- Test "purchaseNft"
Handlers.add("testPurchaseNft", "TestPurchaseNft", function(msg)
    -- Get initial balances
    local balanceBefore1 = getBalance(s.user1)
    local balanceBefore2 = getBalance(s.user2)
    local balanceBeforeContract = getBalance(s.parentTest)
    
    -- Purchase NFT
    local tx = ao.send({
        Target = s.parentTest,
        Action = "PurchaseNft",
        FromMocked = s.user1,
        Quantity = s.nftBuyPrice
    })
    
    if not tx.Data.Success then
        return replyError(msg, 'TestPurchaseNft', 'Purchase failed')
    end
    
    -- Check balances after purchase
    local balanceAfter1 = getBalance(s.user1)
    local balanceAfter2 = getBalance(s.user2)
    local balanceAfterContract = getBalance(s.parentTest)
    
    -- Verify balance changes (40% each to rev1/rev2, 20% to contract)
    if balanceBefore1 - balanceAfter1 ~= 60 then
        return replyError(msg, 'TestPurchaseNft', 'User1 balance change incorrect')
    end
    if balanceAfter2 - balanceBefore2 ~= 40 then
        return replyError(msg, 'TestPurchaseNft', 'User2 balance change incorrect')
    end
    if balanceAfterContract - balanceBeforeContract ~= 20 then
        return replyError(msg, 'TestPurchaseNft', 'Contract balance change incorrect')
    end
    
    msg.reply({
        Action = "TestPurchaseNft-Results",
        Data = {
            Purchase = tx,
            BalanceChanges = {
                User1 = balanceAfter1 - balanceBefore1,
                User2 = balanceAfter2 - balanceBefore2,
                Contract = balanceAfterContract - balanceBeforeContract
            }
        }
    })
end)
