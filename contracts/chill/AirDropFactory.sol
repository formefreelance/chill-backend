pragma solidity ^0.6.0;

import "./AirDrop.sol";
import "../helper/Ownable.sol";

contract AirDropFactory is Ownable {
    mapping (address => address) public _airDropNirvanaAddress;
    address[] public lpPoolArray;
    
    constructor() public {

    }
    
    function createNiravanaIncentivePool(address _lpPool) public onlyOwner {
        AirDrop newAirDrop = new AirDrop(_lpPool, msg.sender);
        _airDropNirvanaAddress[_lpPool] = address(newAirDrop);
        lpPoolArray.push(_lpPool);
    }

    function getAirDropAddressByPool(address _lpPool) public view returns(address) {
        return _airDropNirvanaAddress[_lpPool];
    }

    function getLpPoolArray() public view returns(address[] memory) {
        return lpPoolArray;
    }

    function getLpPoolArrayLength() public view returns(uint256) {
        return lpPoolArray.length;
    }
}