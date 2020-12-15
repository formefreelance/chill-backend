pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IAirDrop {
    //DelegatedCall
    function startPool(uint256 _timeSchedule, uint256 _claimSchedule, uint256 _nirvanaReward) external;
    function claimNirvanaReward(uint256 _pid) external returns(bool);
    function setNirvanaReward(uint256 _rewards) external;
    function setTimeSchedule(uint256 _timeSchedule) external;
    function setClaimTimeSchedule(uint256 _claimSchedule) external;
    function setNirVanaMultiplier(uint256 _nirvanaMultiplier) external;
    function setChillFinance(address _chillFinance) external;
    function setChillToken(address _chillToken) external;
    function transferOwnership(address _owner) external;
    
    // StaticCall
    function getNirvana(uint256 _pid) external view returns(uint256);
    function getAllUsers(uint256 _pid) external view returns(address[] memory, uint256);
    function getUsersInfo(uint256 _pid, address _user) external view returns (uint256, uint256, uint256);
    function getPoolInfo(uint256 _pid) external view returns (IERC20, uint256, uint256, uint256, uint256, address, uint256);
    function getCurrentTimeStamp() external view returns(uint256);
}