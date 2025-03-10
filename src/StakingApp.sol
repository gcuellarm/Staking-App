//SPDX-License-Identifier: LGPL-3.0-only

    //1. Staking Token address (we'll need as a parameter the address of the token we'll use to do staking)
    //2. Admin
    //3. Staking fixed amount. Example: 10 tokens 
    //4. Staking reward period

//Version
pragma solidity ^0.8.24;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

//Contract
contract StakingApp is Ownable{

//Variables
    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsePeriod;
    


    struct Transaction{
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => Transaction[]) public transactionHistory;

    //Events
    event changeStakingPeriodEv(uint256 newStakingPeriod_);
    event DepositTokens(address userAddress_, uint256 depositAmount_);
    event WithdrawTokens(address userAddress_, uint256 withdrawAmount_);
    event EtherSent(uint256 amount_);

    
    constructor(address stakingToken_, address owner_, uint256 stakingPeriod_, uint256 fixedStakingAmount_, uint256 rewardPerPeriod_)  Ownable(owner_){
        stakingToken = stakingToken_; 
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    //Functions

    //External functions
    //1. Deposit tokens
    function depositTokens(uint256 amountToDeposit_) external{
        require(amountToDeposit_ == fixedStakingAmount, "Incorrect amount");
        require(userBalance[msg.sender] == 0, "User already deposited");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amountToDeposit_);
        userBalance[msg.sender] += amountToDeposit_;
        elapsePeriod[msg.sender] = block.timestamp;
        recordTransaction(amountToDeposit_, block.timestamp);

        emit DepositTokens(msg.sender, amountToDeposit_);
    }


    //2. Withdraw tokens
    function withdrawTokens() external{

        uint256 userBalance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).transfer(msg.sender, userBalance_);

        recordTransaction(userBalance_, block.timestamp);

        emit WithdrawTokens(msg.sender, userBalance_);
    }


    //3. Claim Rewards
    function claimRewards() external{
        //1. Check Balance (if balance = 0 cannot claim)
        require(userBalance[msg.sender] == fixedStakingAmount,"Not staking");

        //2. Calulate reward amount
//Elapse period: Current point in time - The point in time we started staking
        uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender];
        require(elapsePeriod_ >= stakingPeriod, "Need to wait");

        //3. Update state
        elapsePeriod[msg.sender] = block.timestamp;

        //4. Transfer rewards
        (bool success, ) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

  
    //function feedContract() external payable onlyOwner{}
    receive() external payable onlyOwner{
        emit EtherSent(msg.value);
    }


    //Internal function
    function recordTransaction(uint256 amount_, uint256 timestamp) internal {
        transactionHistory[msg.sender].push(Transaction(amount_, block.timestamp));
    }

    function getTransactionHistory(address user_) external view returns (Transaction[] memory) {
    return transactionHistory[user_];
}

    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner{
        stakingPeriod = newStakingPeriod_;
        emit changeStakingPeriodEv(newStakingPeriod_);
    }



}
