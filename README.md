
# 💸💻 Staking App
This project is a decentralized staking application written in Solidity, utilizing the Foundry framework for development and testing. The application allows users to deposit tokens, stake them for a fixed period, claim rewards, and withdraw their staked tokens. The system uses ERC20 tokens for staking, and rewards are distributed at specified intervals.

The repository also includes tests for both the StakingToken and StakingApp contracts to ensure they function as expected.


## 📃 Features
- **Staking**: Users can deposit a fixed amount of tokens for staking.
- **Rewards**: Users can claim rewards based on the staking duration.
- **Admin Control**: The admin can change the staking period.
- **ERC20 Support**: The app works with any ERC20 token for staking.

## ⚙️ Components
1. **StakingToken**: This is an ERC20 token used for staking. It includes a minting function, allowing users to mint tokens directly to their wallets.
2. **StakingApp**: The core staking contract that handles deposits, withdrawals, rewards, and staking periods. It also allows the contract owner to modify the staking period.
3. **StakingTokenTest**: A test contract for the StakingToken that ensures the mint function works correctly.
4. **StakingAppTest**: A test contract for the StakingApp that validates the functionality of staking, withdrawing, claiming rewards, and more.

# 🔎 App Details
## 💠 Staking Token Contract
The StakingToken contract is an ERC20 token contract that allows minting new tokens to the sender's address.

### Functions
- **constructor**: Initializes the token with a name and symbol.
- **mint(uint256 amount_)**: Mints the specified amount of tokens to the sender's address.

### Code
```solidity
//SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.24;
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20{
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(uint256 amount_) external {
        _mint(msg.sender, amount_);
    }
}
```

## 📍 Staking App Contract
The StakingApp contract allows users to stake ERC20 tokens, claim rewards, and withdraw staked tokens. It also provides the functionality for an admin to modify the staking period.  

### Functions
- **constructor**: Initializes the contract with the staking token address, owner address, staking period, fixed staking amount, and reward per staking period.
- **depositTokens(uint256 amountToDeposit_)**: Allows users to deposit a fixed amount of tokens.
- **withdrawTokens()**: Allows users to withdraw their staked tokens.
- **claimRewards()**: Allows users to claim rewards after staking for the specified period.
- **changeStakingPeriod(uint256 newStakingPeriod_)**: Allows the owner to change the staking period.

### Code
```solidity
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {

    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsePeriod;

    event changeStakingPeriodEv(uint256 newStakingPeriod_);
    event DepositTokens(address userAddress_, uint256 depositAmount_);
    event WithdarawTokens(address userAddress_, uint256 withdrawAmount_);
    event EtherSent(uint256 amount_);

    constructor(address stakingToken_, address owner_, uint256 stakingPeriod_, uint256 fixedStakingAmount_, uint256 rewardPerPeriod_)  Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    // Deposit tokens
    function depositTokens(uint256 amountToDeposit_) external {
        require(amountToDeposit_ == fixedStakingAmount, "Incorrect amount");
        require(userBalance[msg.sender] == 0, "User already deposited");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amountToDeposit_);
        userBalance[msg.sender] += amountToDeposit_;
        elapsePeriod[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, amountToDeposit_);
    }

    // Withdraw tokens
    function withdrawTokens() external {
        uint256 userBalance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).transfer(msg.sender, userBalance_);

        emit WithdarawTokens(msg.sender, userBalance_);
    }

    // Claim rewards
    function claimRewards() external {
        require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");

        uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender];
        require(elapsePeriod_ >= stakingPeriod, "Need to wait");

        elapsePeriod[msg.sender] = block.timestamp;

        (bool success, ) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

    // Receive ether to fund the contract (only owner)
    receive() external payable onlyOwner {
        emit EtherSent(msg.value);
    }

    // Change staking period (only owner)
    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner {
        stakingPeriod = newStakingPeriod_;
        emit changeStakingPeriodEv(newStakingPeriod_);
    }
}
```

