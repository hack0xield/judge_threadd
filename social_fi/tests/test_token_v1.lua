-- Initialize state
NFTs = NFTs or {}
Metadata = Metadata or {}
NextID = NextID or 0
TokenName = TokenName or "MyNFT"
TokenSymbol = TokenSymbol or "MNFT"
BurnedTokens = BurnedTokens or {}
TokensByOwner = TokensByOwner or {}
AuthorizedMinter = AuthorizedMinter or nil

-- Helper function for error responses
function replyError(msg, action, errorMessage)
    return msg.reply({
        Action = action .. '-Error',
        Data = {
            Error = errorMessage
        }
    })
end

-- Get Token Info Handler
Handlers.add('tokenInfo', 'TokenInfo', function(msg)
  msg.reply({
    Action = 'TokenInfo-Response',
    Data = {
      Name = TokenName,
      Symbol = TokenSymbol,
      TotalSupply = NextID
    }
  })
end)

-- Mint Handler in token contract
Handlers.add('mint', 'Mint', function(msg)
  if msg.From ~= ao.id and msg.From ~= AuthorizedMinter then
    return replyError(msg, 'Mint', 'Only owner or authorized minter can mint NFTs!')
  end
  if not msg.To then
    return replyError(msg, 'Mint', 'Recipient address (To) is required!')
  end

  local nftID = NextID
  NextID = NextID + 1

  NFTs[nftID] = msg.To
  if msg.MetadataTxID then
    Metadata[nftID] = msg.MetadataTxID
  end

  msg.reply({
    Action = 'Mint-Success',
    Data = {
      NFT_ID = nftID,
      Owner = msg.To
    }
  })
end)

-- Transfer Handler
Handlers.add('transfer', 'Transfer', function(msg)
  if not msg.NFT_ID then
    return replyError(msg, 'Transfer', 'NFT_ID is required!')
  end
  if not msg.Recipient then
    return replyError(msg, 'Transfer', 'Recipient is required!')
  end
  if BurnedTokens[msg.NFT_ID] then
    return replyError(msg, 'Transfer', 'Cannot transfer burned token!')
  end

  local owner = NFTs[msg.NFT_ID]
  if owner ~= msg.From then
    return replyError(msg, 'Transfer', 'Only the owner can transfer this NFT!')
  end

  -- Remove token from previous owner's array
  if TokensByOwner[owner] then
    for i, tokenId in ipairs(TokensByOwner[owner]) do
      if tokenId == msg.NFT_ID then
        table.remove(TokensByOwner[owner], i)
        break
      end
    end
  end

  -- Add token to new owner's array
  TokensByOwner[msg.Recipient] = TokensByOwner[msg.Recipient] or {}
  table.insert(TokensByOwner[msg.Recipient], msg.NFT_ID)

  NFTs[msg.NFT_ID] = msg.Recipient

  msg.reply({
    Action = 'Transfer-Success',
    Data = {
      NFT_ID = msg.NFT_ID,
      NewOwner = msg.Recipient
    }
  })
end)

-- Metadata Handler
Handlers.add('metadata', 'Metadata', function(msg)
  if not msg.NFT_ID then
    return replyError(msg, 'Metadata', 'NFT_ID is required!')
  end

  local metadataTxID = Metadata[msg.NFT_ID]
  if not metadataTxID then
    return replyError(msg, 'Metadata', 'Metadata not found for this NFT!')
  end

  msg.reply({
    Action = 'Metadata-Response',
    Data = {
      NFT_ID = msg.NFT_ID,
      MetadataTxID = metadataTxID
    }
  })
end)

-- Owner Of Handler
Handlers.add('ownerOf', 'OwnerOf', function(msg)
  if not msg.NFT_ID then
    return replyError(msg, 'OwnerOf', 'NFT_ID is required!')
  end
  
  local owner = NFTs[msg.NFT_ID]
  if not owner then
    return replyError(msg, 'OwnerOf', 'NFT does not exist!')
  end

  msg.reply({
    Action = 'OwnerOf-Response',
    Data = {
      NFT_ID = msg.NFT_ID,
      Owner = owner
    }
  })
end)

-- Balance Of Handler
Handlers.add('balanceOf', 'BalanceOf', function(msg)
  if not msg.Address then
    return replyError(msg, 'BalanceOf', 'Address is required!')
  end

  local balance = 0
  
  for _, owner in pairs(NFTs) do
    if owner == msg.Address then
      balance = balance + 1
    end
  end

  msg.reply({
    Action = 'BalanceOf-Response',
    Data = {
      Address = msg.Address,
      Balance = balance
    }
  })
end)

-- Burn Handler
Handlers.add('burn', 'Burn', function(msg)
  if not msg.NFT_ID then
    return replyError(msg, 'Burn', 'NFT_ID is required!')
  end
  
  local owner = NFTs[msg.NFT_ID]
  if owner ~= msg.From then
    return replyError(msg, 'Burn', 'Only the owner can burn this NFT!')
  end
  if BurnedTokens[msg.NFT_ID] then
    return replyError(msg, 'Burn', 'Token is already burned!')
  end

  -- Remove token from owner's array
  if TokensByOwner[owner] then
    for i, tokenId in ipairs(TokensByOwner[owner]) do
      if tokenId == msg.NFT_ID then
        table.remove(TokensByOwner[owner], i)
        break
      end
    end
  end

  -- Mark token as burned
  BurnedTokens[msg.NFT_ID] = true
  NFTs[msg.NFT_ID] = nil
  Metadata[msg.NFT_ID] = nil

  msg.reply({
    Action = 'Burn-Success',
    Data = {
      NFT_ID = msg.NFT_ID,
      BurnedBy = msg.From
    }
  })
end)

-- Get Tokens By Owner Handler
Handlers.add('tokensOfOwner', 'TokensOfOwner', function(msg)
  if not msg.Address then
    return replyError(msg, 'TokensOfOwner', 'Address is required!')
  end
  
  local tokens = TokensByOwner[msg.Address] or {}
  local activeTokens = {}
  
  -- Filter out burned tokens
  for _, tokenId in ipairs(tokens) do
    if not BurnedTokens[tokenId] then
      table.insert(activeTokens, tokenId)
    end
  end

  msg.reply({
    Action = 'TokensOfOwner-Response',
    Data = {
      Address = msg.Address,
      Tokens = activeTokens,
      Count = #activeTokens
    }
  })
end)

-- Check if token is burned
Handlers.add('isBurned', 'IsBurned', function(msg)
  if not msg.NFT_ID then
    return replyError(msg, 'IsBurned', 'NFT_ID is required!')
  end
  
  msg.reply({
    Action = 'IsBurned-Response',
    Data = {
      NFT_ID = msg.NFT_ID,
      IsBurned = BurnedTokens[msg.NFT_ID] or false
    }
  })
end)
