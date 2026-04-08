// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    // we want to stake eth and erc20?
    // stake unstake/withdraw
    // min stake
    // stake eth get eth, stake token get token
    // we will need to create a function to add claimable rewards

    IERC20 public stakeToken;
    uint256 public stakeEndTime;
    uint256 public totalStakedEth;
    uint256 public totalTokenStaked;
    uint256 public ethRewardAvailable;
    uint256 public tokenRewardAvailable;
    uint256 public minStakeAmt = 1e4;
    uint256 public constant BASIS_POINT = 1e4;
    uint256 public constant DURATION = 20 days;
    uint256 public rewardRate;
    address public owner;
    uint256 public startTime;

    struct ethStakeInfo {
        bool hasStaked;
        uint256 amountStaked;
        uint256 lastStakeTime;
        bool withdrawn;
    }

    struct erc20StakeInfo {
        bool hasStaked;
        uint256 amountStaked;
        uint256 lastStakeTime;
        bool withdrawn;
    }

    mapping(address => ethStakeInfo) public userEthStakeInfo;
    mapping(address => erc20StakeInfo) public userTokenStakeInfo;

    error InvalidAmount();
    error AlreadyStaked();
    error StakeNotEnded();
    error AlreadyWithdrawn();
    error WithdrawalFailed();
    error NotOwner();

    event Staked(address user, uint256 _amount, uint256 time, bool isEthStake);
    event Unstaked(address user, uint256 _amount, bool isEth);

    constructor(IERC20 _stakeToken) payable {
        stakeToken = _stakeToken;
        ethRewardAvailable = msg.value;
        startTime = block.timestamp;
        stakeEndTime = startTime + DURATION;
        owner = msg.sender;
    }

    function addTokenRewards(uint256 _amount) external {
        if (msg.sender != owner) revert NotOwner();
        tokenRewardAvailable = _amount;
        stakeToken.transferFrom(msg.sender, address(this), _amount);
    }

    function stakeEth() external payable {
        if (msg.value < minStakeAmt) revert InvalidAmount();
        ethStakeInfo storage _stake = userEthStakeInfo[msg.sender];
        if (_stake.hasStaked) revert AlreadyStaked();
        _stake.hasStaked = true;
        _stake.amountStaked += msg.value;
        _stake.lastStakeTime = block.timestamp;
        totalStakedEth += msg.value;

        emit Staked(msg.sender, msg.value, block.timestamp, true);
    }

    function stakeErc20(uint256 _amount) external {
        if (_amount < minStakeAmt) revert InvalidAmount();
        stakeToken.transferFrom(msg.sender, address(this), _amount);
        erc20StakeInfo storage _stake = userTokenStakeInfo[msg.sender];
        if (_stake.hasStaked) revert AlreadyStaked();
        _stake.hasStaked = true;
        _stake.amountStaked += _amount;
        _stake.lastStakeTime = block.timestamp;
        totalTokenStaked += _amount;

        emit Staked(msg.sender, _amount, block.timestamp, false);
    }

    function unstake(bool isEth) external {
        if (block.timestamp <= stakeEndTime) revert StakeNotEnded();
        uint256 _reward;
        uint256 withdrawn;
        if (isEth) {
            ethStakeInfo storage _stake = userEthStakeInfo[msg.sender];
            uint256 _amount = _stake.amountStaked;
            if (_amount == 0) revert InvalidAmount();
            if (_stake.withdrawn) revert AlreadyWithdrawn();
            _stake.withdrawn = true;
            _reward = _caluculateRewardClaimable(_amount, true);
            withdrawn = _reward + _amount;
            (bool s,) = msg.sender.call{value: withdrawn}("");
            if (!s) revert WithdrawalFailed();

            emit Unstaked(msg.sender, withdrawn, true);
        } else {
            erc20StakeInfo storage _stake = userTokenStakeInfo[msg.sender];
            uint256 _amount = _stake.amountStaked;
            if (_amount == 0) revert InvalidAmount();
            if (_stake.withdrawn) revert AlreadyWithdrawn();
            _stake.withdrawn = true;
            _reward = _caluculateRewardClaimable(_amount, false);
            withdrawn = _reward + _amount;
            if (!stakeToken.transfer(msg.sender, withdrawn)) revert WithdrawalFailed();

            emit Unstaked(msg.sender, withdrawn, false);
        }
    }

    function _caluculateRewardClaimable(uint256 _amount, bool isEth) internal view returns (uint256 reward) {
        uint256 _userStakeDuration;
        uint256 _userShares;
        if (isEth) {
            ethStakeInfo storage _stake = userEthStakeInfo[msg.sender];
            _userStakeDuration = stakeEndTime - _stake.lastStakeTime;
            // Division before multiplication avoidance? No, it has * 
            // reward = (_userStakeDuration * _stake.amountStaked) / (totalStakedEth  * DURATION) * ethRewardAvailable;
            // Wait, the original was: _userShares = (_userStakeDuration * _stake.amountStaked) / (totalStakedEth  * DURATION); reward = _userShares * ethRewardAvailable;
            // This is prone to rounding to zero. Better to multiply all numerators first.
            reward = (_userStakeDuration * _amount * ethRewardAvailable) / (totalStakedEth * DURATION);
        } else {
            erc20StakeInfo storage _stake = userTokenStakeInfo[msg.sender];
            _userStakeDuration = stakeEndTime - _stake.lastStakeTime;
            reward = (_userStakeDuration * _amount * tokenRewardAvailable) / (totalTokenStaked * DURATION);
        }
    }
}
