---
title: 'Functional Specification: SocialFi NFT-Pill System'

---

Got it 🚀 — let’s capture this idea into a clear **functional spec** for your **SocialFi NFT-Pill system**.

---

# Functional Specification: SocialFi NFT-Pill System

## 1. Overview

The **NFT-Pill platform** is a gamified SocialFi experience where users profit by interacting with others. Players acquire NFT-Pills, match with peers via a bot, mint new NFT-Pills, and share profits from sales. Each NFT-Pill has a limited lifespan (5 matches), creating a cycle of trading and burning.

---

## 2. Core Concepts

* **NFT-Pill**: A digital collectible (ERC-721 or ERC-1155 token).
* **Match Bot**: Automated service that pairs users randomly.
* **Sale Queue**: Smart contract mechanism to list newly minted NFT-Pills for sale.
* **Revenue Split**: 40% to User A, 40% to User B, 20% to protocol.
* **Burn Mechanism**: NFT-Pills expire after 5 matches and are removed from circulation.

---

## 3. User Flow

1. **Acquire NFT-Pill**

   * User mints or buys their initial NFT-Pill from the marketplace.

2. **Engage with Bot**

   * User activates the bot to be matched with another NFT-Pill holder.

3. **Match Event**

   * A new NFT-Pill is minted.
   * The new NFT-Pill is automatically queued for sale.

4. **Sale & Revenue Distribution**

   * When sold, sale proceeds are split:

     * 40% → First participant
     * 40% → Second participant
     * 20% → Protocol treasury

5. **Burn Cycle**

   * Each NFT-Pill can match 5 times.
   * After 5 matches, the NFT-Pill is burned.

6. **Profit Outcome**

   * Each match generates a potential 40% payout.
   * After 5 matches: **200% total earnings** in ETH.

---

## 4. Smart Contract Logic

* **Mint Function**: Creates new NFT-Pills on match.
* **Match Function**: Randomly pairs active NFT-Pill holders.
* **Sale Queue Contract**: Holds newly minted NFTs for automated sale.
* **Revenue Splitter**: Enforces 40-40-20 ETH distribution on each sale.
* **Burn Function**: Tracks match count and burns NFT-Pill after 5 uses.

---

## 5. Constraints & Assumptions

* Requires **on-chain randomness** (e.g., Chainlink VRF) for fair matching.
* Revenue assumes active buyers for queued NFT-Pills.
* Tokenomics may be inflationary if user growth slows (need balancing mechanics).
* Users must have ETH for gas fees.

---

## 6. Success Criteria

* Users can mint, match, and profit reliably.
* Revenue distribution works trustlessly via smart contracts.
* Dashboard (or bot UI) transparently shows match history, earnings, and burn countdown.
* SocialFi loop (profit from making “frens”) is fun and engaging.

---

⚡ Would you like me to also **draw a system diagram** (like the one I did for the AO/Apus flow) showing the lifecycle of an NFT-Pill through matches, sales, and burning?
