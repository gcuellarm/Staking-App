//SPDX-License-Identifier: LGPL-3.0-only


//Version
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test{
    StakingToken stakingToken;
    StakingApp stakingApp;

    //StakingToken parameters
    string name_ = "Staking Token";
    string symbol_ = "STK";

    //StakingApp parameters
    address owner_ = vm.addr(1);
    uint256 stakingPeriod_ = 100000000000000;
    uint256 fixedStakingAmount_  = 10;
    uint256 rewardPerPeriod_ = 1 ether;

    address randomUser = vm.addr(2);


    function setUp() public{
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

//1. Test to see if our staking token deploys correctly
    function testStakingTokenCorrectlyDeployed() external{
        assert(address(stakingToken) != address(0));
    }

//2. Test to see if our staking app deploys correctly
    function testStakingAppCorrectlyDeployed() external{
        assert(address(stakingToken) != address(0));
    }

//3. Test to revert the action if not the owner tries to change the staking period
    function testShouldRevertIfNotOwner() external{
        uint256 newStakingPeriod_ = 1;
        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
    }

//4. Test to change the staking period successfully
    function testShouldChangeStakingPeriod() external{
        vm.startPrank(owner_);
        uint256 newStakingPeriod_ = 1;

        uint256 stakingPeriodBefore = stakingApp.stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
        uint256 stakingPeriodAfter = stakingApp.stakingPeriod();

        assert(stakingPeriodBefore != newStakingPeriod_);
        assert(stakingPeriodAfter == newStakingPeriod_);
        vm.stopPrank();
    }

//5. Test to see ig the contract receives Ether correctly
    function testContractReceivesEtherCorrectly() external  {
        vm.startPrank(owner_);
        vm.deal(owner_, 1 ether);
        uint256 etherValue = 1 ether;

        uint256 balanceBefore = address(stakingApp).balance;
        (bool success, ) = address(stakingApp).call{value: etherValue}("");
        uint256 balanceAfter = address(stakingApp).balance;

        require(success, "Transfer failed");

        assert(balanceAfter - balanceBefore == etherValue);
        vm.stopPrank();
    }

    //Deposit Function tests

//6. Test to revert the action when depositing an invalid amount
    function testIncorrectAmountShouldRevert() external{
        vm.startPrank(randomUser);

        uint256 depositAmount = 1;
        vm.expectRevert("Incorrect amount");
        stakingApp.depositTokens(depositAmount);


        vm.stopPrank();
    }

//7. Test to deposit tokens correctly
    function testDepositTokenscorrectly() external{
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); 

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore== 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.stopPrank();
    }

//8. Test trying to deposit more than once, should revert
    function testUserCannotDepositMoreThanOnce() external{
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); 

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore== 0);
        assert(elapsePeriodAfter == block.timestamp);

        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        vm.expectRevert("User already deposited");
        stakingApp.depositTokens(tokenAmount);

        vm.stopPrank();
    }
    
    //Withdraw function testing

//9. Test to check that only 0 is withdrawable when 0 is the amount deposited
    function testCanOnlyWithdraw0WithoutDeposit() external{
        vm.startPrank(randomUser);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        assert(userBalanceAfter == userBalanceBefore);

        vm.stopPrank();
    }

//10. Test to withdraw tokens correctly
    function testWithdrawTokensCorrectly() external{
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); 

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore== 0);
        assert(elapsePeriodAfter == block.timestamp);

        uint256 userBalanceBefore2 = IERC20(stakingToken).balanceOf(randomUser);
        uint256 userBalanceInMapping = stakingApp.userBalance(randomUser);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfter2 = IERC20(stakingToken).balanceOf(randomUser);
        assert(userBalanceAfter2 == userBalanceBefore2 + userBalanceInMapping);


        vm.stopPrank();
    }


    //Claim Rewards testing

//11. Test to check claim is not possible if there's no previous staking, should revert
    function testCannotClaimIfNotStaking() external {
        vm.startPrank(randomUser);

        vm.expectRevert("Not staking");
        stakingApp.claimRewards();

        vm.stopPrank();

    }

//12. Test to check claim is not possible if time is not enough, should revert
    function testCannotClaimIfNotElapsedTime() external{
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); 

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore== 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.expectRevert("Need to wait");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

//13. Test to check claim is not possible if there's no ether, should revert
        function testShouldRevertIfNoEther() external{
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); 

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore== 0);
        assert(elapsePeriodAfter == block.timestamp);

        
        vm.warp(block.timestamp + stakingPeriod_); //this "moves" you to the point in time you want to be, so the parameter must be that point in time
        vm.expectRevert("Transfer failed");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

//14. Test to check claim works correctly
    function testCanClaimRewardsCorrectly() external{
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); 

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore== 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.stopPrank();

        vm.startPrank(owner_);
        uint256 etherAmount = 100000 ether;
        vm.deal(owner_, etherAmount);
        (bool success, ) = address(stakingApp).call{value: etherAmount}("");
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.warp(block.timestamp + stakingPeriod_); //vm.warp "moves" you to the point in time you want to be, so the parameter must be that point in time
        uint256 etherAmountBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 etherAmountAfter = address(randomUser).balance;
        uint256 elapsePeriod = stakingApp.elapsePeriod(randomUser);


        assert(etherAmountAfter - etherAmountBefore == rewardPerPeriod_);
        assert(elapsePeriod == block.timestamp);
        

        vm.stopPrank();
    }

//15. Test to see if it's possible to claim reward twice in a row, should revert
    function testCannotClaimRewardsTwice() external{
         vm.startPrank(randomUser);

        //minteamos tokens
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount); 

        //miramos el balance y el tiempo antes de stakear, depositamos los tokens y miramos el balance y el tiempo a posteriori
        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        //asserts para hacer las pruebas
        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore== 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.stopPrank();

        vm.startPrank(owner_);
        uint256 etherAmount = 100000 ether;
        vm.deal(owner_, etherAmount);
        (bool success, ) = address(stakingApp).call{value: etherAmount}("");
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.warp(block.timestamp + stakingPeriod_); 
        uint256 etherAmountBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 etherAmountAfter = address(randomUser).balance;
        uint256 elapsePeriod = stakingApp.elapsePeriod(randomUser);


        assert(etherAmountAfter - etherAmountBefore == rewardPerPeriod_);
        assert(elapsePeriod == block.timestamp);

        //Claim again, should revert because elapsePeriod is not enough
        vm.expectRevert("Need to wait");
        stakingApp.claimRewards();
        

        vm.stopPrank();
    }
}