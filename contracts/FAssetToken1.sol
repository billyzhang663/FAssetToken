pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ownable.sol";

contract FAssetToken1 is ERC20, Ownable {
    struct CheckPoint {
        uint256 fromBlock;
        uint256 value;
    }

    struct VotePowerDelegation {
        uint256 token;
        uint8 balance;        
        address[] assigners;
        address[] owners;
    }

    // It preserves the list of VotePower CheckPoint mapping to the address.
    mapping(address => CheckPoint[]) allVotePowers;
    // It preserves the list of Balance CheckPoint mapping to the address.
    mapping(address => CheckPoint[]) allBalances;
    // It preserves the list of VotePowerDelegation mapping to the address.
    mapping(address => VotePowerDelegation) allDelegations;
    // It preserves mapping percentage mapping to the address with mapping to the address.
    mapping(address => mapping(address => uint8)) allDelegatedPercentages;
    // It preserves assigner exist bool mapping to the address.
    mapping(address => mapping(address => bool)) allAssignerExist;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    function balanceOfAt(address _user, uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        CheckPoint[] storage checkPoints = allBalances[_user];
        return getValueAt(checkPoints, _blockNumber);
    }

    function balanceFromDelegationOfAt(address _user)
        public
        view
        returns (uint256)
    {
        VotePowerDelegation storage votePowerDelegation = allDelegations[_user];        
        return votePowerDelegation.balance;
    }

    function votePowerOfAt(address _user, uint256 _blockNumber)
        public
        view
        returns (uint256)
    {
        CheckPoint[] storage checkPoints = allVotePowers[_user];
        return getValueAt(checkPoints, _blockNumber);
    }

    function getValueAt(CheckPoint[] storage _checkPoints, uint256 _blockNumber)
        internal
        view
        returns (uint256)
    {
        if (_checkPoints.length == 0) return 0;
        if (_blockNumber < _checkPoints[0].fromBlock) return 0;
        if (_blockNumber >= _checkPoints[_checkPoints.length - 1].fromBlock)
            return _checkPoints[_checkPoints.length - 1].value;
        else {
            uint256 min = 0;
            uint256 max = _checkPoints.length - 1;
            while (max > min) {
                uint256 mid = (max + min + 1) / 2;
                if (_checkPoints[mid].fromBlock <= _blockNumber) {
                    min = mid;
                } else {
                    max = mid - 1;
                }
            }
            return _checkPoints[min].value;
        }
    }

    function delegate(address _user, uint8 _percentage) public {
        VotePowerDelegation storage delegation = allDelegations[msg.sender];
        uint8 balance = delegation.balance;

        require(balance != 0, "The user has no token to delegate.");
        
        uint8 oldPercentage = allDelegatedPercentages[msg.sender][_user];
        require(_percentage > 0 && _percentage - oldPercentage <= balance, "Invalid Percentage");

        delegation.balance = balance - _percentage + oldPercentage;
        allDelegatedPercentages[msg.sender][_user] = _percentage;

        CheckPoint[] storage checkPoints = allBalances[msg.sender];
        CheckPoint storage checkPoint = checkPoints.push();
        checkPoint.fromBlock = block.number;
        checkPoint.value = getRemainingBalance(delegation);
        
        updateVotePower(msg.sender, delegation);
        
        VotePowerDelegation storage assignedVotePowerDelegation = allDelegations[_user];
        if (allAssignerExist[msg.sender][_user] == false) {
            allAssignerExist[msg.sender][_user] == true;
            delegation.assigners.push(_user);

            VotePowerDelegation storage assignerVPD = allDelegations[_user];
            assignerVPD.owners.push(msg.sender);
        }

        updateVotePower(_user, assignedVotePowerDelegation);
    }

    function getRemainingBalance(
        VotePowerDelegation storage _votePowerDelegation
    ) internal view returns (uint256) {
        return (_votePowerDelegation.token * _votePowerDelegation.balance) / 100;
    }

    function getSubVotePowerOfAt(
        address _owner,
        address _user,
        VotePowerDelegation storage _votePowerDelegation
    ) internal view returns (uint256) {
        require(allAssignerExist[_owner][_user] == false, "That user wasn't delegated yet!");
        return (_votePowerDelegation.token * allDelegatedPercentages[_owner][_user]) / 100;
    }

    function updateVotePower(
        address _user,
        VotePowerDelegation storage _votePowerDelegation
    ) internal {
        address[] memory owners = _votePowerDelegation.owners;

        uint256 remainingBalance = getRemainingBalance(_votePowerDelegation);
        uint256 delegatedVotePower = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            VotePowerDelegation storage delegation = allDelegations[owner];
            delegatedVotePower += getSubVotePowerOfAt(owner, _user, delegation);
        }

        CheckPoint storage checkPoint = allVotePowers[_user].push();
        checkPoint.fromBlock = block.number;
        checkPoint.value = remainingBalance + delegatedVotePower;
    }

    function mint(address _user, uint256 _token) external payable onlyOwner {
        _mint(_user, _token);

        VotePowerDelegation storage votePowerDelegation = allDelegations[_user];

        if (votePowerDelegation.balance == 0 && votePowerDelegation.token == 0)
            votePowerDelegation.balance = 100;
        
        uint256 newToken = votePowerDelegation.token + _token;        
        votePowerDelegation.token = newToken;

        CheckPoint[] storage checkPoints = allBalances[_user];
        CheckPoint storage checkPoint = checkPoints.push();
        checkPoint.fromBlock = block.number;
        checkPoint.value = newToken;

        updateVotePower(_user, votePowerDelegation);

        address[] memory assigners = votePowerDelegation.assigners;
        for (uint256 i = 0; i < assigners.length; i++) {
            address assigner = assigners[i];
            VotePowerDelegation storage delegation = allDelegations[assigner];
            updateVotePower(assigner, delegation);
        }
    }

    // function transfer(address _user, uint256 _token) external payable {        
    // }
}