## 🚧💠 StakingToken Test (Using Foundry)
This repository contains a test for the StakingToken contract, written in Solidity. The test is created using the Foundry testing framework. The test ensures that the mint function in the StakingToken contract works as expected by verifying that tokens are minted correctly to the user's address.

### Code
```solidity
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingTokenTest is Test {

    StakingToken stakingToken;
    string name_ = "Staking Token";
    string symbol_ = "STK";
    address randomUser = vm.addr(1);

    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
    }

    function testStakingTokenMintsCorrectly() public {
        vm.startPrank(randomUser);
        uint256 amount_ = 1 ether;

        // Token balance before minting
        uint256 balanceBefore_ = IERC20(address(stakingToken)).balanceOf(randomUser);
        stakingToken.mint(amount_);

        // Token balance after minting
        uint256 balanceAfter_ = IERC20(address(stakingToken)).balanceOf(randomUser);

        // Ensure that the minted amount matches the balance increase
        assert(balanceAfter_ - balanceBefore_ == amount_);
        vm.stopPrank();
    }
}
```
### ✏️ Test descriptions
1. **testStakingTokenMintsCorrectly**:
- **Goal**: Verify that the *mint* function allows tokens to be minted correctly and that the user's balance increases by the expected amount.
- **Description**: In this test, a user (using *vm.addr(1)*) mints tokens through the *mint* function. It then checks that the user's balance increased by the expected amount (1 ether in this case).

