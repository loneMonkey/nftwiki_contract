// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface  Minion{
    function minionSupply() external view returns (uint);
}

contract nftk_erc20_eth is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable,AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CONSENSUS_MINT_ROLE = keccak256("CONSENSUS_MINT_ROLE");
    bool public isPreMint=false;
    uint public initBlock;
    address public minionAddress;

    uint public maxSupply=1890000000*10 ** decimals();

    uint public minionCount;
    uint maxMinionCount=2000000;
    uint public currConsensusMint=1*10**decimals()/6250;

    //2300000
    uint constant _difficultyBomb=2300000;

    uint constant _consensusMintInterval=100;

    uint public lastConsensusMintBlock;

    uint public maxBatchMint=126000000*10 ** decimals();
    uint public batchMinted=0;

    struct Consensus{
        address to;
        uint256 amount;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address daoAddr,address teamAddr,address consensusAddr,address batchMintAddr) initializer {
        __ERC20_init("NFTWiki Token", "NFTK");
        __ERC20Burnable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, batchMintAddr);
        _grantRole(CONSENSUS_MINT_ROLE, consensusAddr);

        initBlock=block.number;
        lastConsensusMintBlock=block.number;

        preMint(daoAddr,294000000 * 10 ** decimals());
        preMint(teamAddr,210000000 * 10 ** decimals());
        isPreMint=true;
    }
    function preMint(address to,uint amount)  private {
        require(!isPreMint,"Pre Mint has been executed");
        _mint(to, amount);
    }

    function setMinionAddress(address addr) public onlyRole(CONSENSUS_MINT_ROLE){
        require(minionAddress==address (0),"Address must be zero");
        require(Address.isContract(addr),"Address must be contract");
        minionAddress=addr;
    }
    function syncMinionCount()public onlyRole(CONSENSUS_MINT_ROLE){
        if(minionAddress!=address(0)){
            minionCount= Minion(minionAddress).minionSupply();
            if(minionCount>maxMinionCount){
                minionCount=maxMinionCount;
            }
        }
    }

    /// consensus Mint,
    function consensusMint(address to)public onlyRole(CONSENSUS_MINT_ROLE){
        require(lastConsensusMintBlock+_consensusMintInterval<block.number,"consensus Mint too fast");
        mint(to,getMintableAmt());
        lastConsensusMintBlock= block.number;
        bool step=(lastConsensusMintBlock-initBlock)>=_difficultyBomb;
        if(step){
            currConsensusMint=currConsensusMint*4/5;
            initBlock=block.number;
        }
    }

    function getMintableAmt()public view returns(uint amount){
        return (block.number-lastConsensusMintBlock)*minionCount*currConsensusMint;
    }

    function mint(address to, uint256 amount) private  {
        require(totalSupply()+amount<=maxSupply,"Too many coins");
        _mint(to, amount);
    }
    function batchMint(Consensus[] memory cs) public  onlyRole(MINTER_ROLE){

        require(batchMinted<=maxBatchMint,"minted too more");
        for(uint i =0;i<cs.length;i++){
            batchMinted=batchMinted+cs[i].amount;
            if(batchMinted<=maxBatchMint){
                _mint(cs[i].to,cs[i].amount);
            }
        }
    }

    function batchTransfer(address from,Consensus[] memory cs) public{
        for(uint i =0;i<cs.length;i++){
            transferFrom(from,cs[i].to,cs[i].amount);
        }
    }
}

