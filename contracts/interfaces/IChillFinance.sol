pragma solidity ^0.6.0;

import "./IERC20.sol";

interface IChillFinance {
    function poolUsers(uint256 _pid, uint256 _index) external view returns(address);
    function getPoolUsers(uint256 _pid) external view returns(address[] memory);
    function getPoolUsersLength(uint256 _pid) external view returns(uint256);
    function userPoollength(uint256 _pid) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns(uint256, uint256, uint256);
    function poolInfo(uint256 _pid) external view returns(IERC20, uint256, uint256, uint256, uint256, address, uint256);
    function getNirvanaStatus(uint256 _from) external view returns (uint256);
}