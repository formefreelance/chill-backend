pragma solidity ^0.6.0;

import "../uniswap/UniswapV2Library.sol";
import "../helper/SafeMath.sol";
import "../helper/Ownable.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../helper/WETH9.sol";
import "../helper/SafeERC20.sol";

contract InstaStakeContract is Ownable {

    IUniswapV2Router02 public iUniswapV2Router02;
    IUniswapV2Factory public iUniswapV2factory;
    IUniswapV2Pair public iUniswapV2Pair;
    WETH9 public wethContract;
    address payable weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    using SafeMath for uint256;
    bool public isFastStaking = true;
    using SafeERC20 for IERC20;


    constructor(WETH9 _weth) public {
        wethContract = _weth;
        iUniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        iUniswapV2factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    }
    
    receive() external payable {
    }
    
    modifier isFastStakingEnable {
        require(isFastStaking == true);
        _;
    }

    function deposit(address _token, address[] memory _path) public payable isFastStakingEnable {
        wethContract.deposit{value : msg.value}();
        uint256[] memory amounts = iUniswapV2Router02.swapExactTokensForTokens(
            msg.value.div(2),
            0,
            _path, 
            address(this),
            block.timestamp.add(3600)
        );
        address pair = iUniswapV2factory.getPair(weth, _token);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 amountOut;
        if(IUniswapV2Pair(pair).token0() != address(weth)) {
            amountOut = UniswapV2Library.getAmountOut(amounts[1], reserve0, reserve1);
        } else {
            amountOut = UniswapV2Library.getAmountOut(amounts[1], reserve1, reserve0);
        }
        
        iUniswapV2Router02.addLiquidity(weth, _token, amountOut, amounts[1], 0, 0, msg.sender, block.timestamp.add(3600));
    }
    
    function approveUnlimited(address _token) public onlyOwner {
        IERC20(_token).safeApprove(address(iUniswapV2Router02), uint(-1));
    }
    
    function approveLimited(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeApprove(address(iUniswapV2Router02), _amount);
    }
    
    function setFastStakingEnable(bool _isFastStaking) public onlyOwner {
        isFastStaking = _isFastStaking;
    }
    
    function getExtras(address _token) public onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    
    function getExtrasEth() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
}