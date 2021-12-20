// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ERC998, ItemTypeIO} from "../libraries/LibERC998.sol";
import {LibAppStorage, TileType, QueueItem, Modifiers} from "../libraries/AppStorage.sol";
import {LibStrings} from "../libraries/LibStrings.sol";
import {LibMeta} from "../libraries/LibMeta.sol";
import {LibERC1155} from "../libraries/LibERC1155.sol";
import {ERC998} from "../libraries/LibERC998.sol";
import {LibERC20} from "../libraries/LibERC20.sol";
import {LibTile} from "../libraries/LibTile.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {RealmDiamond} from "../interfaces/RealmDiamond.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract TileFacet is Modifiers {
    event AddedToQueue(
        uint256 indexed _queueId,
        uint256 indexed _tileId,
        uint256 _readyBlock,
        address _sender
    );

    event QueueClaimed(uint256 indexed _queueId);

    event CraftTimeReduced(uint256 indexed _queueId, uint256 _blocksReduced);

    /***********************************|
   |             Read Functions         |
   |__________________________________*/

    struct TileIdIO {
        uint256 tileId;
        uint256 balance;
    }

    ///@notice Returns balance for each tile that exists for an account
    ///@param _account Address of the account to query
    ///@return bals_ An array of structs,each struct containing details about each tile owned
    function tileBalances(address _account)
        external
        view
        returns (TileIdIO[] memory bals_)
    {
        uint256 count = s.ownerTiles[_account].length;
        bals_ = new TileIdIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 tileId = s.ownerTiles[_account][i];
            bals_[i].balance = s.ownerTilesBalances[_account][tileId];
            bals_[i].tileId = tileId;
        }
    }

    ///@notice Returns balance for each tile(and their types) that exists for an account
    ///@param _owner Address of the account to query
    ///@return output_ An array of structs containing details about each tile owned(including the tile types)
    function tileBalancesWithTypes(address _owner)
        external
        view
        returns (ItemTypeIO[] memory output_)
    {
        uint256 count = s.ownerTiles[_owner].length;
        output_ = new ItemTypeIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 tileId = s.ownerTiles[_owner][i];
            output_[i].balance = s.ownerTilesBalances[_owner][tileId];
            output_[i].itemId = tileId;
            output_[i].tileType = s.tileTypes[tileId];
        }
    }

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return bal_    The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256 bal_)
    {
        bal_ = s.ownerTilesBalances[_owner][_id];
    }

    /// @notice Get the balance of a non-fungible parent token
    /// @param _tokenContract The contract tracking the parent token
    /// @param _tokenId The ID of the parent token
    /// @param _id     ID of the token
    /// @return value The balance of the token
    function balanceOfToken(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _id
    ) public view returns (uint256 value) {
        value = s.nftTileBalances[_tokenContract][_tokenId][_id];
    }

    ///@notice Returns the balances for all ERC1155 items for a ERC721 token
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return bals_ An array of structs containing details about each item owned
    function tileBalancesOfToken(address _tokenContract, uint256 _tokenId)
        public
        view
        returns (TileIdIO[] memory bals_)
    {
        uint256 count = s.nftTiles[_tokenContract][_tokenId].length;
        bals_ = new TileIdIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 tileId = s.nftTiles[_tokenContract][_tokenId][i];
            bals_[i].tileId = tileId;
            bals_[i].balance = s.nftTileBalances[_tokenContract][_tokenId][
                tileId
            ];
        }
    }

    ///@notice Returns the balances for all ERC1155 items for a ERC721 token
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return tileBalancesOfTokenWithTypes_ An array of structs containing details about each tile owned(including tile types)
    function tileBalancesOfTokenWithTypes(
        address _tokenContract,
        uint256 _tokenId
    )
        external
        view
        returns (ItemTypeIO[] memory tileBalancesOfTokenWithTypes_)
    {
        tileBalancesOfTokenWithTypes_ = ERC998.itemBalancesOfTokenWithTypes(
            _tokenContract,
            _tokenId
        );
    }

    function tileBalancesOfTokenByIds(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            balances[i] = balanceOfToken(_tokenContract, _tokenId, _ids[i]);
        }
        return balances;
    }

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return bals   The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory bals)
    {
        require(
            _owners.length == _ids.length,
            "TileFacet: _owners length not same as _ids length"
        );
        bals = new uint256[](_owners.length);
        for (uint256 i; i < _owners.length; i++) {
            uint256 id = _ids[i];
            address owner = _owners[i];
            bals[i] = s.ownerTilesBalances[owner][id];
        }
    }

    ///@notice Query the item type of a particular tile
    ///@param _tileTypeId Item to query
    ///@return tileType A struct containing details about the item type of an item with identifier `_itemId`
    function getTileType(uint256 _tileTypeId)
        external
        view
        returns (TileType memory tileType)
    {
        require(
            _tileTypeId < s.tileTypes.length,
            "TileFacet: Item type doesn't exist"
        );
        tileType = s.tileTypes[_tileTypeId];
    }

    ///@notice Query the item type of multiple tile types
    ///@param _tileTypeIds An array containing the identifiers of items to query
    ///@return tileTypes_ An array of structs,each struct containing details about the item type of the corresponding item
    function getTileTypes(uint256[] calldata _tileTypeIds)
        external
        view
        returns (TileType[] memory tileTypes_)
    {
        if (_tileTypeIds.length == 0) {
            tileTypes_ = s.tileTypes;
        } else {
            tileTypes_ = new TileType[](_tileTypeIds.length);
            for (uint256 i; i < _tileTypeIds.length; i++) {
                tileTypes_[i] = s.tileTypes[_tileTypeIds[i]];
            }
        }
    }

    /**
        @notice Get the URI for a voucher type
        @return URI for token type
    */
    function uri(uint256 _id) external view returns (string memory) {
        require(_id < s.tileTypes.length, "TileFacet: Item _id not found");
        return LibStrings.strWithUint(s.baseUri, _id);
    }

    function getAlchemicaAddresses() external view returns (address[] memory) {
        return s.alchemicaAddresses;
    }

    /***********************************|
   |             Write Functions        |
   |__________________________________*/

    function craftTile(uint256[] calldata _tileTypes) external {
        for (uint8 i = 0; i < _tileTypes.length; i++) {
            //take the required alchemica
            TileType memory tileType = s.tileTypes[_tileTypes[i]];
            for (uint8 j = 0; j < tileType.alchemicaCost.length; j++) {
                LibERC20.transferFrom(
                    s.alchemicaAddresses[j],
                    msg.sender,
                    address(this),
                    s.tileTypes[_tileTypes[i]].alchemicaCost[j]
                );
            }

            uint256 readyBlock = block.number + tileType.craftTime;

            //put the tile into a queue
            //each wearable needs a unique queue id
            s.craftQueue.push(
                QueueItem(
                    s.nextCraftId,
                    readyBlock,
                    _tileTypes[i],
                    false,
                    msg.sender
                )
            );

            emit AddedToQueue(
                s.nextCraftId,
                _tileTypes[i],
                readyBlock,
                msg.sender
            );
            s.nextCraftId++;
        }
        //after queue is over, user can claim tile
    }

    function reduceCraftTime(
        uint256[] calldata _queueIds,
        uint256[] calldata _amounts
    ) external {
        require(
            _queueIds.length == _amounts.length,
            "TileFacet: Mismatched arrays"
        );
        for (uint8 i; i < _queueIds.length; i++) {
            uint256 queueId = _queueIds[i];
            QueueItem storage queueItem = s.craftQueue[queueId];
            require(msg.sender == queueItem.owner, "TileFacet: not owner");

            require(
                block.number <= queueItem.readyBlock,
                "TileFacet: tile already done"
            );

            IERC20 glmr = IERC20(s.glmr);
            require(
                glmr.balanceOf(msg.sender) >= _amounts[i],
                "TileFacet: not enough GLMR"
            );
            glmr.burnFrom(msg.sender, _amounts[i]);

            queueItem.readyBlock -= _amounts[i];
            emit CraftTimeReduced(queueId, _amounts[i]);
        }
    }

    function claimTile(uint256[] calldata _queueIds) external {
        for (uint8 i; i < _queueIds.length; i++) {
            uint256 queueId = _queueIds[i];
            QueueItem memory queueItem = s.craftQueue[queueId];
            require(msg.sender == queueItem.owner, "TileFacet: not owner");
            require(!queueItem.claimed, "TileFacet: already claimed");

            require(
                block.number >= queueItem.readyBlock,
                "TileFacet: tile not ready"
            );

            // mint tile
            LibERC1155._safeMint(msg.sender, queueItem.tileType, queueItem.id);
            // remove tile from queue array
            s.craftQueue[queueId] = s.craftQueue[s.craftQueue.length - 1];
            s.craftQueue.pop();
            emit QueueClaimed(queueId);
        }
    }

    function equipTile(
        address _owner,
        uint256 _realmId,
        uint256 _tileId
    ) external onlyRealmDiamond {
        LibTile._equipTile(_owner, _realmId, _tileId);
    }

    function unequipTile(
        address _owner,
        uint256 _realmId,
        uint256 _tileId
    ) external onlyRealmDiamond {
        LibTile._unequipTile(_owner, _realmId, _tileId);
    }

    function getCraftQueue()
        external
        view
        returns (QueueItem[] memory output_)
    {
        uint256 counter;
        for (uint256 i; i < s.craftQueue.length; i++) {
            if (s.craftQueue[i].owner == msg.sender) {
                output_[counter] = s.craftQueue[i];
                counter++;
            }
        }
    }

    /***********************************|
   |             Owner Functions        |
   |__________________________________*/

    /**
        @notice Set the base url for all voucher types
        @param _value The new base url        
    */
    function setBaseURI(string memory _value) external onlyOwner {
        s.baseUri = _value;
        for (uint256 i; i < s.tileTypes.length; i++) {
            emit LibERC1155.URI(LibStrings.strWithUint(_value, i), i);
        }
    }

    function setAlchemicaAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        s.alchemicaAddresses = _addresses;
    }

    function setAddresses(
        address _aavegotchiDiamond,
        address _realmDiamond,
        address _glmr
    ) external onlyOwner {
        s.aavegotchiDiamond = _aavegotchiDiamond;
        s.realmDiamond = _realmDiamond;
        s.glmr = _glmr;
    }

    function addTileTypes(TileType[] calldata _tileTypes) external onlyOwner {
        for (uint16 i = 0; i < _tileTypes.length; i++) {
            s.tileTypes.push(
                TileType(
                    _tileTypes[i].tileType,
                    _tileTypes[i].width,
                    _tileTypes[i].height,
                    _tileTypes[i].alchemicaCost,
                    _tileTypes[i].craftTime
                )
            );
        }
    }

    function eraseTileTypes() external onlyOwner {
        for (uint256 i; i < s.tileTypes.length; i++) {
            delete s.tileTypes[i];
        }
    }

    function editTileType(uint256 _typeId, TileType calldata _tileType)
        external
        onlyOwner
    {
        s.tileTypes[_typeId] = _tileType;
    }
}
