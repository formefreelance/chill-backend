# Chill-Finance Smart Contracts

Steps to run smart contracts:

```
1). git clone https://github.com/sunnyRK/yield-backend.git
2). cd yield-backend
3). yarn 
3). truffle compile
3). truffle test
```

Deploy:

        truffle deploy --reset --network kovan

Steps to follow for deploy on mainnet: 

1). Fisrt deploy chilltoken  
2). Second deploy chillfinance contracts  
3). Third transfer ownership of chill token to chill finance  

4-i). Forth add Uni pool using `add function`  
4-ii). if your contract want to stake your lp into uniswap to generate more reward usinh uni token then add pair in uniswap using `addStakeUniPool`

5-i). Deposit and Withdraw for stake and unstake lp token.
5-ii). Each time deposit and withdraw calls update pool function will be call and also simultanoously extra reward or deduct tax function also called.

