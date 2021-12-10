// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTK_ERC20 is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable,AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    bytes32 public constant CONSENSUS_MINT_ROLE = keccak256("CONSENSUS_MINT_ROLE");
    bool public isPreMint=false;

    struct Consensus{
        address to;
        uint256 amount;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {
        __ERC20_init("NFTWiKi Token", "NFTK");
        __ERC20Burnable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(CONSENSUS_MINT_ROLE, msg.sender);
    }

    function preMint(address to)  public onlyRole(DEFAULT_ADMIN_ROLE){
        require(!isPreMint,"Pre Mint has been executed");
        _mint(to, 100000000 * 10 ** decimals());
        isPreMint=true;
    }

    function batchTransfer(address from,Consensus[] memory cs) public{
        for(uint i =0;i<cs.length;i++){
            transferFrom(from,cs[i].to,cs[i].amount);
        }
    }
}

