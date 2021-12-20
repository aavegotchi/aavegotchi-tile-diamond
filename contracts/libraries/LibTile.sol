// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ERC998} from "../libraries/LibERC998.sol";
import {LibERC1155} from "../libraries/LibERC1155.sol";
import {LibAppStorage, AppStorage} from "../libraries/AppStorage.sol";

library LibTile {
  event TransferToParent(address indexed _toContract, uint256 indexed _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);

  function _equipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    ERC998.removeFromOwner(_owner, _tileId, 1);
    ERC998.addToParent(s.realmDiamond, _realmId, _tileId, 1);
    emit TransferToParent(s.realmDiamond, _realmId, _tileId, 1);
  }

  function _unequipTile(
    address _owner,
    uint256 _realmId,
    uint256 _tileId
  ) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();
    ERC998.removeFromParent(s.realmDiamond, _realmId, _tileId, 1);
    ERC998.addToOwner(_owner, _tileId, 1);
    LibERC1155._burn(_owner, _tileId, 1);
  }
}
