// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface RealmDiamond {
  struct ParcelOutput {
    string parcelId;
    string parcelAddress;
    address owner;
    uint256 coordinateX; //x position on the map
    uint256 coordinateY; //y position on the map
    uint256 size; //0=humble, 1=reasonable, 2=spacious vertical, 3=spacious horizontal, 4=partner
    uint256 district;
    uint256[4] boost;
  }

  function checkCoordinates(
    uint256 _tokenId,
    uint256 _coordinateX,
    uint256 _coordinateY,
    uint256 _tileId
  ) external view;

  function upgradeTile(
    uint256 _realmId,
    uint256 _prevTileId,
    uint256 _nextTileId
  ) external;
}
