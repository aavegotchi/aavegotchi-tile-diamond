// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage, TileType} from "./AppStorage.sol";
import {LibERC1155} from "./LibERC1155.sol";

struct ItemTypeIO {
  uint256 balance;
  uint256 itemId;
  TileType tileType;
}

library ERC998 {
  function itemBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
    internal
    view
    returns (ItemTypeIO[] memory itemBalancesOfTokenWithTypes_)
  {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 count = s.nftTiles[_tokenContract][_tokenId].length;
    itemBalancesOfTokenWithTypes_ = new ItemTypeIO[](count);
    for (uint256 i; i < count; i++) {
      uint256 itemId = s.nftTiles[_tokenContract][_tokenId][i];
      uint256 bal = s.nftTileBalances[_tokenContract][_tokenId][itemId];
      itemBalancesOfTokenWithTypes_[i].itemId = itemId;
      itemBalancesOfTokenWithTypes_[i].balance = bal;
      itemBalancesOfTokenWithTypes_[i].tileType = s.tileTypes[itemId];
    }
  }

  function addToParent(
    address _toContract,
    uint256 _toTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.nftTileBalances[_toContract][_toTokenId][_id] += _value;
    if (s.nftTilesIndexes[_toContract][_toTokenId][_id] == 0) {
      s.nftTiles[_toContract][_toTokenId].push(uint16(_id));
      s.nftTilesIndexes[_toContract][_toTokenId][_id] = s.nftTiles[_toContract][_toTokenId].length;
    }
  }

  function addToOwner(
    address _to,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    s.ownerTilesBalances[_to][_id] += _value;
    if (s.ownerTileIndexes[_to][_id] == 0) {
      s.ownerTiles[_to].push(uint16(_id));
      s.ownerTileIndexes[_to][_id] = s.ownerTiles[_to].length;
    }
  }

  function removeFromOwner(
    address _from,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 bal = s.ownerTilesBalances[_from][_id];
    require(_value <= bal, "LibItems: Doesn't have that many to transfer");
    bal -= _value;
    s.ownerTilesBalances[_from][_id] = bal;
    if (bal == 0) {
      uint256 index = s.ownerTileIndexes[_from][_id] - 1;
      uint256 lastIndex = s.ownerTiles[_from].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.ownerTiles[_from][lastIndex];
        s.ownerTiles[_from][index] = uint16(lastId);
        s.ownerTileIndexes[_from][lastId] = index + 1;
      }
      s.ownerTiles[_from].pop();
      delete s.ownerTileIndexes[_from][_id];
    }
  }

  function removeFromParent(
    address _fromContract,
    uint256 _fromTokenId,
    uint256 _id,
    uint256 _value
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    uint256 bal = s.nftTileBalances[_fromContract][_fromTokenId][_id];
    require(_value <= bal, "Items: Doesn't have that many to transfer");
    bal -= _value;
    s.nftTileBalances[_fromContract][_fromTokenId][_id] = bal;
    if (bal == 0) {
      uint256 index = s.nftTilesIndexes[_fromContract][_fromTokenId][_id] - 1;
      uint256 lastIndex = s.nftTiles[_fromContract][_fromTokenId].length - 1;
      if (index != lastIndex) {
        uint256 lastId = s.nftTiles[_fromContract][_fromTokenId][lastIndex];
        s.nftTiles[_fromContract][_fromTokenId][index] = uint16(lastId);
        s.nftTilesIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
      }
      s.nftTiles[_fromContract][_fromTokenId].pop();
      delete s.nftTilesIndexes[_fromContract][_fromTokenId][_id];
    }
  }
}
