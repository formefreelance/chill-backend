pragma solidity ^0.6.0;

import "../interfaces/IChillFinance.sol";
import "../interfaces/IERC20.sol";
import "../helper/SafeMath.sol";

contract AirDrop {
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
        NIRVANA_POOL_NAME = "DAI-ETH";
        iChillFiinance = IChillFinance(0x4ad97fd79F8a2aE0e5415821BC06781bF5a164e1);
        chillToken = IERC20(0xD6689f303fA491f1fBba919C1AFa619Bd8E595e3);
        owner = _owner;
        nirwanaReward = 50; // Nirvana Reward Percentage
        timeSchedule = 28800; // 8 hours
        claimSchedule = 27000; // 15 hours 30 mins
        uint256 currentTimeStamp = block.timestamp;
        timeStamp = currentTimeStamp;
        claimTimeStamp = currentTimeStamp.add(timeSchedule).add(claimSchedule);
    }
    
    // Contract Implementation Methods (Logic Contracts)
    function addImplementation(address _implementation) public isOwner {
        implementation = _implementation;
    }
    
    // Upgradable Delegated Call Methods 
    function startPool(uint256 _timeSchedule, uint256 _claimSchedule, uint256 _nirvanaReward) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("startPool(uint256,uint256,uint256)", _timeSchedule, _claimSchedule, _nirvanaReward));   
        require(success, "startPool(uint256 _timeSchedule, uint256 _claimSchedule, uint256 _nirvanaReward) delegatecall failed.");
    }
    
    function claimNirvanaReward(uint256 _pid) public returns(bool) {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("claimNirvanaReward(uint256)", _pid));
        require(success, "claimNirvanaReward(uint256 _pid) delegatecall failed.");
        return success;
    }
    
    function setNirvanaReward(uint256 _rewards) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("setNirvanaReward(uint256)", _rewards));
        require(success, "setNirvanaReward(uint256 _rewards) delegatecall failed.");
    }
    
    function setTimeSchedule(uint256 _timeSchedule) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("setTimeSchedule(uint256)", _timeSchedule));
        require(success, "setTimeSchedule(uint256 _timeSchedule) delegatecall failed.");
    }
    
    function setClaimTimeSchedule(uint256 _claimSchedule) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("setClaimTimeSchedule(uint256)", _claimSchedule));
        require(success, "setClaimTimeSchedule(uint256 _claimSchedule) delegatecall failed.");
    }
    
    function setNirVanaMultiplier(uint256 _nirvanaMultiplier) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("setNirVanaMultiplier(uint256)", _nirvanaMultiplier));
        require(success, "setNirVanaMultiplier(uint256 _nirvanaMultiplier) delegatecall failed.");
    }
    
    function setChillFinance(address _chillFinance) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("setChillFinance(address)", _chillFinance));
        require(success, "setChillFinance(address _chillFinance) delegatecall failed.");
    }

    function setChillToken(address _chillToken) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("setChillToken(address)", _chillToken));
        require(success, "setChillToken(address _chillToken) delegatecall failed.");
    }

    function transferOwnership(address _owner) public isOwner {
        (bool success,) = implementation.delegatecall(abi.encodeWithSignature("transferOwnership(address)", _owner));
        require(success, "transferOwnership(address _owner) delegatecall failed.");
    }
    
    // Upgradable Static Call Methods 
    function getNirvana(uint256 _pid) public view returns(uint256) {
        (bool success, bytes memory result) = implementation.staticcall(abi.encodeWithSignature("getNirvana(uint256)", _pid));
        require(success, "getNirvana(uint256 _pid) staticcall failed.");
        return abi.decode(result, (uint256));
    }
    
    function getAllUsers(uint256 _pid) public view returns(address[] memory, uint256) {
        (bool success, bytes memory result) = implementation.staticcall(abi.encodeWithSignature("getAllUsers(uint256)", _pid));
        require(success, "getAllUsers(uint256 _pid) staticcall failed.");
        return abi.decode(result, (address[], uint256));
    }
    
    function getUsersInfo(uint256 _pid, address _user) public view returns (uint256, uint256, uint256) {
        (bool success, bytes memory result) = implementation.staticcall(abi.encodeWithSignature("getUsersInfo(uint256,address)", _pid, _user));
        require(success, "getUsersInfo(uint256 _pid, address _user) staticcall failed.");
        return abi.decode(result, (uint256, uint256, uint256));
    }
    
    function getPoolInfo(uint256 _pid) public view returns (IERC20, uint256, uint256, uint256, uint256, address, uint256) {
        (bool success, bytes memory result) = implementation.staticcall(abi.encodeWithSignature("getPoolInfo(uint256)", _pid));
        require(success, "getPoolInfo(uint256 _pid) staticcall failed.");
        return abi.decode(result, (IERC20, uint256, uint256, uint256, uint256, address, uint256));
    }
    
    function getCurrentTimeStamp() public view returns(uint256) {
        (bool success, bytes memory result) = implementation.staticcall(abi.encodeWithSignature("getCurrentTimeStamp()"));
        require(success, "getCurrentTimeStamp() staticcall failed.");
        return abi.decode(result, (uint256));
    }
}
