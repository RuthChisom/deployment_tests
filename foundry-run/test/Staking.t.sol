// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/staking.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    bool public failTransfer;
    constructor() ERC20("Mock", "MCK") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    function setFailTransfer(bool _fail) external {
        failTransfer = _fail;
    }
    function transfer(address to, uint256 amount) public override returns (bool) {
        if (failTransfer) return false;
        return super.transfer(to, amount);
    }
}

contract StakingTest is Test {
    Staking public staking;
    MockERC20 public token;
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    uint256 public constant INITIAL_ETH_REWARD = 10 ether;
    uint256 public constant MIN_STAKE = 1e4;

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

        vm.startPrank(owner);
        token = new MockERC20();
        staking = new Staking{value: INITIAL_ETH_REWARD}(token);
        token.mint(owner, 1000 ether);
        token.approve(address(staking), type(uint256).max);
        vm.stopPrank();

        token.mint(user1, 1000 ether);
        vm.prank(user1);
        token.approve(address(staking), type(uint256).max);

        token.mint(user2, 1000 ether);
        vm.prank(user2);
        token.approve(address(staking), type(uint256).max);
    }

    // --- Constructor Tests ---
    function test_Constructor() public {
        assertEq(address(staking.stakeToken()), address(token));
        assertEq(staking.ethRewardAvailable(), INITIAL_ETH_REWARD);
        assertEq(staking.owner(), owner);
        assertEq(staking.startTime(), block.timestamp);
        assertEq(staking.stakeEndTime(), block.timestamp + 20 days);
    }

    // --- addTokenRewards Tests ---
    function test_AddTokenRewards() public {
        uint256 rewardAmt = 500 ether;
        vm.prank(owner);
        staking.addTokenRewards(rewardAmt);
        assertEq(staking.tokenRewardAvailable(), rewardAmt);
        assertEq(token.balanceOf(address(staking)), rewardAmt);
    }

    function test_Revert_AddTokenRewards_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert(Staking.NotOwner.selector);
        staking.addTokenRewards(100);
    }

    // --- stakeEth Tests ---
    function test_StakeEth() public {
        vm.prank(user1);
        staking.stakeEth{value: 1 ether}();

        (bool hasStaked, uint256 amountStaked, uint256 lastStakeTime, bool withdrawn) = staking.userEthStakeInfo(user1);
        assertTrue(hasStaked);
        assertEq(amountStaked, 1 ether);
        assertEq(lastStakeTime, block.timestamp);
        assertFalse(withdrawn);
        assertEq(staking.totalStakedEth(), 1 ether);
    }

    function test_Revert_StakeEth_InvalidAmount() public {
        vm.prank(user1);
        vm.expectRevert(Staking.InvalidAmount.selector);
        staking.stakeEth{value: MIN_STAKE - 1}();
    }

    function test_Revert_StakeEth_AlreadyStaked() public {
        vm.startPrank(user1);
        staking.stakeEth{value: 1 ether}();
        vm.expectRevert(Staking.AlreadyStaked.selector);
        staking.stakeEth{value: 1 ether}();
        vm.stopPrank();
    }

    // --- stakeErc20 Tests ---
    function test_StakeErc20() public {
        vm.prank(user1);
        staking.stakeErc20(10 ether);

        (bool hasStaked, uint256 amountStaked, uint256 lastStakeTime, bool withdrawn) = staking.userTokenStakeInfo(user1);
        assertTrue(hasStaked);
        assertEq(amountStaked, 10 ether);
        assertEq(lastStakeTime, block.timestamp);
        assertFalse(withdrawn);
        assertEq(staking.totalTokenStaked(), 10 ether);
        assertEq(token.balanceOf(address(staking)), 10 ether);
    }

    function test_Revert_StakeErc20_InvalidAmount() public {
        vm.prank(user1);
        vm.expectRevert(Staking.InvalidAmount.selector);
        staking.stakeErc20(MIN_STAKE - 1);
    }

    function test_Revert_StakeErc20_AlreadyStaked() public {
        vm.startPrank(user1);
        staking.stakeErc20(10 ether);
        vm.expectRevert(Staking.AlreadyStaked.selector);
        staking.stakeErc20(10 ether);
        vm.stopPrank();
    }

    // --- unstake Tests ---
    function test_UnstakeEth() public {
        vm.prank(user1);
        staking.stakeEth{value: 1 ether}();

        vm.warp(block.timestamp + 21 days);

        uint256 balanceBefore = user1.balance;
        vm.prank(user1);
        staking.unstake(true);
        uint256 balanceAfter = user1.balance;

        // Reward should be: (duration * amount * rewardAvailable) / (totalStaked * DURATION)
        // duration = 20 days (since it's capped at stakeEndTime - lastStakeTime)
        // (20 days * 1 ether * 10 ether) / (1 ether * 20 days) = 10 ether
        // Total withdrawn = 1 ether (stake) + 10 ether (reward) = 11 ether
        assertEq(balanceAfter - balanceBefore, 11 ether);
        
        (,,, bool withdrawn) = staking.userEthStakeInfo(user1);
        assertTrue(withdrawn);
    }

    function test_UnstakeErc20() public {
        // Setup token rewards first
        vm.prank(owner);
        staking.addTokenRewards(100 ether);

        vm.prank(user1);
        staking.stakeErc20(10 ether);

        vm.warp(block.timestamp + 21 days);

        uint256 balanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        staking.unstake(false);
        uint256 balanceAfter = token.balanceOf(user1);

        // Reward: (20 days * 10 ether * 100 ether) / (10 ether * 20 days) = 100 ether
        // Total: 10 + 100 = 110 ether
        assertEq(balanceAfter - balanceBefore, 110 ether);

        (,,, bool withdrawn) = staking.userTokenStakeInfo(user1);
        assertTrue(withdrawn);
    }

    function test_Revert_Unstake_StakeNotEnded() public {
        vm.prank(user1);
        staking.stakeEth{value: 1 ether}();

        vm.warp(block.timestamp + 10 days);
        vm.prank(user1);
        vm.expectRevert(Staking.StakeNotEnded.selector);
        staking.unstake(true);
    }

    function test_Revert_Unstake_InvalidAmount() public {
        vm.warp(block.timestamp + 21 days);
        vm.prank(user1);
        vm.expectRevert(Staking.InvalidAmount.selector);
        staking.unstake(true);
    }

    function test_Revert_Unstake_ERC20_InvalidAmount() public {
        vm.warp(block.timestamp + 21 days);
        vm.prank(user1);
        vm.expectRevert(Staking.InvalidAmount.selector);
        staking.unstake(false);
    }

    function test_Revert_Unstake_AlreadyWithdrawn() public {
        vm.prank(user1);
        staking.stakeEth{value: 1 ether}();

        vm.warp(block.timestamp + 21 days);
        vm.startPrank(user1);
        staking.unstake(true);
        vm.expectRevert(Staking.AlreadyWithdrawn.selector);
        staking.unstake(true);
        vm.stopPrank();
    }

    function test_Unstake_ERC20_AlreadyWithdrawn() public {
         vm.prank(user1);
        staking.stakeErc20(10 ether);

        vm.warp(block.timestamp + 21 days);
        vm.startPrank(user1);
        staking.unstake(false);
        vm.expectRevert(Staking.AlreadyWithdrawn.selector);
        staking.unstake(false);
        vm.stopPrank();
    }

    function test_Revert_Unstake_ERC20_WithdrawalFailed() public {
        vm.prank(user1);
        staking.stakeErc20(10 ether);

        vm.warp(block.timestamp + 21 days);
        
        token.setFailTransfer(true);
        vm.prank(user1);
        vm.expectRevert(Staking.WithdrawalFailed.selector);
        staking.unstake(false);
    }

    // --- Fuzz Test for Unstake ---
    /**
     * Unique fuzz test that varies the stake amount and ensures the total 
     * withdrawn (stake + reward) is consistent with the formula and doesn't crash.
     */
    function testFuzz_Unstake(uint256 stakeAmt, bool isEth, uint256 timePassed) public {
        // Bound inputs
        stakeAmt = bound(stakeAmt, MIN_STAKE, 100 ether);
        timePassed = bound(timePassed, 20.1 days, 100 days); // Ensure stake has ended

        if (isEth) {
            vm.deal(user2, stakeAmt);
            vm.prank(user2);
            staking.stakeEth{value: stakeAmt}();

            vm.warp(block.timestamp + timePassed);

            uint256 balanceBefore = user2.balance;
            vm.prank(user2);
            staking.unstake(true);
            uint256 balanceAfter = user2.balance;

            // Since user2 is the only staker (in this fuzz run's context, mostly), 
            // reward should be approx INITIAL_ETH_REWARD if they staked at start.
            // Formula: ( (endTime - lastStakeTime) * stakeAmt * ethRewardAvailable ) / (totalStakedEth * DURATION)
            // (20 days * stakeAmt * 10 ether) / (stakeAmt * 20 days) = 10 ether.
            assertEq(balanceAfter - balanceBefore, stakeAmt + INITIAL_ETH_REWARD);
        } else {
            uint256 tokenReward = 50 ether;
            vm.prank(owner);
            staking.addTokenRewards(tokenReward);

            token.mint(user2, stakeAmt);
            vm.startPrank(user2);
            token.approve(address(staking), stakeAmt);
            staking.stakeErc20(stakeAmt);
            vm.stopPrank();

            vm.warp(block.timestamp + timePassed);

            uint256 balanceBefore = token.balanceOf(user2);
            vm.prank(user2);
            staking.unstake(false);
            uint256 balanceAfter = token.balanceOf(user2);

            assertEq(balanceAfter - balanceBefore, stakeAmt + tokenReward);
        }
    }

    // Additional coverage for partial rewards (multiple stakers)
    function test_MultipleStakers_Eth() public {
        vm.prank(user1);
        staking.stakeEth{value: 1 ether}(); // at t=0

        vm.warp(block.timestamp + 10 days); // halfway

        vm.prank(user2);
        staking.stakeEth{value: 1 ether}(); // at t=10

        vm.warp(block.timestamp + 21 days); // end

        // totalStakedEth = 2 ether
        // user1 reward: (20 days * 1 ether * 10 ether) / (2 ether * 20 days) = 5 ether
        // user2 reward: (10 days * 1 ether * 10 ether) / (2 ether * 20 days) = 2.5 ether

        uint256 b1Before = user1.balance;
        vm.prank(user1);
        staking.unstake(true);
        assertEq(user1.balance - b1Before, 1 ether + 5 ether);

        uint256 b2Before = user2.balance;
        vm.prank(user2);
        staking.unstake(true);
        assertEq(user2.balance - b2Before, 1 ether + 2.5 ether);
    }
    
    // Test for failing transfer (ETH)
    // To test WithdrawalFailed for ETH, we need a contract that refuses ETH.
}

contract RevertingReceiver {
    receive() external payable {
        revert("I refuse ETH");
    }
    function stake(Staking staking) external payable {
        staking.stakeEth{value: msg.value}();
    }
    function unstake(Staking staking) external {
        staking.unstake(true);
    }
}

contract StakingFailTest is Test {
    Staking public staking;
    MockERC20 public token;

    function setUp() public {
        token = new MockERC20();
        staking = new Staking{value: 10 ether}(token);
    }

    function test_Revert_Unstake_WithdrawalFailed() public {
        RevertingReceiver receiver = new RevertingReceiver();
        vm.deal(address(receiver), 1 ether);
        
        receiver.stake{value: 1 ether}(staking);

        vm.warp(block.timestamp + 21 days);
        
        vm.expectRevert(Staking.WithdrawalFailed.selector);
        receiver.unstake(staking);
    }
}
