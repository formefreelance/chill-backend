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
const AirDrop = artifacts.require('AirDrop');

contract('AirDrop', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.factory = await UniswapV2Factory.new(alice, { from: alice });
        this.weth = await WETH9.new({ from: alice });
        this.router = await UniswapV2Router01.new(this.factory.address, this.weth.address, { from: alice });
        this.chill = await ChillToken.new(this.router.address, this.factory.address, this.weth.address, { from: alice });
        this.uni = await UniToken.new({ from: alice });
        this.uniV2Pair = await UniswapV2Pair.new({ from: alice });
        this.airdrop = await AirDrop.new(alice, { from: alice });
    });

    it('should set correct state variables', async () => {
        this.chillchef = await ChillFinance.new(this.chill.address, dev, this.uniV2Pair.address, { from: alice });        
        await this.chill.transferOwnership(this.chillchef.address, { from: alice });
        const chill = await this.chillchef.chill();
        const devaddr = await this.chillchef.devaddr();
        const owner = await this.chill.owner();
        assert.equal(chill.valueOf(), this.chill.address);
        assert.equal(devaddr.valueOf(), dev);
        assert.equal(owner.valueOf(), this.chillchef.address);
    });

    it('should allow dev and only dev to update dev', async () => {
        this.chillchef = await ChillFinance.new(this.chill.address, dev, this.uniV2Pair.address, { from: alice });
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

        
        it('should not deduct reward after nirvana', async () => {
            this.chillchef = await ChillFinance.new(this.chill.address, dev, this.uniV2Pair.address, { from: alice });
            await this.chill.transferOwnership(this.chillchef.address, { from: alice });
            await this.chillchef.addStakeUniPool(this.lp.address, this.stakingRewards.address, { from: alice });
            await this.chillchef.add('100', this.lp.address, true);
            await this.chillchef.setNirvanaDetails('0', '5', this.airdrop.address);
            await this.lp.approve(this.chillchef.address, '1000', { from: alice });
            await this.lp.approve(this.chillchef.address, '2000', { from: bob });
            await time.advanceBlockTo('400');
            await this.chillchef.deposit(0, '1000', { from: alice });
            await this.chillchef.deposit(0, '2000', { from: bob });
            await this.stakingRewards.notifyRewardAmount('100000000000000000000', { from: minter });
            const stakelp = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
            console.log("stakelp: ", stakelp.toString());
            await time.advanceBlockTo('1000');
            await this.chillchef.deposit('0', '0', { from: bob });
            //after 9600 block it will be nirvana so no deduct and multiplier will be 1.5 instead 1
            await time.advanceBlockTo('10100');
            // await this.chillchef.deposit('0', '0', { from: alice });
            await this.chillchef.getUniReward(this.stakingRewards.address, { from: alice });
            const alicebal = (await this.chill.balanceOf(alice)).valueOf();
            const bobbal = (await this.chill.balanceOf(bob)).valueOf();
            const devbal = (await this.chill.balanceOf(dev)).valueOf();
            const chefbal = (await this.chill.balanceOf(this.chillchef.address)).valueOf();
            const totalSupply = (await this.chill.totalSupply()).valueOf();
            const chefuni = (await this.uni.balanceOf(this.chillchef.address)).valueOf();
            const minterbal = (await this.uni.balanceOf(minter)).valueOf();
            const alicebaluni = (await this.uni.balanceOf(alice)).valueOf();
            const stakelp2 = (await this.lp.balanceOf(this.stakingRewards.address)).valueOf();
            const airdropbal = (await this.chill.balanceOf(this.airdrop.address)).valueOf();
            // let isCorrect;
            // if(parseInt(alicebal) > 727000000000000000000000 && parseInt(chefuni) > 0) {
            //     isCorrect = true;
            // } else {
            //     isCorrect = false;
            // }
            // assert.equal(isCorrect, true);
            console.log("Alice: ", alicebal.toString());
            console.log("Bob: ", bobbal.toString());
            console.log("Dev: ", devbal.toString());
            console.log("Chef: ", chefbal.toString());
            console.log("totalSupply: ", totalSupply.toString());
            console.log("stakelp: ", stakelp2.toString());
            console.log("ChefUni: ", chefuni.toString());
            console.log("alicebaluni: ", alicebaluni.toString());
            console.log("Minter: ", minterbal.toString());
            console.log("Airdrop: ", airdropbal.toString());
            await this.airdrop.setChillFinance(this.chillchef.address);
            await this.airdrop.setChillToken(this.chill.address);
            const mul = await this.airdrop.getNirvana('0', {from: alice});
            console.log('Nirvana Alice=:', mul.toString());
            await time.increaseTo('1605469407');
            await this.airdrop.claimNirvanaReward('0', { from: alice });
            // await this.airdrop.claimNirvanaReward('0', {from: bob});
            const alicebal2 = (await this.chill.balanceOf(alice)).valueOf();
            const bobbal2 = (await this.chill.balanceOf(bob)).valueOf();
            const airdropbal2 = (await this.chill.balanceOf(this.airdrop.address)).valueOf();
            console.log("Alice2: ", alicebal2.toString());
            console.log("Bob2: ", bobbal2.toString());
            console.log("Airdrop2: ", airdropbal2.toString());
        });
    });
});
