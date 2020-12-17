pragma solidity ^0.6.0;

import './ChillFinance.sol';
import "../uniswap/UniswapV2Router02.sol";
import "../uniswap/UniswapV2Library.sol";
import "../interfaces/IERC20.sol";
import "../helper/SafeMath.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWETH.sol";
import "../helper/WETH9.sol";
// 0x224AB8bC86788EE3EE91B5512D0Afd349a2b59aA
// "0xC059Ab991c99D2c08A511F8e04EE5EA85a2e97bf","0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",["0xd0A1E359811322d97991E03f863a0C30C2cF029C","0xC059Ab991c99D2c08A511F8e04EE5EA85a2e97bf"]
contract InstaStake {

    IUniswapV2Router02 public iUniswapV2Router02;
    IUniswapV2Factory public iUniswapV2factory;
    IUniswapV2Pair public iUniswapV2Pair;
    WETH9 public wethContract;
    address payable weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address public chillFinance = 0xa15E697806711003E635bEe08CA049130C4917fd;
    using SafeMath for uint256;
    uint256[] public amounts;
    uint256[] public count;
    uint256 public amountOut;


    constructor(WETH9 _weth) public payable {
        wethContract = _weth;
        iUniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        iUniswapV2factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        wethContract.deposit{value : msg.value}();
    }
    
    fallback() external payable {
        // wethContract.deposit{value : msg.value}();
    }

    function deposit(uint256 _pid, address _token, address[] memory _path, uint256 flag1, uint256 flag2) public payable
        // returns(bool)    
    {
        uint256 wethBal = IERC20(weth).balanceOf(address(this));
        uint256 chillBal = IERC20(_token).balanceOf(address(this));

        wethContract.deposit{value : msg.value}();
        IERC20(weth).approve(address(iUniswapV2Router02), 1000e18);
        amounts = iUniswapV2Router02.swapExactTokensForTokens(
            msg.value.div(2), 
            0,
            _path, 
            address(this),
            block.timestamp.add(1000)
        );
        address pair = iUniswapV2factory.getPair(weth, _token);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        // // // return (reserve0, reserve1, IUniswapV2Pair(pair).token0());
        if(IUniswapV2Pair(pair).token0() != address(weth)) {
            count.push(11);
            amountOut = UniswapV2Library.getAmountOut(amounts[1], reserve0, reserve1);
        } else {
            count.push(12);
            amountOut = UniswapV2Library.getAmountOut(amounts[1], reserve1, reserve0);
        }
        
        IERC20(weth).approve(address(iUniswapV2Router02), uint(-1));
        IERC20(_token).approve(address(iUniswapV2Router02), uint(-1));
        iUniswapV2Router02.addLiquidity(weth, _token, amountOut, amounts[1], 0, 0, msg.sender, block.timestamp.add(1000));
        
        uint256 restWethBal = IERC20(weth).balanceOf(address(this));
        uint256 restChillBal = IERC20(weth).balanceOf(address(this));

        if(restWethBal > wethBal && flag1 == 0) {
            IERC20(weth).transfer(msg.sender, restWethBal.sub(wethBal));
            count.push(13);
        }
        
        if(restChillBal > chillBal && flag2 == 0) {
            IERC20(_token).transfer(msg.sender, restChillBal.sub(chillBal));
            count.push(14);
        }
        
        // (bool success,) = chillFinance.delegatecall(abi.encodeWithSignature("deposit(uint256,uint256)", _pid, _amount));
        // require(success, "deposit(uint256 _pid, uint256 _amount) delegatecall failed.");
        // return success;
    }

    function addLiquidity(address _token, address routerAddress, address[] memory _path) public payable
        // view returns(uint256, uint256, address)
    {
        wethContract.deposit{value : msg.value}();
        IERC20(weth).approve(routerAddress, msg.value);
        IERC20(_token).approve(routerAddress, 10000e18);
        iUniswapV2Router02.addLiquidity(weth, _token, msg.value, 100e18, 0, 0, msg.sender, block.timestamp.add(1000));
    }
}