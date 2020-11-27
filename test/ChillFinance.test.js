const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ChillToken = artifacts.require('ChillToken');
const UniToken = artifacts.require('UniToken');
const ChillFinance = artifacts.require('ChillFinance');
const StakingRewards = artifacts.require('StakingRewards');
const MockERC20 = artifacts.require('MockERC20');
const UniswapV2Pair = artifacts.require('UniswapV2Pair');
const UniswapV2Library = artifacts.require('UniswapV2Library');
const UniswapV2Factory = artifacts.require('UniswapV2Factory');
const UniswapV2Router02 = artifacts.require('UniswapV2Router02');
const UniswapV2Router01 = artifacts.require('UniswapV2Router01');
const WETH9 = artifacts.require('WETH9');

contract('ChillFinance', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.factory = await UniswapV2Factory.new(alice, { from: alice });
        this.weth = await WETH9.new({ from: alice });
        this.router = await UniswapV2Router01.new(this.factory.address, this.weth.address, { from: alice });
        this.chill = await ChillToken.new(this.router.address, this.factory.address, this.weth.address, { from: alice });
        this.uni = await UniToken.new({ from: alice });
        this.uniV2Pair = await UniswapV2Pair.new({ from: alice });
    });

    it('should set correct state variables', async () => {
        this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });        
        await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        const chill = await this.chillchef.chill();
        const devaddr = await this.chillchef.devaddr();
        const owner = await this.chill.owner();
        assert.equal(chill.valueOf(), this.chill.address);
        assert.equal(devaddr.valueOf(), dev);
        assert.equal(owner.valueOf(), this.chillchef.address);
    });

    it('should allow dev and only dev to update dev', async () => {
        this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        assert.equal((await this.chillchef.devaddr()).valueOf(), dev);
        // await expectRevert(this.chillchef.dev(bob, { from: dev }), 'dev: wut?');
        await this.chillchef.dev(bob, '0', '20' , { from: dev });
        assert.equal((await this.chillchef.devaddr()).valueOf(), bob);
        await this.chillchef.dev(alice, '0', '20', { from: bob });
        assert.equal((await this.chillchef.devaddr()).valueOf(), alice);
    });

    context('With ERC/LP token added to the field', () => {
        beforeEach(async () => {
            this.lp = await MockERC20.new('LPToken', 'LP', '1000000000000000000000000000', { from: minter });
            await this.lp.transfer(minter, '400000000000000000000000', { from: minter });
            await this.lp.transfer(alice, '400000000000000000000000', { from: minter });
            await this.lp.transfer(bob, '400000000000000000000000', { from: minter });
            await this.lp.transfer(carol, '400000000000000000000000', { from: minter });

            this.lp2 = await MockERC20.new('LPToken', 'LP', '400000000000000000000000000', { from: minter });
            await this.lp2.transfer(minter, '400000000000000000000000', { from: minter });
            await this.lp2.transfer(alice, '400000000000000000000000', { from: minter });
            await this.lp2.transfer(bob, '400000000000000000000000', { from: minter });
            await this.lp2.transfer(carol, '400000000000000000000000', { from: minter });

            this.stakingRewards = await StakingRewards.new(minter, this.uni.address, this.lp.address, { from: minter });
            await this.uni.mint(this.stakingRewards.address, '1000000000000000000000', {from: alice});

            this.stakingRewards2 = await StakingRewards.new(minter, this.uni.address, this.lp2.address, { from: minter });
            await this.uni.mint(this.stakingRewards2.address, '1000000000000000000000', {from: alice});
        });

        it('should allow deposit on one lp one depositer', async () => {
            this.chillchef = await ChillFinance.new(this.chill.address, dev,{ from: alice });
            await this.chill.transferOwnership(this.chillchef.address, { from: alice });
            await this.chillchef.add('100', this.lp.address, true);
            await this.chillchef.set('0', '100', '10', minter, true);
            await time.advanceBlockTo('400');
            await this.lp.approve(this.chillchef.address, '100000000000000000000000', { from: alice });
            await this.chillchef.deposit('0', '100', { from: alice });
            await time.advanceBlockTo('600');
            const pendingChillAlice = await this.chillchef.pendingChill('0', alice, { from: alice });
            // await this.chillchef.deposit('0', '0', { from: alice }); // harvest with 0 amount
            // const burnDetails = await this.chillchef.getBurnedDetails();
            // console.log('burnDetails: ', burnDetails[0].toString());
            // console.log('burnDetails: ', burnDetails[1].toString());
            // console.log('burnDetails: ', burnDetails[2].toString());
            // console.log('burnDetails: ', burnDetails[3].toString());
            // await time.advanceBlockTo('1300');
            // await time.increaseTo('1604978963');
            // await this.chillchef.deposit('0', '0', { from: alice }); // harvest with 0 deposit amount
            // const burnDetails2 = await this.chillchef.getBurnedDetails();
            // console.log('burnDetails: ', burnDetails2[0].toString());
            // console.log('burnDetails: ', burnDetails2[1].toString());
            // console.log('burnDetails: ', burnDetails2[2].toString());
            // console.log('burnDetails: ', burnDetails2[3].toString());
            // await time.advanceBlockTo('1800');
            // await time.increaseTo('1605065963');
            // await this.chillchef.deposit('0', '0', { from: alice }); // harvest with 0 deposit amount
            // const burnDetails3 = await this.chillchef.getBurnedDetails();
            // console.log('burnDetails: ', burnDetails3[0].toString());
            // console.log('burnDetails: ', burnDetails3[1].toString());
            // console.log('burnDetails: ', burnDetails3[2].toString());
            // console.log('burnDetails: ', burnDetails3[3].toString());
            // await time.increaseTo('1605152963');
            // await this.chillchef.deposit('0', '0', { from: alice }); // harvest with 0 deposit amount
            // const burnDetails4 = await this.chillchef.getBurnedDetails();
            // console.log('burnDetails: ', burnDetails4[0].toString());
            // console.log('burnDetails: ', burnDetails4[1].toString());
            // console.log('burnDetails: ', burnDetails4[2].toString());
            // console.log('burnDetails: ', burnDetails4[3].toString());
            const alicebal = (await this.chill.balanceOf(alice)).valueOf();
            const minterbal = (await this.chill.balanceOf(minter)).valueOf();
            const devbal = (await this.chill.balanceOf(dev)).valueOf();
            const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
            const totalSupply = (await this.chill.totalSupply()).valueOf();
            let isCorrectAlice;
            if(parseInt(alicebal) > 7400000000000000000000) {
                isCorrectAlice = true;
            } else {
                isCorrectAlice = false;
            }
            assert.equal(isCorrectAlice, true);
            console.log('pendingChillAlice: ', pendingChillAlice.toString());
            console.log("Alice: ", alicebal.toString());
            console.log("Minter Nirvana-Rewarder: ", minterbal.toString());
            console.log("Dev: ", devbal.toString());
            console.log("Chef: ", chefbal.toString());
            console.log("totalSupply: ", totalSupply.toString());
        });
        
        // it('should allow deposit on one lp two depositer', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        //     await this.chillchef.add('100', this.lp.address, true);
        //     await this.chillchef.setNirvanaDetails('0', '10', minter);
        //     await time.advanceBlockTo('800');
        //     await this.lp.approve(this.chillchef.address, '100', { from: alice });
        //     await this.lp.approve(this.chillchef.address, '200', { from: bob });
        //     await this.chillchef.deposit(0, '100', { from: alice });
        //     await this.chillchef.deposit(0, '100', { from: bob });
        //     await time.advanceBlockTo('1500');
        //     const pendingChillAlice = await this.chillchef.pendingChill(0, alice, { from: alice });
        //     const pendingChillBob = await this.chillchef.pendingChill(0, bob, { from: bob });
        //     await this.chillchef.withdraw(0, '100', { from: alice });
        //     await this.chillchef.withdraw(0, '100', { from: bob });
        //     const alicebal = (await this.chill.balanceOf(alice)).valueOf();
        //     const bobbal = (await this.chill.balanceOf(bob)).valueOf();
        //     const minterbal = (await this.chill.balanceOf(minter)).valueOf();
        //     const devbal = (await this.chill.balanceOf(dev)).valueOf();
        //     const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
        //     const totalSupply = (await this.chill.totalSupply()).valueOf();
        //     let isCorrect;
        //     if(parseInt(alicebal) > 13000000000000000000000 && parseInt(bobbal) > 13000000000000000000000) {
        //         isCorrect = true;
        //     } else {
        //         isCorrect = false;
        //     }
        //     assert.equal(isCorrect, true);
        //     console.log('pendingChillAlice: ', pendingChillAlice.toString());
        //     console.log("Alice: ", alicebal.toString());
        //     console.log('pendingChillBob: ', pendingChillBob.toString());
        //     console.log("Bob: ", bobbal.toString());
        //     console.log("Minter Nirvana-Rewarder: ", minterbal.toString());
        //     console.log("Dev: ", devbal.toString());
        //     console.log("Chef: ", chefbal.toString());
        //     console.log("totalSupply: ", totalSupply.toString());
        // });

        // it('should distribute chills properly for each staker', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });
        //     await this.chillchef.add('100', this.lp.address, true);
        //     await this.chillchef.setNirvanaDetails('0', '10', minter);
        //     await this.lp.approve(this.chillchef.address, '1000', { from: alice });
        //     await this.lp.approve(this.chillchef.address, '1000', { from: bob });
        //     await this.chillchef.deposit(0, '1000', { from: alice });
        //     await this.chillchef.deposit(0, '1000', { from: bob });
        //     await this.stakingRewards.notifyRewardAmount('100000000000000000000', { from: minter });
        //     const stakelp = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     console.log("stakelp: ", stakelp.toString());
        //     await time.advanceBlockTo('2075');
        //     await this.chillchef.withdraw(0, '1000', { from: alice });
        //     await this.chillchef.withdraw(0, '1000', { from: bob });
        //     await this.chillchef.getUniReward(this.stakingRewards.address, { from: alice });
        //     const alicebal = (await this.chill.balanceOf(alice)).valueOf();
        //     const bobbal = (await this.chill.balanceOf(bob)).valueOf();
        //     const minterbal = (await this.chill.balanceOf(minter)).valueOf();
        //     const devbal = (await this.chill.balanceOf(dev)).valueOf();
        //     const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
        //     const totalSupply = (await this.chill.totalSupply()).valueOf();
        //     const chefuni = (await this.uni.balanceOf(this.chillchef.address)).valueOf();
        //     const minterbalUni = (await this.uni.balanceOf(minter)).valueOf();
        //     const alicebaluni = (await this.uni.balanceOf(alice)).valueOf();
        //     const stakelp2 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     let isCorrect;
        //     if(parseInt(alicebal) > 10000000000000000000000 && parseInt(bobbal) > 10000000000000000000000 && parseInt(chefuni) > 0) {
        //         isCorrect = true;
        //     } else {
        //         isCorrect = false;
        //     }
        //     assert.equal(isCorrect, true);
        //     console.log("Alice: ", alicebal.toString());
        //     console.log("Bob: ", bobbal.toString());
        //     console.log("Minter Nirvana-Rewarder: ", minterbal.toString());
        //     console.log("Dev: ", devbal.toString());
        //     console.log("Chef: ", chefbal.toString());
        //     console.log("totalSupply: ", totalSupply.toString());
        //     console.log("stakelp: ", stakelp2.toString());
        //     console.log("ChefUni: ", chefuni.toString());
        //     console.log("alicebaluni: ", alicebaluni.toString());
        //     console.log("Minter: ", minterbalUni.toString());
        // });
        
        // it('should proper CHILLs allocation to each pool', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });
        //     await this.chillchef.add('100', this.lp.address, true);
        //     await this.chillchef.add('100', this.lp2.address, true);
        //     await this.lp.approve(this.chillchef.address, '1000', { from: alice });
        //     await this.lp2.approve(this.chillchef.address, '1000', { from: bob });
        //     await this.chillchef.deposit('0', '1000', { from: alice });
        //     await this.chillchef.deposit('1', '1000', { from: bob });
        //     await this.stakingRewards.notifyRewardAmount('100000000000000000000', { from: minter });
        //     const stakelp = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     console.log("stakelp: ", stakelp.toString());
        //     await time.advanceBlockTo('2150');
        //     await this.chillchef.withdraw(0, '1000', { from: alice });
        //     await this.chillchef.withdraw(1, '1000', { from: bob });
        //     await this.chillchef.getUniReward(this.stakingRewards.address, { from: alice });
        //     const alicebal = (await this.chill.balanceOf(alice)).valueOf();
        //     const bobbal = (await this.chill.balanceOf(bob)).valueOf();
        //     const carolbal = (await this.chill.balanceOf(carol)).valueOf();
        //     const devbal = (await this.chill.balanceOf(dev)).valueOf();
        //     const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
        //     const totalSupply = (await this.chill.totalSupply()).valueOf();
        //     const chefuni = (await this.uni.balanceOf(this.chillchef.address)).valueOf();
        //     const minterbal = (await this.uni.balanceOf(minter)).valueOf();
        //     const alicebaluni = (await this.uni.balanceOf(alice)).valueOf();
        //     const stakelp2 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     let isCorrect;
        //     if(parseInt(alicebal) > 840000000000000000000 && parseInt(bobbal) > 840000000000000000000 && parseInt(chefuni) > 0) {
        //         isCorrect = true;
        //     } else {
        //         isCorrect = false;
        //     }
        //     assert.equal(isCorrect, true);
        //     console.log("Alice: ", alicebal.toString());
        //     console.log("Bob: ", bobbal.toString());
        //     console.log("Carol: ", carolbal.toString());
        //     console.log("Dev: ", devbal.toString());
        //     console.log("Chef: ", chefbal.toString());
        //     console.log("totalSupply: ", totalSupply.toString());
        //     console.log("stakelp: ", stakelp2.toString());
        //     console.log("ChefUni: ", chefuni.toString());
        //     console.log("alicebaluni: ", alicebaluni.toString());
        //     console.log("Minter: ", minterbal.toString());
        // });

        // it('should deduct reward before nirvana', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });
        //     await this.chillchef.add('100', this.lp.address, true);
        //     await this.lp.approve(this.chillchef.address, '1000', { from: alice });
        //     await time.advanceBlockTo('2300'); 
        //     await this.chillchef.deposit('0', '1000', { from: alice });
        //     await this.stakingRewards.notifyRewardAmount('100000000000000000000', { from: minter });
        //     const stakelp = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     console.log("stakelp: ", stakelp.toString());
        //     await time.advanceBlockTo('3000');
        //     await this.chillchef.withdraw(0, '1000', { from: alice });
        //     await this.chillchef.getUniReward(this.stakingRewards.address, { from: alice });
        //     const alicebal = (await this.chill.balanceOf(alice)).valueOf();
        //     const devbal = (await this.chill.balanceOf(dev)).valueOf();
        //     const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
        //     const totalSupply = (await this.chill.totalSupply()).valueOf();
        //     const stakelp2 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     const chefuni = (await this.uni.balanceOf(this.chillchef.address)).valueOf();
        //     const minterbal = (await this.uni.balanceOf(minter)).valueOf();
        //     const alicebaluni = (await this.uni.balanceOf(alice)).valueOf();
        //     console.log("Alice: ", alicebal.toString());
        //     console.log("Dev: ", devbal.toString());
        //     console.log("Chef: ", chefbal.toString());
        //     console.log("totalSupply: ", totalSupply.toString());
        //     console.log("stakelp: ", stakelp2.toString());
        //     console.log("ChefUni: ", chefuni.toString());
        //     console.log("alicebaluni: ", alicebaluni.toString());
        //     console.log("Minter: ", minterbal.toString());
        //     let isCorrect;
        //     if(parseInt(alicebal) > 26000000000000000000000 && parseInt(chefuni) > 0) {
        //         isCorrect = true;
        //     } else {
        //         isCorrect = false;
        //     }
        //     assert.equal(isCorrect, true);
        // });

        // it('should not deduct reward after nirvana', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });
        //     await this.chillchef.add('100', this.lp.address, true);
        //     await this.lp.approve(this.chillchef.address, '1000', { from: alice });
        //     await time.advanceBlockTo('400');
        //     await this.chillchef.deposit(0, '1000', { from: alice });
        //     await this.stakingRewards.notifyRewardAmount('100000000000000000000', { from: minter });
        //     const stakelp = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     console.log("stakelp: ", stakelp.toString());
        //     //after 9600 block it will be nirvana so no deduct and multiplier will be 1.5 instead 1
        //     await time.advanceBlockTo('10100');
        //     await this.chillchef.withdraw(0, '1000', { from: alice });
        //     await this.chillchef.getUniReward(this.stakingRewards.address, { from: alice });
        //     const alicebal = (await this.chill.balanceOf(alice)).valueOf();
        //     const devbal = (await this.chill.balanceOf(dev)).valueOf();
        //     const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
        //     const totalSupply = (await this.chill.totalSupply()).valueOf();
        //     const chefuni = (await this.uni.balanceOf(this.chillchef.address)).valueOf();
        //     const minterbal = (await this.uni.balanceOf(minter)).valueOf();
        //     const alicebaluni = (await this.uni.balanceOf(alice)).valueOf();
        //     const stakelp2 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     let isCorrect;
        //     if(parseInt(alicebal) > 727000000000000000000000 && parseInt(chefuni) > 0) {
        //         isCorrect = true;
        //     } else {
        //         isCorrect = false;
        //     }
        //     assert.equal(isCorrect, true);
        //     console.log("Alice: ", alicebal.toString());
        //     console.log("Dev: ", devbal.toString());
        //     console.log("Chef: ", chefbal.toString());
        //     console.log("totalSupply: ", totalSupply.toString());

        //     console.log("stakelp: ", stakelp2.toString());
        //     console.log("ChefUni: ", chefuni.toString());
        //     console.log("alicebaluni: ", alicebaluni.toString());
        //     console.log("Minter: ", minterbal.toString());
        // });

        // it('should proper CHILLs allocation to each pool by its alloc point', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });

        //     await this.chillchef.add('100', this.lp.address, true);
        //     await this.chillchef.add('200', this.lp2.address, true);
            
        //     await this.lp.approve(this.chillchef.address, '1000', { from: alice });
        //     await this.lp2.approve(this.chillchef.address, '1000', { from: bob });

        //     await time.advanceBlockTo('400'); 

        //     await this.chillchef.deposit(0, '1000', { from: alice });
        //     await this.chillchef.deposit(1, '1000', { from: bob });

        //     await this.stakingRewards.notifyRewardAmount('100000000000000000000', { from: minter });

        //     const stakelp = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     console.log("stakelp: ", stakelp.toString());

        //     await time.advanceBlockTo('900'); 

        //     await this.chillchef.withdraw(0, '1000', { from: alice });
        //     await this.chillchef.withdraw(1, '1000', { from: bob });
        //     await this.chillchef.getUniReward(this.stakingRewards.address, { from: alice });

        //     const alicebal = (await this.chill.balanceOf(alice)).valueOf();
        //     const bobbal = (await this.chill.balanceOf(bob)).valueOf();
        //     const devbal = (await this.chill.balanceOf(dev)).valueOf();
        //     const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
        //     const totalSupply = (await this.chill.totalSupply()).valueOf();
            
        //     const chefuni = (await this.uni.balanceOf(this.chillchef.address)).valueOf();
        //     const minterbal = (await this.uni.balanceOf(minter)).valueOf();
        //     const alicebaluni = (await this.uni.balanceOf(alice)).valueOf();
        //     const stakelp2 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();

        //     let isCorrect;
        //     if(parseInt(alicebal) >= 6200000000000000000000 && parseInt(bobbal) >= 12000000000000000000000 && parseInt(chefuni) > 0) {
        //         isCorrect = true;
        //     } else {
        //         isCorrect = false;
        //     }
        //     assert.equal(isCorrect, true);
            
        //     console.log("Alice: ", alicebal.toString());
        //     console.log("Bob: ", bobbal.toString());
        //     console.log("Dev: ", devbal.toString());
        //     console.log("Chef: ", chefbal.toString());
        //     console.log("totalSupply: ", totalSupply.toString());

        //     console.log("stakelp: ", stakelp2.toString());
        //     console.log("ChefUni: ", chefuni.toString());
        //     console.log("alicebaluni: ", alicebaluni.toString());
        //     console.log("Minter: ", minterbal.toString());
        // });

        // it('should distribute chills properly for each staker and each pool and also match pending chill with update pool', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });
        //     await this.chillchef.addStakeUniPool(this.lp2.address, this.stakingRewards2.address, { from: alice });

        //     await this.chillchef.add('100', this.lp.address, true);
        //     await this.chillchef.add('100', this.lp2.address, true);
            
        //     await this.lp.approve(this.chillchef.address, '1000000000', { from: alice });
        //     await this.lp.approve(this.chillchef.address, '1000000000', { from: bob });
        //     await this.lp2.approve(this.chillchef.address, '1000000000', { from: carol });
        //     await this.lp2.approve(this.chillchef.address, '1000000000', { from: minter });

        //     await this.chillchef.deposit(0, '1000000000', { from: alice });
        //     await this.chillchef.deposit(0, '1000000000', { from: bob });
        //     await this.chillchef.deposit(1, '1000000000', { from: carol });
        //     await this.chillchef.deposit(1, '1000000000', { from: minter });

        //     await this.stakingRewards.notifyRewardAmount('100000000000000000000', { from: minter });
        //     await this.stakingRewards2.notifyRewardAmount('100000000000000000000', { from: minter });

        //     const stakelp0 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
        //     console.log("stakelp0: ", stakelp0.toString());
        //     const stakelp1 = (await this.lp2.balanceOf(this.stakingRewards.address)).valueOf();
        //     console.log("stakelp1: ", stakelp1.toString());

        //     await time.advanceBlockTo('1900');

        //     const alicePending = await this.chillchef.pendingChill(0, alice, {from: alice}).valueOf();
        //     const BobPending = await this.chillchef.pendingChill(0, bob, {from: alice}).valueOf();
        //     const CarolPending = await this.chillchef.pendingChill(1, carol, {from: alice}).valueOf();
        //     const MinterPending = await this.chillchef.pendingChill(1, minter, {from: alice}).valueOf();

        //     await this.chillchef.withdraw(0, '1000000000', { from: alice });
        //     await this.chillchef.withdraw(0, '1000000000', { from: bob });
        //     await this.chillchef.withdraw(1, '1000000000', { from: carol });
        //     await this.chillchef.withdraw(1, '1000000000', { from: minter });

        //     await this.chillchef.getUniReward(this.stakingRewards.address, { from: alice });

        //     const alicebal = (await this.chill.balanceOf(alice)).valueOf();
        //     const bobbal = (await this.chill.balanceOf(bob)).valueOf();
        //     const carolbal = (await this.chill.balanceOf(carol)).valueOf();
        //     const minterbal = (await this.chill.balanceOf(minter)).valueOf();
        //     const devbal = (await this.chill.balanceOf(dev)).valueOf();
        //     const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
        //     const totalSupply = (await this.chill.totalSupply()).valueOf();
            
        //     let isCorrect;
        //     if(parseInt(alicebal) > 9070000000000000000000 && parseInt(alicebal) > 9070000000000000000000 && parseInt(alicebal) > 9070000000000000000000 && parseInt(alicebal) > 9070000000000000000000) {
        //         isCorrect = true;
        //     } else {
        //         isCorrect = false;
        //     }
        //     assert.equal(isCorrect, true);

        //     console.log("AlicePending: ", alicePending.toString());
        //     console.log("BobPending: ", BobPending.toString());
        //     console.log("CarolPending: ", CarolPending.toString());
        //     console.log("MinterPending: ", MinterPending.toString());
            
        //     console.log("Alice: ", alicebal.toString());
        //     console.log("Bob: ", bobbal.toString());
        //     console.log("Carol: ", carolbal.toString());
        //     console.log("Minter: ", minterbal.toString());
        //     console.log("Dev: ", devbal.toString());
        //     console.log("Chef: ", chefbal.toString());
        //     console.log("totalSupply: ", totalSupply.toString());

        //     const chefuni = (await this.uni.balanceOf(this.chillchef.address)).valueOf();
        //     const stakelp2 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();

        //     console.log("stakelp: ", stakelp2.toString());
        //     console.log("ChefUni: ", chefuni.toString());
        // });

        // it('should add new uni pool for chill finance', async () => {
        //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
        //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });

        //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });
        //     await this.chillchef.removeStakeUniPool(this.lp.address, { from: alice });
        // }); 

    //     // it("Check price below $20000", async () => {
    //     //     this.chillchef = await ChillFinance.new(this.chill.address, dev, { from: alice });
    //     //     await this.chill.transferOwnership(this.chillchef.address, { from: alice });
    //     //     await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });

    //     //     const balance = await this.chillchef.countStakeAmount(alice, alice, "1000").valueOf();
    //     //     console.log(balance.toString());
    //     // });
        
    //     // it("#1 ", async () => {
            
    //     //     this.unifactory = await UniswapV2Factory.new(alice, { from: alice });
    //     //     this.weth = await WETH9.new({ from: alice });
    //     //     const length = await this.unifactory.allPairsLength({from: alice}).valueOf();
    //     //     console.log(length.toString());

    //     //     await this.unifactory.createPair(this.lp.address, this.lp2.address, { from: alice });

    //     //     const length2 = await this.unifactory.allPairsLength({from: alice}).valueOf();
    //     //     console.log(length2.toString()); 

    //     //     const pair = await this.unifactory.getPair(this.lp.address, this.lp2.address).valueOf();
    //     //     console.log(pair.toString());


    //     //     this.router01 = await UniswapV2Router01.new(this.unifactory.address, this.weth.address, { from: alice });
    //     //     console.log(this.router01.address);

    //     //     await this.lp.approve(this.router01.address, "100000000000000000000", { from: alice });
    //     //     await this.lp3.approve(this.router01.address, "40000000000000000000000", { from: alice });
    //     //     await this.router01.addLiquidity(this.lp.address, this.lp3.address, "10000000000000000000", "4000000000000000000000", "0", "0", alice, 1603964349, { from: alice });
    //     //     // this.univ2pair = await UniswapV2Pair(pair);
    //     // });
    });
});
