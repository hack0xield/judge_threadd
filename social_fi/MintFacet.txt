// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibNftPairing} from "../libraries/LibNftPairing.sol";

contract MintFacet is Modifiers {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    event NftMint(
        uint256 indexed id1,
        uint256 indexed id2,
        uint256 indexed newId
    );

    event NftPurchase(address indexed owner, uint256 indexed nftId);

    function getUseCount(uint256 id_) external view returns (uint256) {
        return s.useCount[id_];
    }

    function getPairUsedCount(
        uint256 id1_,
        uint256 id2_
    ) external view returns (uint256) {
        bytes32 key = _keyForIdsPair(id1_, id2_);
        return s.pairUsedCount[key];
    }

    function getNftRevenues(
        uint256 id_
    ) external view returns (address[2] memory) {
        return s.nftRevenues[id_];
    }

    function getNextIdInQueue() external view returns (uint256) {
        return uint256(s.idsQueue.front());
    }

    function getTimeUntilNextMint(uint256 id_) public view returns (uint256) {
        uint256 passedTime = block.timestamp - s.lastUsedTime[id_];
        if (passedTime < s.nftCdSec) {
            return s.nftCdSec - passedTime;
        }
        return 0;
    }

    function isInCd(uint256 id_) public view returns (bool) {
        return getTimeUntilNextMint(id_) > 0;
    }

    function setRewardManager(
        address rewardManager_,
        uint256 nftCount_
    ) external onlyOwner {
        s.rewardManager = rewardManager_;
        LibNftPairing.mint(nftCount_, s.rewardManager);
    }

    function setNftMaxUseCount(uint256 limit_) external onlyRewardManager {
        s.maxUseCount = limit_;
    }

    function setNftBuyPrice(uint256 price_) external onlyRewardManager {
        s.nftBuyPrice = price_;
    }

    function setMintCdSec(uint256 cdSec_) external onlyRewardManager {
        s.nftCdSec = cdSec_;
    }

    function setPairingLimit(uint256 limit_) external onlyRewardManager {
        s.pairingLimit = limit_;
    }

    function setLastUsedTime(uint256 id_, uint256 time_) external onlyRewardManager {
        s.lastUsedTime[id_] = time_;
    }

    function squeezeQueue() external onlyRewardManager {
        _squeezeQueue();
    }

    function mint(
        address rev1_,
        uint256 id1_,
        address rev2_,
        uint256 id2_
    ) external onlyRewardManager {
        bytes32 pairKey = _checkMintAllowness(rev1_, id1_, rev2_, id2_);

        uint256 newId = _makePairedNft(rev1_, rev2_);

        _incUseCount(rev1_, id1_);
        _incUseCount(rev2_, id2_);

        s.lastUsedTime[id1_] = block.timestamp;
        s.lastUsedTime[id2_] = block.timestamp;
        s.pairUsedCount[pairKey] += 1;

        emit NftMint(id1_, id2_, newId);
    }

    function mintIdle(
        address rev1_,
        uint256 id1_,
        address rev2_,
        uint256 id2_
    ) external onlyRewardManager {
        _checkMintAllowness(rev1_, id1_, rev2_, id2_);

        s.lastUsedTime[id1_] = block.timestamp;
        s.lastUsedTime[id2_] = block.timestamp;
    }

    function _checkMintAllowness(
        address rev1_,
        uint256 id1_,
        address rev2_,
        uint256 id2_
    ) internal view returns (bytes32 key) {
        require(rev1_ != rev2_, "MintFacet: rev1 and rev2 should be different");
        require(address(0) != rev1_, "MintFacet: rev1 invalid address");
        require(address(0) != rev2_, "MintFacet: rev2 invalid address");
        require(s.owners[id1_] == rev1_, "MintFacet: rev1 is not owner of id1");
        require(s.owners[id2_] == rev2_, "MintFacet: rev2 is not owner of id2");
        require(isInCd(id1_) == false, "MintFacet: id1 Nft is in cooldown");
        require(isInCd(id2_) == false, "MintFacet: id2 Nft is in cooldown");

        key = _keyForIdsPair(id1_, id2_);
        require(
            s.pairUsedCount[key] < s.pairingLimit,
            "MintFacet: pairing limit reached for these nfts"
        );
    }

    function _keyForIdsPair(
        uint256 id1_,
        uint256 id2_
    ) internal pure returns (bytes32) {
        (uint256 elem1, uint256 elem2) = id1_ < id2_
            ? (id1_, id2_)
            : (id2_, id1_);

        return keccak256(abi.encodePacked(elem1, elem2));
    }

    function _makePairedNft(
        address rev1_,
        address rev2_
    ) internal returns (uint256 newId) {
        newId = s.tokenIdsCount;
        s.nftRevenues[newId][0] = rev1_;
        s.nftRevenues[newId][1] = rev2_;

        LibNftPairing.mint(1, address(this));

        s.idsQueue.pushBack(bytes32(newId));
    }

    function _incUseCount(address rev_, uint256 id_) internal {
        s.useCount[id_] += 1;
        if (s.useCount[id_] >= s.maxUseCount) {
            LibNftPairing.transfer(rev_, address(0), id_); //burn
            delete s.useCount[id_];
        }
    }

    function purchaseNft() external payable {
        require(
            s.idsQueue.length() > 0,
            "MintFacet: Minted nfts queue is empty"
        );
        require(
            s.nftBuyPrice <= msg.value,
            "MintFacet: Insufficient ethers value"
        );

        _squeezeQueue();
        uint256 nftId = uint256(s.idsQueue.popFront());
        _purchaseNft(nftId);
    }

    function purchaseRefNft(
        uint256 id_,
        bytes calldata signature_
    ) external payable {
        require(
            s.owners[id_] == address(this),
            "MintFacet: this NFT already purchased"
        );
        require(
            s.nftBuyPrice <= msg.value,
            "MintFacet: Insufficient ethers value"
        );

        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(
            keccak256(abi.encodePacked(msg.sender, id_))
        );
        require(
            s.rewardManager == ECDSA.recover(hash, signature_),
            "MintFacet: Sig validation failed"
        );

        _purchaseNft(id_);
    }

    function _purchaseNft(uint256 nftId) internal {
        LibNftPairing.transfer(address(this), msg.sender, nftId);

        (bool success, ) = s.nftRevenues[nftId][0].call{
            value: (s.nftBuyPrice / 100) * 40
        }("");
        require(success, "MintFacet: rev 0 call failed");

        (success, ) = s.nftRevenues[nftId][1].call{
            value: (s.nftBuyPrice / 100) * 40
        }("");
        require(success, "MintFacet: rev 1 call failed");

        delete s.nftRevenues[nftId];
        emit NftPurchase(msg.sender, nftId);
    }

    function _squeezeQueue() internal {
        while (s.idsQueue.length() > 0) {
            uint256 id = uint256(s.idsQueue.front());
            if (s.owners[id] == address(this)) {
                return;
            }
            s.idsQueue.popFront();
        }
    }

    function withdraw() external onlyRewardManager {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "MintFacet: Withdraw failed");
    }
}
