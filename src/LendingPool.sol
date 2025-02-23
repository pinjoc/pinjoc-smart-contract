// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ETHUSDOracle} from "./ETHUSDOracle.sol";

// References using morpho: https://github.com/morpho-org/morpho-blue/blob/main/src/Morpho.sol
// Accrue Interest = Utilization Rate * APY Supply

interface IOracle {
    function getPrice() external view returns (uint256);
}

contract LendingPool is Ownable, ReentrancyGuard {

    // Errors
    error InvalidAddressParameter();
    error ZeroAmount();
    error InsufficientLiquidity();
    error InsufficientShares();
    error InsufficientCollateral();
    error LTVExceedAmount();
    error BorrowRateExceedAmount();
    error FlashLoanFailed();

    // Events
    event Supply(address user, uint256 amount, uint256 shares);
    event Borrow(address user, uint256 amount, uint256 shares);
    event Withdraw(address user, uint256 amount, uint256 shares);
    event SupplyCollateral(address user, uint256 amount);
    event WithdrawCollateral(address user, uint256 amount);
    event Repay(address user, uint256 amount, uint256 shares);

    address public debtToken; // USDC
    address public collateralToken; // ETH
    address public oracle; // USDC-ETH Oracle

    // Supply
    uint256 public totalSupplyAssets;
    uint256 public totalSupplyShares;
    mapping(address => uint256) public userSupplyShares;

    // Borrow
    uint256 public totalBorrowAssets;
    uint256 public totalBorrowShares;
    mapping(address => uint256) public userBorrowShares;
    mapping(address => uint256) public userCollaterals;

    // Interest Calculation
    uint256 public lastAccrued = block.timestamp; // assumpt this contract is deployed after anyone doing supply
    uint256 public borrowRate; // 18 decimals: 1e17 = 10% APY

    // Collateral Calculation
    uint256 public ltv; // 70% Loan to Value (70% in 18 decimals)

    constructor(address _debtToken, address _collateralToken, address _oracle, uint256 _ltv, uint256 _borrowRate) {
        if (_debtToken == address(0) || _collateralToken == address(0) || _oracle == address(0)) revert InvalidAddressParameter();
        if (_ltv > 1e18) revert LTVExceedAmount();
        if (_borrowRate > 1e18) revert BorrowRateExceedAmount();

        debtToken = _debtToken;
        collateralToken = _collateralToken;
        oracle = _oracle;
        ltv = _ltv;
        borrowRate = _borrowRate;
    }

    function supply(uint256 amount) public nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (IERC20(debtToken).balanceOf(msg.sender) < amount) revert InsufficientLiquidity();
        _accrueInterest();

        uint256 shares = 0;
        if (totalSupplyShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupplyShares) / totalSupplyAssets;
        }

        userSupplyShares[msg.sender] += shares;
        totalSupplyShares += shares;
        totalSupplyAssets += amount;

        IERC20(debtToken).transferFrom(msg.sender, address(this), amount);

        emit Supply(msg.sender, amount, shares);
    }

    function borrow(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (IERC20(debtToken).balanceOf(address(this)) < amount) revert InsufficientLiquidity();
        _accrueInterest();

        uint256 shares = 0;
        if (totalBorrowShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalBorrowShares) / totalBorrowAssets;
        }

        userBorrowShares[msg.sender] += shares;
        totalBorrowShares += shares;
        totalBorrowAssets += amount;

        _isHealthy(msg.sender);

        IERC20(debtToken).transfer(msg.sender, amount);

        emit Borrow(msg.sender, amount, shares);
    }

    function withdraw(uint256 shares) external nonReentrant {
        if (shares == 0) revert ZeroAmount();
        if (userSupplyShares[msg.sender] < shares) revert InsufficientShares();
        _accrueInterest();

        // this calculates automatically with the interest
        uint256 amount = (shares * totalSupplyAssets) / totalSupplyShares;

        if (IERC20(debtToken).balanceOf(address(this)) < amount) revert InsufficientLiquidity();

        userSupplyShares[msg.sender] -= shares;
        totalSupplyShares -= shares;
        totalSupplyAssets -= amount;

        IERC20(debtToken).transfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount, shares);
    }

    function supplyCollateral(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (IERC20(collateralToken).balanceOf(msg.sender) < amount) revert InsufficientLiquidity();
        _accrueInterest();

        userCollaterals[msg.sender] += amount;

        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);

        emit SupplyCollateral(msg.sender, amount);
    }

    function withdrawCollateral(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (userCollaterals[msg.sender] < amount) revert InsufficientShares();
        _accrueInterest();

        userCollaterals[msg.sender] -= amount;

        _isHealthy(msg.sender);

        IERC20(collateralToken).transfer(msg.sender, amount);

        emit WithdrawCollateral(msg.sender, amount);
    }

    function repay(uint256 shares) external nonReentrant {
        // could repay partially or fully
        if (shares == 0) revert ZeroAmount();
        _accrueInterest();
        
        uint256 borrowAmount = (shares * totalBorrowAssets) / totalBorrowShares;

        userBorrowShares[msg.sender] -= shares;
        totalBorrowShares -= shares;
        totalBorrowAssets -= borrowAmount;

        IERC20(debtToken).transferFrom(msg.sender, address(this), borrowAmount);

        emit Repay(msg.sender, borrowAmount, shares);
    }

    function flashLoan(address token, uint256 amount, bytes calldata data) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        IERC20(token).transfer(msg.sender, amount);

        (bool success, ) = address(msg.sender).call(data);
        if (!success) revert FlashLoanFailed();

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit FlashLoan(msg.sender, token, amount);
    }

    function accrueInterest() external {
        _accrueInterest();
    }

    function _accrueInterest() internal {
        uint256 interestPerYear = totalBorrowAssets * borrowRate / 1e18;
        uint256 timePassed = block.timestamp - lastAccrued;

        uint256 interest = (interestPerYear * timePassed) / 365 days;

        totalSupplyAssets += interest;
        totalBorrowAssets += interest;
        lastAccrued = block.timestamp;
    }

    function _isHealthy(address user) internal view {
        uint256 collateralPrice = IOracle(oracle).getPrice();
        uint256 collateralDecimals = 10 ** IERC20Metadata(collateralToken).decimals();

        uint256 borrowedValue = userBorrowShares[user] * totalBorrowAssets / totalBorrowShares;
        uint256 collateralValue = userCollaterals[user] * collateralPrice / collateralDecimals;
        uint256 maxBorrowValue = collateralValue * ltv / 1e18;

        if (borrowedValue > maxBorrowValue) revert InsufficientCollateral();
    }

}