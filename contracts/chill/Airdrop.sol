pragma solidity ^0.6.0;

import "../interfaces/IChillFinance.sol";
import "../interfaces/IERC20.sol";
import "../helper/SafeMath.sol";

contract AirDrop {
    using SafeMath for uint256;
    IERC20 chillToken;
    IChillFinance public iChillFiinance;
    uint256 nirwanaReward;
    address public lpTokenAddress;
    address[] public users;
    uint256 timeStamp;
    uint256 timeSchedule;
    address public owner;
    // address[] public nirvanaAddresses;
    
    constructor(address _lpToken, address _owner) public {
        iChillFiinance = IChillFinance(0xa15E697806711003E635bEe08CA049130C4917fd);
        chillToken = IERC20(0xC059Ab991c99D2c08A511F8e04EE5EA85a2e97bf);
        nirwanaReward = 1;
        timeSchedule = 28800;
        lpTokenAddress = _lpToken;
        owner = _owner;
        timeStamp = block.timestamp.add(timeSchedule);
    }

    modifier isSchedule(uint256 _timeStamp) {
        require(block.timestamp > timeStamp);
        _;
    }
    
    modifier isOwner {
        require(owner == msg.sender, "Error: Address is not owner");
        _;
    }
    
    function getAllUsers(uint256 _pid) public view returns(address[] memory, uint256) {
        uint256 userLength = iChillFiinance.userPoollength(_pid);
        address[] memory nirvanaAddresses = new address[](userLength);
        address poolUser;
        uint256 count = 0;
        for(uint i=0; i < userLength; i++) {
            poolUser = iChillFiinance.poolUsers(_pid, i);
            (,,uint256 startedBlock) = getAllUsersInfo(_pid, poolUser);
            uint256 nirvanMultiplier = iChillFiinance.getNirvanaStatus(startedBlock);
            if(nirvanMultiplier == 50) {
                nirvanaAddresses[count] = poolUser;
                count = count.add(1);
            }
        }
        return (nirvanaAddresses, count);
    }

    function sendNirvanaRewards(uint256 _pid) isSchedule(block.timestamp) public returns(bool) {
        timeStamp = block.timestamp.add(timeSchedule);
        uint256 chillBalance = chillToken.balanceOf(address(this));
        uint256 chillReward = chillBalance.mul(nirwanaReward).div(100);
        (address[] memory nirvanaAddress, uint256 userLength) = getAllUsers(_pid);
        for(uint i=0; i < userLength; i++) {
            if(nirvanaAddress[i] != address(0)) {
                chillToken.transfer(nirvanaAddress[i], chillReward.div(userLength));
            } else {
                break;
            }
        }
        return true;
    }
    
    function setNirvanaReward(uint256 _rewards) public isOwner {
        nirwanaReward = _rewards;
    }

    function setTimeSchedule(uint256 _timeSchedule) public isOwner {
        timeSchedule = _timeSchedule;
    }

    function getAllUsersInfo(uint256 _pid, address _user) public view returns (uint256, uint256, uint256) {
        return iChillFiinance.userInfo(_pid, _user);
    }
    
    function setChillFinance(address _chillFinance) public isOwner {
        iChillFiinance = IChillFinance(_chillFinance);
    }
}