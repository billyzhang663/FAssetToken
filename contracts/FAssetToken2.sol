pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FAssetToken is ERC20 {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    struct VotePower {
        address ownerAddress;
        uint256 token;
        uint8 balance;
        uint8 delegatedPercentage;
    }

    mapping(address => VotePower[]) allVotePowers;
}