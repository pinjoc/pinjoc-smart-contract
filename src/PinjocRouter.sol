// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IMockGTXOrderBook} from "./interfaces/IMockGTXOrderBook.sol";
import {LendingOrderType, Status} from "./types/Types.sol";
import {OrderBookToken} from "./OrderBookToken.sol";
import {ILendingPoolManager} from "./interfaces/ILendingPoolManager.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {Side} from "./types/Types.sol";

contract PinjocRouter is Ownable, ReentrancyGuard {

    IMockGTXOrderBook public orderBook;
    ILendingPoolManager public lendingPoolManager;
    mapping(string => address) public orderBookTokenMapping;

    error InvalidAddressParameter();
    error InvalidPlaceOrderParameter();
    error BalanceNotEnough(address token, uint256 balance, uint256 amount);
    error LendingPoolNotFound();
    error DelegateCallFailed();

    event OrderPlaced(
        uint256 orderId,
        address debtToken,
        address collateralToken,
        uint256 amount,
        uint256 rate,
        uint256 maturity,
        string maturityMonth,
        uint256 maturityYear,
        LendingOrderType lendingOrderType,
        Status status
    );

    event OrderCancelled(
        uint256 orderId,
        Status status
    );

    constructor(
        address _orderBook,
        address _lendingPoolManager
    ) Ownable(msg.sender) {
        setOrderBook(_orderBook);
        setLendingPoolManager(_lendingPoolManager);
    }

    function setOrderBook(address _orderBook) public onlyOwner {
        if(_orderBook == address(0)) revert InvalidAddressParameter();
        orderBook = IMockGTXOrderBook(_orderBook);
    }

    function setLendingPoolManager(address _lendingPoolManager) public onlyOwner {
        if(_lendingPoolManager == address(0)) revert InvalidAddressParameter();
        lendingPoolManager = ILendingPoolManager(_lendingPoolManager);
    }

    function getOrderBookTokenAddress(address _token, string calldata _maturityMonth, uint256 _maturityYear) internal returns (address) {
        string memory _tokenName = string(abi.encodePacked(IERC20Metadata(_token).symbol(), _maturityMonth, _maturityYear));
        if (orderBookTokenMapping[_tokenName] == address(0)) {  
            OrderBookToken _newToken = new OrderBookToken(_token, _maturityMonth, _maturityYear);
            orderBookTokenMapping[_tokenName] = address(_newToken);
        }
        return orderBookTokenMapping[_tokenName];
    }

    function placeOrder(
        address _debtToken, // lender's token - CA USDC
        address _collateralToken, // borrower's token - CA ETH
        uint256 _amount, // amount of token debt token not collateral token - 500K$
        uint256 _rate, // APY percentage (18 decimals), e.g. for 100% pass 1e18 or 100e16, for 5% pass 5e16 - 4%
        uint256 _maturity, // maturity date in unix timestamp - 31 Maret 2025
        string calldata _maturityMonth, // MAR
        uint256 _maturityYear, // 2025
        LendingOrderType _lendingOrderType, // LEND
        bool _isMatchOrder
    ) external nonReentrant {
        if (
            _debtToken == address(0) ||
            _collateralToken == address(0) ||
            _amount == 0 ||
            _rate == 0
        ) revert InvalidPlaceOrderParameter();

        address debtTokenOB = getOrderBookTokenAddress(_debtToken, _maturityMonth, _maturityYear);
        address collateralTokenOB = getOrderBookTokenAddress(_collateralToken, _maturityMonth, _maturityYear);

        (uint256 orderId, Status status) = orderBook.placeLimitOrder(
            debtTokenOB,
            collateralTokenOB,
            msg.sender,
            _amount,
            _rate,
            _lendingOrderType.convertToSide(),
            _isMatchOrder
        );

        emit OrderPlaced(
            orderId,
            _debtToken,
            _collateralToken,
            _amount,
            _rate,
            _maturity,
            _maturityMonth,
            _maturityYear,
            _lendingOrderType,
            status
        );
        
        if (_isMatchOrder) {
            address lendingPoolAddress = lendingPoolManager.getLendingPool(
                _debtToken,
                _collateralToken,
                _rate,
                _maturityMonth,
                _maturityYear
            );
            if (lendingPoolAddress == address(0)) revert LendingPoolNotFound();

            // Build the data for the delegatecall
            bytes memory data;
            if (_lendingOrderType == LendingOrderType.LEND) {
                // supply(uint256)
                data = abi.encodeWithSelector(
                    ILendingPool.supply.selector,
                    _amount
                );
            } else if (_lendingOrderType == LendingOrderType.BORROW) {
                // borrow(uint256)
                data = abi.encodeWithSelector(
                    ILendingPool.borrow.selector,
                    _amount
                );
            }

            // Perform the delegatecall
            (bool success, bytes memory returnData) = lendingPoolAddress.delegatecall(data);
            if (!success) {
                // Bubble up the revert reason from the called contract
                if (returnData.length > 0) {
                    assembly {
                        revert(add(returnData, 32), mload(returnData))
                    }
                } else {
                    revert DelegateCallFailed();
                }
            }
        }
    }

    function cancelOrder(
        uint256 _orderId
    ) external nonReentrant {
        if (_orderId == 0) revert InvalidPlaceOrderParameter();

        orderBook.cancelOrder(msg.sender, _orderId);

        emit OrderCancelled(_orderId, Status.CANCELLED);
    }

}