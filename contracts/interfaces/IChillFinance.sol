pragma solidity ^0.6.0;

interface IChillFinance {
    function poolUsers(uint256 _pid, uint256 _index) external view returns(address);
    function userPoollength(uint256 _pid) external view returns (uint256);
    function userInfo(uint256 _pid, address _user) external view returns(uint256, uint256, uint256);
    function getNirvanaStatus(uint256 _from) external view returns (uint256);
}