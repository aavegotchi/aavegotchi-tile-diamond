// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import {LibDiamond} from "./LibDiamond.sol";

struct TileType {
  uint16 tileType;
  uint256 width;
  uint256 height;
  uint256[] alchemicaCost; // [fud, fomo, alpha, kek]
  uint256 craftTime; // in blocks
}

struct QueueItem {
  uint256 id;
  uint256 readyBlock;
  uint256 tileType;
  bool claimed;
  address owner;
}

struct AppStorage {
  address realmDiamond;
  address aavegotchiDiamond;
  address glmr;
  address[] alchemicaAddresses;
  string baseUri;
  TileType[] tileTypes;
  QueueItem[] craftQueue;
  uint256 nextCraftId;
  //ERC1155 vars
  mapping(address => mapping(address => bool)) operators;
  //ERC998 vars
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftTileBalances;
  mapping(address => mapping(uint256 => uint256[])) nftTiles;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftTilesIndexes;
  mapping(address => mapping(uint256 => uint256)) ownerTilesBalances;
  mapping(address => uint256[]) ownerTiles;
  mapping(address => mapping(uint256 => uint256)) ownerTileIndexes;
}

library LibAppStorage {
  function diamondStorage() internal pure returns (AppStorage storage ds) {
    assembly {
      ds.slot := 0
    }
  }
}

contract Modifiers {
  AppStorage internal s;

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  modifier onlyRealmDiamond() {
    require(msg.sender == s.realmDiamond, "LibDiamond: Must be realm diamond");
    _;
  }
}