## 🚧📍 StakingApp Test (Using Foundry)
This repository also contains a comprehensive test for the StakingApp contract, which includes tests for the functionalities of staking tokens, withdrawing tokens, claiming rewards, and changing the staking period.
```solidity
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {
    StakingToken stakingToken;
    StakingApp stakingApp;

    string name_ = "Staking Token";
    string symbol_ = "STK";
    address owner_ = vm.addr(1);
    uint256 stakingPeriod_ = 100000000000000;
    uint256 fixedStakingAmount_ = 10;
    uint256 rewardPerPeriod_ = 1 ether;

    address randomUser = vm.addr(2);

    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    // Test to ensure that the staking token is deployed correctly
    function testStakingTokenCorrectlyDeployed() external {
        assert(address(stakingToken) != address(0));
    }

    // Test to ensure that the staking app is deployed correctly
    function testStakingAppCorrectlyDeployed() external {
        assert(address(stakingApp) != address(0));
    }

    // Test for incorrect staking period change (not the owner)
    function testShouldRevertIfNotOwner() external {
        uint256 newStakingPeriod_ = 1;
        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
    }

    // Test to successfully change staking period
    function testShouldChangeStakingPeriod() external {
        vm.startPrank(owner_);
        uint256 newStakingPeriod_ = 1;

        uint256 stakingPeriodBefore = stakingApp.stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod_);
        uint256 stakingPeriodAfter = stakingApp.stakingPeriod();

        assert(stakingPeriodBefore != newStakingPeriod_);
        assert(stakingPeriodAfter == newStakingPeriod_);
        vm.stopPrank();
    }

    // Test to see if contract can receive Ether correctly
    function testContractReceivesEtherCorrectly() external {
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
}
```
### ✏️ Test descriptions
1. **testStakingTokenCorrectlyDeployed**:
- **Goal**: Verify that the StakingToken contract is deployed correctly (its address should not be zero).
- **Description**: This test simply checks that the StakingToken contract's address is not zero, indicating the contract was deployed successfully.
2. **testStakingAppCorrectlyDeployed**:
- **Goal**: Verify that the StakingApp contract is deployed correctly (its address should not be zero).
- **Description**: This test verifies that the StakingApp contract is deployed correctly and that its address is not zero.
3. **testShouldRevertIfNotOwner**:
- **Goal**: Ensure that only the owner can change the staking period.
- **Description**: If a non-owner tries to change the staking period, the transaction should revert. This test ensures that the revert is correctly triggered when a non-owner attempts the action.
4. **testShouldChangeStakingPeriod**:
- **Goal**: Verify that the owner can successfully change the staking period.
- **Description**: This test simulates an owner changing the staking period. It verifies that the staking period is updated correctly in the contract.
5. **testContractReceivesEtherCorrectly**:
- **Goal**: Validate that the contract can receive ether correctly.
- **Description**: This test simulates a transfer of ether to the StakingApp contract and verifies that the contract's balance increases by the correct amount.
6. **testIncorrectAmountShouldRevert**:
- **Goal**: Verify that the contract rejects deposits with incorrect amounts (i.e., amounts that don't match the fixed staking amount).
- **Description**: If a user attempts to deposit an amount other than the fixed staking amount, the transaction should revert with an error.
7. **testDepositTokensCorrectly**:
- **Goal**: Ensure that users can deposit the correct required amount of tokens.
- **Description**: This test verifies that a user can correctly deposit tokens into the contract and that the contract updates the user's balance and staking time correctly.
8. **testUserCannotDepositMoreThanOnce**:
- **Goal**: Ensure that a user cannot make multiple deposits.
- **Description**: After a successful deposit, if the same user attempts to deposit more tokens, the transaction should revert.
9. **testCanOnlyWithdraw0WithoutDeposit**:
- **Goal**: Verify that a user cannot withdraw tokens if they have not made any deposit.
- **Description**: If a user has not deposited any tokens, their balance will be zero, and they will not be able to withdraw tokens.
10. **testWithdrawTokensCorrectly**:
- **Goal**: Validate that a user can correctly withdraw tokens they have deposited.
- **Description**: This test ensures that token withdrawal works as expected and that both the user's and the contract's balances are updated correctly.
11. **testCannotClaimIfNotStaking**:
- **Goal**: Ensure that a user cannot claim rewards if they are not staking
- **Description**: If a user has not deposited tokens, they should not be able to claim rewards.
12. **testCannotClaimIfNotElapsedTime**:
- **Goal**: Verify that a user cannot claim rewards if the required staking time has not passed.
- **Description**: This test ensures that the user has to wait until the required staking time has passed before they can claim rewards.
13. **testShouldRevertIfNoEther**:
- **Goal**: Verify that a user cannot claim rewards if there is no ether available in the contract.
- **Description**: If the contract doesn't have enough ether to pay out rewards, the transaction should revert.
14. **testCanClaimRewardsCorrectly**:
- **Goal**: Ensure that a user can claim rewards correctly after completing the staking period.
- **Description**: This test ensures that after the staking period has passed, the user can claim the correct amount of ether as a reward.
15. **testCannotClaimRewardsTwice**:
- **Goal**: Ensure that a user cannot claim rewards more than once before the required waiting period.
- **Description**: After claiming rewards once, the user should not be able to claim again until the staking period has fully elapsed.




## 🛠️ Setup and Installation
### Prerequisites
- **Foundry**: Ensure that you have Foundry installed. You can install it using the following command:
```curl -L https://foundry.paradigm.xyz | bash```
- **Visual Studio Code**: Ensure that you have Visual Studio Code (VS Code) installed.

### Setups to run the app
1. **Clone the Repository**:
```
git clone <your-repository-url>
cd <your-project-directory> 
```
2. **Install OpenZeppelin Contracts**: In your project directory, run the following command to install OpenZeppelin contracts:
```
forge install OpenZeppelin/openzeppelin-contracts
```

3. **Compile the Contracts**: Use Foundry's forge to compile the contracts:
```
forge build
```
4. **Deploy the Contracts**:You can deploy the contracts using the following command (make sure to configure your deployment settings):
```
forge deploy
```
    
## Contributing

Feel free to open issues or submit pull requests if you want to contribute improvements or bug fixes.




## License

This project is licensed under the LGPL-3.0-only License.


