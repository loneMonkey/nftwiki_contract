// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract minion_erc1155 is ERC1155, Ownable, ERC1155Supply {

    uint public minionSupply;
    uint public maxMinionSupply=1<<255;
    mapping(uint => string) public tokenURI;
    mapping(uint => uint) public supplyLimit;
    constructor() ERC1155("") {}

    function setURI(uint _id,string memory newuri) public onlyOwner {
        if(bytes(tokenURI[_id]).length == 0){
            tokenURI[_id] = newuri;
            emit URI(newuri, _id);
        }
    }
    function setMaxMinionSupply(uint limit)public onlyOwner{
        require(maxMinionSupply==1<<255,"Max limit set already");
        maxMinionSupply=limit;
    }

    function uri(uint _id) public override view returns (string memory) {
        return tokenURI[_id];
    }

    function mint(address account, uint256 id, uint256 amount,uint256 limit,
        string memory tokenUri, bytes memory data)
    public
    onlyOwner
    {
        require(amount<=limit,"Mint too more");
        checkSupplyLimit(id,amount,limit);
        _mint(account, id, amount, data);
        minionSupply+=amount;
        setURI(id,tokenUri);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts,
        uint256[] memory limits,string[] memory uris,bytes memory data)
    public
    onlyOwner
    {
        require(ids.length==limits.length&&ids.length==uris.length,"ids limits uri length max eq");
        _mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i]<=limits[i],"Mint too more");
            checkSupplyLimit(ids[i],amounts[i],limits[i]);
            minionSupply += amounts[i];
            setURI(ids[i],uris[i]);
        }
    }

    function checkSupplyLimit( uint256 id, uint256 amount,uint limit)private{
        require(maxMinionSupply>=minionSupply,"Mint too more");
        if(supplyLimit[id]==0&&totalSupply(id)==0){
            supplyLimit[id]=limit;
        }else{
            require(supplyLimit[id]>=totalSupply(id)+amount,"Mint too more");
        }
    }
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

