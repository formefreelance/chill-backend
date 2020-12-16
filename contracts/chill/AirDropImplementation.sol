pragma solidity ^0.6.0;

import "../interfaces/IChillFinance.sol";
import "../interfaces/IERC20.sol";
import "../helper/SafeMath.sol";
import "../interfaces/IAirDrop.sol";

contract AirDropImplementation is IAirDrop  {
    using SafeMath for uint256;
    IERC20 public chillToken;
    IChillFinance public iChillFiinance;
    address public owner;
    address public implementation;
    uint256 public nirwanaReward;
    uint256 public timeSchedule;
    uint256 public claimSchedule;
    uint256 public timeStamp;
    uint256 public claimTimeStamp;
    uint256 public rewardAmount;
    uint256 public scheduleCount = 0;
    uint256 public NIRVANA_MULTIPLIER = 50;
    string public NIRVANA_POOL_NAME;
    mapping (uint256 => mapping(address => bool)) public isNewRewardGiven;

    modifier isOwner {
        require(owner == msg.sender, "Error: Address is not owner");
        _;
    }
    
    constructor(address _owner) public {
        NIRVANA_POOL_NAME = "IMPLEMENTATION-POOL";
        iChillFiinance = IChillFinance(0x4ad97fd79F8a2aE0e5415821BC06781bF5a164e1);
        chillToken = IERC20(0xD6689f303fA491f1fBba919C1AFa619Bd8E595e3);
        owner = _owner;
    }
    
    function startPool(uint256 _timeSchedule, uint256 _claimSchedule, uint256 _nirvanaReward) external override isOwner {
        nirwanaReward = _nirvanaReward; // Nirvana Reward Percentage
        timeSchedule = _timeSchedule; // 8 hours
        claimSchedule = _claimSchedule; // 15 hours 30 mins
        uint256 currentTimeStamp = getCurrentTimeStamp();
        timeStamp = currentTimeStamp.add(timeSchedule);
        claimTimeStamp = currentTimeStamp.add(timeSchedule).add(claimSchedule);
        uint256 chillBalance = chillToken.balanceOf(address(this));
        uint256 chillReward = chillBalance.mul(nirwanaReward).div(100);
        rewardAmount = chillReward;
    }
    
    function setNewScheduler() internal {
        if (getCurrentTimeStamp() > timeStamp) {
            uint256 currentTimeStamp = getCurrentTimeStamp();
            timeStamp = currentTimeStamp.add(timeSchedule); // increase by 8 hours
            uint256 chillBalance = chillToken.balanceOf(address(this));
            uint256 chillReward = chillBalance.mul(nirwanaReward).div(100);
            rewardAmount = chillReward;
            scheduleCount = scheduleCount.add(1);
            claimTimeStamp = currentTimeStamp.add(claimSchedule); // 7 hours 30 mins
        }
    }

    function getNirvana(uint256 _pid) public override view returns(uint256) {
        (,,uint256 startedBlock) = getUsersInfo(_pid, msg.sender);
        uint256 nirvanMultiplier;
        if(startedBlock > 0) {
            nirvanMultiplier = iChillFiinance.getNirvanaStatus(startedBlock);
        } else {
            nirvanMultiplier = 0;
        }
        return nirvanMultiplier;
    }
    
    function claimNirvanaReward(uint256 _pid) external override returns(bool) {
        require(getNirvana(_pid) == NIRVANA_MULTIPLIER, "You are not Niravana user.");
        setNewScheduler();
        require(scheduleCount > 0, "Claim window is not open");
        require(!isNewRewardGiven[scheduleCount][msg.sender] && getCurrentTimeStamp() < claimTimeStamp, "Already Reward is Claimed, Wait for Next Snapshot");
        isNewRewardGiven[scheduleCount][msg.sender] = true;
        (,,,,uint256 poolBalance,,) = getPoolInfo(_pid);
        (uint256 userBalance,,) = getUsersInfo(_pid, msg.sender);
        uint256 transferBalancePercent = userBalance.mul(1e18).div(poolBalance);
        uint256 transferBalance = transferBalancePercent.mul(rewardAmount).div(1e18);
        require(chillToken.balanceOf(address(this)) >= transferBalance.div(1e18), "Not Enough Balance in Nirvana Pool.");
        chillToken.transfer(msg.sender, transferBalance.div(1e18));
        return true;
    }
    
    function getAllUsers(uint256 _pid) external override view returns(address[] memory, uint256) {
        uint256 userLength = iChillFiinance.userPoollength(_pid);
        address[] memory nirvanaAddresses = new address[](userLength);
        address poolUser;
        uint256 count = 0;
        for (uint i = 0; i < userLength; i++) {
            poolUser = iChillFiinance.poolUsers(_pid, i);
            (,,uint256 startedBlock) = getUsersInfo(_pid, poolUser);
            uint256 nirvanMultiplier = iChillFiinance.getNirvanaStatus(startedBlock);
            if (nirvanMultiplier == NIRVANA_MULTIPLIER) {
                nirvanaAddresses[count] = poolUser;
                count = count.add(1);
            }
        }
        return (nirvanaAddresses, count);
    }
    
    function setNirvanaReward(uint256 _rewards) external override isOwner {
        nirwanaReward = _rewards;
    }
    
    function setTimeSchedule(uint256 _timeSchedule) external override isOwner {
        timeSchedule = _timeSchedule;
    }
    
    function setClaimTimeSchedule(uint256 _claimSchedule) external override isOwner {
        claimSchedule = _claimSchedule;
    }
    
    function setNirVanaMultiplier(uint256 _nirvanaMultiplier) external override isOwner {
        NIRVANA_MULTIPLIER = _nirvanaMultiplier;
    }
    
    function getUsersInfo(uint256 _pid, address _user) public override view returns (uint256, uint256, uint256) {
        return iChillFiinance.userInfo(_pid, _user);
    }
    
    function getPoolInfo(uint256 _pid) public override view returns (IERC20, uint256, uint256, uint256, uint256, address, uint256) {
        return iChillFiinance.poolInfo(_pid);
    }
    
    function setChillFinance(address _chillFinance) external override isOwner {
        iChillFiinance = IChillFinance(_chillFinance);
    }

    function setChillToken(address _chillToken) external override isOwner {
        chillToken = IERC20(_chillToken);
    }
    
    function getCurrentTimeStamp() public override view returns(uint256) {
        return block.timestamp;
    }

    function transferOwnership(address _owner) external override isOwner {
        owner = _owner;
    }
}
