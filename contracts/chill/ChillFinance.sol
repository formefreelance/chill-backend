pragma solidity ^0.6.0;

import "../helper/SafeERC20.sol";
import "../helper/SafeMath.sol";
import "../helper/Ownable.sol";
import "./ChillToken.sol";
import "../uniswap/UniswapV2Library.sol";
import "./PairValue.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniStakingRewards.sol";

interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}

// eth-dai 0xBbB8eeA618861940FaDEf3071e79458d4c2B42e3
contract ChillFinance is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 startedBlock;
    }
    
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accChillPerShare;
        uint256 totalPoolBalance;
        address nirvanaRewardAddress;
        uint256 nirvanaFee;
    }

    ChillToken public chill;
    address public devaddr;
    uint256 public DEV_FEE = 0;
    uint256 public DEV_TAX_FEE = 20;
    PoolInfo[] public poolInfo;
    uint256 public bonusEndBlock;
    uint256 public constant BONUS_MULTIPLIER = 10;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlockOfChill;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (uint256 => address[]) public poolUsers;
    mapping (uint256 => mapping(address => bool)) public isUserExist;
    mapping (address => bool) public stakingUniPools;
    mapping (address => address) public uniRewardAddresses;
    mapping (uint256 => bool) public isCheckInitialPeriod;
    mapping (address => bool) private distributors;
    IMigratorChef public migrator;

    uint256 initialPeriod;
    uint256[] public blockPerPhase;
    uint256[] public blockMilestone;

    uint256 public phase1time;
    uint256 public phase2time;
    uint256 public phase3time;
    uint256 public phase4time;
    uint256 public phase5time;

    uint256 burnFlag = 0;
    uint256 lastBurnedPhase1 = 0;
    uint256 lastBurnedPhase2 = 0;
    uint256 lastTimeOfBurn;
    uint256 totalBurnedAmount;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    modifier isDistributor(address _isDistributor) {
        require(distributors[_isDistributor]);
        _;
    }

    constructor(
        ChillToken _chill,
        address _devaddr
    ) public {
        chill = _chill;
        devaddr = _devaddr;
        
        startBlockOfChill = block.number;
        bonusEndBlock = block.number;
        initialPeriod = block.number.add(28800); // 5 days (5*24*60*60)/15
        
        blockPerPhase.push(75e18);
        blockPerPhase.push(100e18);
        blockPerPhase.push(50e18);
        blockPerPhase.push(25e18);
        blockPerPhase.push(0);

        blockMilestone.push(1920);
        blockMilestone.push(3840);
        blockMilestone.push(5760);
        blockMilestone.push(7680);
        blockMilestone.push(9600);

        phase1time = block.number.add(80640); // 14 days (14*24*60*60)/15
        phase2time = block.number.add(253440); // 44 - 14 = 30 days (44*24*60*60)/15 
        phase3time = block.number.add(426240); // 74 - 44 = 30 days (74*24*60*60)/15
        phase4time = block.number.add(771840); // 134 - 74 = 60 days (134*24*60*60)/15
        phase5time = block.number.add(0); // 134 - 74 = 60 days (134*24*60*60)/15
        lastTimeOfBurn = block.timestamp.add(1 days);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    function userPoollength(uint256 _pid) external view returns (uint256) {
        return poolUsers[_pid].length;
    }

    // get a participant users in a specific pool
    function getPoolUsers(uint256 _pid) public view returns(address[] memory) {
        return poolUsers[_pid];
    }

    // Add Function to give support new uniswap lp pool by only owner
    // for allocpoint will be 100 and if you want to generate more chill for specific pool then you need to increase allocpoint
    // like for, 1x=>100, 2x=>200, 3x=>300 etc.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _lastRewardBlock = block.number > startBlockOfChill ? block.number : startBlockOfChill;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: _lastRewardBlock,
            accChillPerShare: 0,
            totalPoolBalance: 0,
            nirvanaRewardAddress: address(0),
            nirvanaFee: 0
        }));
    }
    
    // increase alloc point for specific pool
    function set(uint256 _pid, uint256 _allocPoint, uint256 _nirvanaFee, address _nirvanaRewardAddress, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].nirvanaRewardAddress = _nirvanaRewardAddress;
        poolInfo[_pid].nirvanaFee = _nirvanaFee;
    }
    
    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }
    
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    // user can deposit lp for specific pool
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (isCheckInitialPeriod[_pid]) {
            if (block.number <= initialPeriod) {
                // calculate id lp token amount less than $20000 and only applicable to eth pair
                require(PairValue.countEthAmount(address(pool.lpToken), _amount) <= 20000, "Amount must be less than or equal to 20000 dollars.");
            } else {
                isCheckInitialPeriod[_pid] = false;
            }
        }
        
        if (user.startedBlock <= 0) {
            user.startedBlock = block.number;
        }
        
        updatePool(_pid);
        if (user.amount > 0) {
            userRewardAndTaxes(pool, user);
        }

        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        pool.totalPoolBalance = pool.totalPoolBalance.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accChillPerShare).div(1e12);
        user.startedBlock = block.number;

        if (stakingUniPools[address(pool.lpToken)] && _amount > 0) {
            stakeInUni(_amount, address(pool.lpToken), uniRewardAddresses[address(pool.lpToken)]);
        }

        if (!isUserExist[_pid][msg.sender]) {
            isUserExist[_pid][msg.sender] = true;
            poolUsers[_pid].push(msg.sender);
        }
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    // it will be call if spicific pool uniswap uni pool supported in chill finance
    // and if you want to support uniswap pool then you need to add in addStakeUniPool
    function stakeInUni(uint256 amount, address v2address, address _stakeAddress) private {
        IERC20(v2address).approve(address(_stakeAddress), amount);
        IUniStakingRewards(_stakeAddress).stake(amount);
    }

    // user can withdraw their lp token from specific pool 
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw is not valid");
        
        if (user.startedBlock <= 0) {
            user.startedBlock = block.number;
        }
        
        if (stakingUniPools[address(pool.lpToken)]  && _amount > 0) {
            withdrawUni(uniRewardAddresses[address(pool.lpToken)], _amount);
        }

        updatePool(_pid);
        userRewardAndTaxes(pool, user);

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accChillPerShare).div(1e12);
        user.startedBlock = block.number;
        pool.totalPoolBalance = pool.totalPoolBalance.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // withdraw lp token from uniswap uni farm pool  
    function withdrawUni(address _stakeAddress, uint256 _amount) private {
        IUniStakingRewards(_stakeAddress).withdraw(_amount);
    }
    
    // Reward will genrate in update pool function and call will be happen internally by deposit and withdraw function
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalPoolBalance == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 chillReward;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if (block.number <= phase1time) {
            chillReward = multiplier.mul(blockPerPhase[0]).mul(pool.allocPoint).div(totalAllocPoint);
        } else if (block.number <= phase2time) {
            chillReward = multiplier.mul(blockPerPhase[1]).mul(pool.allocPoint).div(totalAllocPoint);
        } else if (block.number <= phase3time) {
            chillReward = multiplier.mul(blockPerPhase[2]).mul(pool.allocPoint).div(totalAllocPoint);
        } else if (block.number <= phase4time) {
            chillReward = multiplier.mul(blockPerPhase[3]).mul(pool.allocPoint).div(totalAllocPoint);
        } else {
            chillReward = multiplier.mul(blockPerPhase[4]).mul(pool.allocPoint).div(totalAllocPoint);
        }
        
        if (chillReward > 0) {
            if (DEV_FEE > 0) {
                chill.mint(devaddr, chillReward.mul(DEV_FEE).div(100));
            }
            chill.mint(address(this), chillReward);
        }
        pool.accChillPerShare = pool.accChillPerShare.add(chillReward.mul(1e12).div(pool.totalPoolBalance));
        pool.lastRewardBlock = block.number;
    }
    
    // User's extra reward and taxes will be handle in this internal funation
    function userRewardAndTaxes(PoolInfo storage pool, UserInfo storage user) internal {
        uint256 pending =  user.amount.mul(pool.accChillPerShare).div(1e12).sub(user.rewardDebt);
        uint256 tax = deductTaxByBlock(getCrossMultiplier(user.startedBlock, block.number));
        if (tax > 0) {
            uint256 pendingTax = pending.mul(tax).div(100);
            uint256 devReward = pendingTax.mul(DEV_TAX_FEE).div(100);
            safeChillTransfer(devaddr, devReward);
            if (pool.nirvanaFee > 0) {
                uint256 nirvanaReward = pendingTax.mul(pool.nirvanaFee).div(100);
                safeChillTransfer(pool.nirvanaRewardAddress, nirvanaReward);
                safeChillTransfer(msg.sender, pending.sub(devReward).sub(nirvanaReward));
                chill.burn(msg.sender, pendingTax.sub(devReward).sub(nirvanaReward));
                lastDayBurned(pendingTax.sub(devReward).sub(nirvanaReward));
            } else {
                safeChillTransfer(msg.sender, pending.sub(devReward));
                chill.burn(msg.sender, pendingTax.sub(devReward));
                lastDayBurned(pendingTax.sub(devReward));
            }
        } else {
            safeChillTransfer(msg.sender, pending);
            lastDayBurned(0);
        }
    }
    
    function lastDayBurned(uint256 burnedAmount) internal {
        if (block.timestamp >= lastTimeOfBurn) {
            if (burnFlag == 0) {
                burnFlag = 1;
                lastBurnedPhase1 = 0;
            } else {
                burnFlag = 0;
                lastBurnedPhase2 = 0;
            }
            lastTimeOfBurn = block.timestamp.add(1 days);
        }
        totalBurnedAmount = totalBurnedAmount.add(burnedAmount);
        if (burnFlag == 0) {
            lastBurnedPhase2 = lastBurnedPhase2.add(burnedAmount);
            // return lastBurnedPhase1;
        } else {
            lastBurnedPhase1 = lastBurnedPhase1.add(burnedAmount);
            // return lastBurnedPhase2;
        }
    }
    
    function getBurnedDetails() public view returns (uint256, uint256, uint256, uint256) {
        return (burnFlag, lastBurnedPhase1, lastBurnedPhase2, totalBurnedAmount);
    }

    // For user interface to claimable token
    function pendingChill(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pending;
        uint256 accChillPerShare = pool.accChillPerShare;
        uint256 lpSupply = pool.totalPoolBalance;
        if (lpSupply != 0) {
            uint256 chillReward;
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            if (block.number <= phase1time) {
                chillReward = multiplier.mul(blockPerPhase[0]).mul(pool.allocPoint).div(totalAllocPoint);
            } else if (block.number <= phase2time) {
                chillReward = multiplier.mul(blockPerPhase[1]).mul(pool.allocPoint).div(totalAllocPoint);
            } else if (block.number <= phase3time) {
                chillReward = multiplier.mul(blockPerPhase[2]).mul(pool.allocPoint).div(totalAllocPoint);
            } else if (block.number <= phase4time) {
                chillReward = multiplier.mul(blockPerPhase[3]).mul(pool.allocPoint).div(totalAllocPoint);
            } else {
                chillReward = multiplier.mul(blockPerPhase[4]).mul(pool.allocPoint).div(totalAllocPoint);
            }
            accChillPerShare = accChillPerShare.add(chillReward.mul(1e12).div(pool.totalPoolBalance));
            pending =  user.amount.mul(accChillPerShare).div(1e12).sub(user.rewardDebt);
            uint256 tax = deductTaxByBlock(getCrossMultiplier(user.startedBlock, block.number));
            if (tax > 0) {
                uint256 pendingTax = pending.mul(tax).div(100);
                pending = pending.sub(pendingTax);
            }
        }
        return pending;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getCrossMultiplier(uint256 _from, uint256 currentblock) public view returns (uint256) {
        uint256 multiplier;
        if (currentblock > _from) {
            multiplier = currentblock.sub(_from);
        } else {
            multiplier = _from.sub(currentblock);
        }
        return multiplier;
    }
    
    // get if nirvana
    function getNirvanaStatus(uint256 _from) public view returns (uint256) {
        uint256 multiplier = getCrossMultiplier(_from, block.number);
        uint256 isNirvana = getTotalBlocksCovered(multiplier);
        return isNirvana;
    }
    
    // Set extra reward after each 8 hours(1920 block)
    function getTotalBlocksCovered(uint256 _block) internal view returns(uint256) {
        if (_block >= blockMilestone[4]) { // 9600
            return 50;
        } else if (_block >= blockMilestone[3]) { // 7680
            return 40;
        } else if (_block >= blockMilestone[2]) { // 5760
            return 30;
        } else if (_block >= blockMilestone[1]) { // 3840
            return 20;
        } else if (_block >= blockMilestone[0]) { // 1920
            return 10;
        } else {
            return 0;
        }
    }
    
    // Deduct tax if user withdraw before nirvana at different stage
    function deductTaxByBlock(uint256 _block) internal view returns(uint256) {
        if (_block <= blockMilestone[0]) { // 1920
            return 50;
        } else if (_block <= blockMilestone[1]) { // 3840
            return 40;
        } else if (_block <= blockMilestone[2]) { // 5760
            return 30;
        } else if (_block <= blockMilestone[3]) { // 7680
            return 20;
        } else if (_block <= blockMilestone[4]) { // 9600
            return 10;
        }  else {
            return 0;
        }
    }

    // Safe chill transfer function, just in case if rounding error causes pool to not have enough CHILLs.
    function safeChillTransfer(address _to, uint256 _amount) internal {
        uint256 chillBal = chill.balanceOf(address(this));
        if (_amount > chillBal) {
            chill.transfer(_to, chillBal);
        } else {
            chill.transfer(_to, _amount);
        }
    }
    
    // if specific lp pool is supported in uniswap uni pool the deposited lp token in chill finance will again deposit in uni pool and earn double reward in uni token
    // and owner can withdraw extra reward from uni pool
    function getUniReward(address _stakeAddress) public onlyOwner {
        IUniStakingRewards(_stakeAddress).getReward();
    }
    
    // extra uni reward only access by distributor
    // distributor can be single user or any other contracts as well 
    function accessReward(address _uniAddress, address _to, uint256 _amount) public isDistributor(msg.sender) {
        require(_amount <= IERC20(_uniAddress).balanceOf(address(this)), "Not Enough Uni Token Balance");
        require(_to != address(0), "Not Vaild Address");
        IERC20(_uniAddress).safeTransfer(_to, _amount);
    }
    
    // withdraw extra uni reward and lp token as well from uni pool
    // function getUniRewardAndExit(address _stakeAddress) public onlyOwner {
    //     IUniStakingRewards(_stakeAddress).exit();
    // }
    
    // to give support to specific pool to deposit again in uni pool to generate extra reward in uni token 
    function addStakeUniPool(address _uniV2Pool, address _stakingRewardAddress) public onlyOwner {
        require(!stakingUniPools[_uniV2Pool], "This pool is already exist.");
        uint256 _amount = IERC20(_uniV2Pool).balanceOf(address(this));
        if(_amount > 0) {
            stakeInUni(_amount, address(_uniV2Pool), address(_stakingRewardAddress));
        }
        stakingUniPools[_uniV2Pool] = true;
        uniRewardAddresses[_uniV2Pool] = _stakingRewardAddress;
    }

    // to remove support of uni pool for specific pool
    function removeStakeUniPool(address _uniV2Pool) public onlyOwner {
        require(stakingUniPools[_uniV2Pool], "This pool is not exist.");
        uint256 _amount = IUniStakingRewards(uniRewardAddresses[address(_uniV2Pool)]).balanceOf(address(this));
        if (_amount > 0) {
            IUniStakingRewards(uniRewardAddresses[address(_uniV2Pool)]).withdraw(_amount);
        }
        stakingUniPools[_uniV2Pool] = false;
        uniRewardAddresses[_uniV2Pool] = address(0);
    }
    
    // dev adderess can only change by dev
    function dev(address _devaddr, uint256 _devFee, uint256 _devTaxFee) public {
        require(msg.sender == devaddr, "dev adddress is not valid");
        devaddr = _devaddr;
        DEV_FEE = _devFee;
        DEV_TAX_FEE = _devTaxFee;
    }

    // to set flag for count $20000 worth asset for specific pool
    function setCheckInitialPeriod(uint256 _pid, bool _isCheck) public onlyOwner {
        isCheckInitialPeriod[_pid] = _isCheck;
    }

    // set block milestone
    function setBlockMilestoneByIndex(uint256 _index, uint256 _blockMilestone) public onlyOwner {
        blockMilestone[_index] = _blockMilestone;
    }

    // increase any phase time and chill per block by its index
    function setAndEditPhaseTime(uint256 _index, uint256 _time, uint256 _chillPerBlock) public onlyOwner {
        blockPerPhase[_index] = _chillPerBlock;
        if(_index == 0) {
            phase1time = phase1time.add(_time);
        } else if(_index == 1) {
            phase2time = phase2time.add(_time);
        } else if(_index == 2) {
            phase3time = phase3time.add(_time);
        } else if(_index == 3) {
            phase4time = phase4time.add(_time);
        } else if(_index == 4) {
            phase5time = phase5time.add(_time);
        }
    }

    // get current phase with its chill per block
    function getPhaseTimeAndBlocks() public view returns(uint256, uint256) {
        if (block.number <= phase1time) {
            return ( phase1time, blockPerPhase[0] );
        } else if (block.number <= phase2time) {
            return ( phase2time, blockPerPhase[1] );
        } else if (block.number <= phase3time) {
            return ( phase3time, blockPerPhase[2] );
        } else if (block.number <= phase4time) {
            return ( phase4time, blockPerPhase[3] );
        } else {
            return ( phase5time, blockPerPhase[4] );
        }
    }

    // to set reward distibutor for extra uni token
    function setRewardDistributor(address _distributor, bool _isdistributor) public onlyOwner {
        distributors[_distributor] = _isdistributor;
    }
}
