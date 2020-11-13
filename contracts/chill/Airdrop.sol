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
    uint256 claimTimeStamp;
    uint256 timeSchedule;
    uint256 claimSchedule;
    address public owner;
    uint256 public percentage;
    uint256 public scheduleCount = 0;
    mapping (uint256 => mapping(address => bool)) public isNewRewardGiven;
    
    constructor(address _lpToken, address _owner) public {
        iChillFiinance = IChillFinance(0xa15E697806711003E635bEe08CA049130C4917fd);
        chillToken = IERC20(0xC059Ab991c99D2c08A511F8e04EE5EA85a2e97bf);
        nirwanaReward = 1;
        timeSchedule = 28800;
        claimSchedule = 55800;
        lpTokenAddress = _lpToken;
        owner = _owner;
        timeStamp = block.timestamp.add(timeSchedule);
        claimTimeStamp = block.timestamp.add(claimSchedule);
    }

    modifier isSchedule {
        require(block.timestamp > timeStamp);
        _;
    }
    
    modifier isClaimSchedule {
        require(block.timestamp < claimTimeStamp);
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
            (,,uint256 startedBlock) = getUsersInfo(_pid, poolUser);
            uint256 nirvanMultiplier = iChillFiinance.getNirvanaStatus(startedBlock);
            if(nirvanMultiplier == 50) {
                nirvanaAddresses[count] = poolUser;
                count = count.add(1);
            }
        }
        return (nirvanaAddresses, count);
    }
    
    function setNewScheduler() public {
        if (block.timestamp > timeStamp) {
            timeStamp = block.timestamp.add(timeSchedule);
            uint256 chillBalance = chillToken.balanceOf(address(this));
            uint256 chillReward = chillBalance.mul(nirwanaReward).div(100);
            percentage = chillReward;
            scheduleCount = scheduleCount.add(1);
        }
    }

    function claimNirvanaReward(uint256 _pid) public returns(bool) {
        (,,uint256 startedBlock) = getUsersInfo(_pid, msg.sender);
        uint256 nirvanMultiplier = iChillFiinance.getNirvanaStatus(startedBlock);
        require(nirvanMultiplier == 50, "You are not Niravana user.");
        setNewScheduler();
        require(scheduleCount > 0, "Claim window is not open");
        require(!isNewRewardGiven[scheduleCount][msg.sender], "Already Reward is Claimed, Wait for Next Snapshot");
        isNewRewardGiven[scheduleCount][msg.sender] = true;
        (,,,,uint256 poolBalance,,) = getPoolInfo(_pid);
        (uint256 userBalance,,) = getUsersInfo(_pid, msg.sender);
        uint256 transferBalancePercent = userBalance.div(poolBalance).mul(100);
        uint256 transferBalance = transferBalancePercent.mul(percentage).div(100);
        chillToken.transfer(msg.sender, transferBalance);
        return true;
    }
    
    function setNirvanaReward(uint256 _rewards) public isOwner {
        nirwanaReward = _rewards;
    }

    function setTimeSchedule(uint256 _timeSchedule) public isOwner {
        timeSchedule = _timeSchedule;
    }

    function getUsersInfo(uint256 _pid, address _user) public view returns (uint256, uint256, uint256) {
        return iChillFiinance.userInfo(_pid, _user);
    }
    
    function getPoolInfo(uint256 _pid) public view returns (IERC20, uint256, uint256, uint256, uint256, address, uint256) {
        return iChillFiinance.poolInfo(_pid);
    }
    
    function setChillFinance(address _chillFinance) public isOwner {
        iChillFiinance = IChillFinance(_chillFinance);
    }
}