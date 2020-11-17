pragma solidity >=0.5.0;

import "../helper/SafeERC20.sol";
import "../helper/SafeMath.sol";
import "../uniswap/UniswapV2Library.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniStakingRewards.sol";

library PairValue {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    function countEthAmount(address _countPair, uint256 _liquiditybalance) internal view returns(uint256) {
        address countToken0 = IUniswapV2Pair(_countPair).token0();
        (uint112 countReserves0, uint112 countReserves1, ) = IUniswapV2Pair(_countPair).getReserves();
        uint256 countTotalSupply = IERC20(_countPair).totalSupply();
        uint256 ethAmount;
        uint256 tokenbalance;

        if(countTotalSupply > 0) {
            if(countToken0 != 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
                tokenbalance = _liquiditybalance.mul(countReserves0).div(countTotalSupply);
                ethAmount = UniswapV2Library.getAmountOut(tokenbalance, countReserves0, countReserves1);
            } else {
                tokenbalance = _liquiditybalance.mul(countReserves1).div(countTotalSupply);
                ethAmount = UniswapV2Library.getAmountOut(tokenbalance, countReserves1, countReserves0);
            }
        } else {
            return 0;
        }
        return countUsdtAmount(ethAmount);
    }

    function countUsdtAmount(uint256 ethAmount) internal view returns(uint256) {
        address _stablePair = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852;
        address usdttoken0 = IUniswapV2Pair(_stablePair).token0();
        (uint112 stableReserves0, uint112 stableReserves1, ) = IUniswapV2Pair(_stablePair).getReserves();

        uint256 stableOutAmount;
        if (usdttoken0 == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) { // WETH Mainnet
            stableOutAmount = UniswapV2Library.getAmountOut(1e18, stableReserves0, stableReserves1);
        } else {
            stableOutAmount = UniswapV2Library.getAmountOut(1e18, stableReserves1, stableReserves0);
        }
        uint256 totalAmount = ((ethAmount.div(1e18)).mul(stableOutAmount.div(1e6))).mul(2);
        return totalAmount;
    }
}
