pragma solidity ^0.6.0;

import "../interfaces/IChillFinance.sol";
import "../helper/Ownable.sol";

contract Airdrop is Ownable {
    IChillFinance public iChillFiinance;
    address[] public users;
    
    constructor() public {
        iChillFiinance = IChillFinance(0xFf20bbEAF2E1d7239436Da6fCE98278e85079500);
    }
    
    function getAllUsers(uint256 _pid) public view  returns(address[] memory, uint256) {
        uint256 userLength = iChillFiinance.userPoollength(_pid);
        address[] memory nirvanaAddresses = new address[](userLength);
        address poolUser;
        for(uint i=0; i < userLength; i++) {
            poolUser = iChillFiinance.poolUsers(_pid, i);
            (,,uint256 startedBlock) = getAllUsersInfo(_pid, poolUser);
            uint256 nirvanMultiplier = iChillFiinance.getNirvanaStatus(startedBlock);
            if(nirvanMultiplier == 50) {
                nirvanaAddresses[i] = poolUser;
            }
        }
        return (nirvanaAddresses, nirvanaAddresses.length);
    }
    
    function getAllUsersInfo(uint256 _pid, address _user) public view returns (uint256, uint256, uint256) {
        return iChillFiinance.userInfo(_pid, _user);
    }
    
    function setChillFinance(address _chillFinance) public onlyOwner {
        iChillFiinance = IChillFinance(_chillFinance);
    }
}