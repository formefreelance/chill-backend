pragma solidity 0.6.12;


import "./ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) public ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
    }

    function withdraw(uint wad) public {
        require(_balances[msg.sender] >= wad);
        _balances[msg.sender] -= wad;
        msg.sender.transfer(wad);
    }
}