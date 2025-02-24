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

contract PinjocRouter is Ownable, ReentrancyGuard {

    IMockGTXOrderBook public orderBook;
    mapping(string => address) public orderBookTokenMapping;
    ILendingPoolManager public lendingPoolManager;

    error InvalidAddressParameter();
    error InvalidPlaceOrderParameter();
    error BalanceNotEnough(address token, uint256 balance, uint256 amount);

    event OrderPlaced(
        uint256 orderId,
        address debtToken,
        address collateralToken,
        uint256 amount,
        uint64 rate,
        uint256 maturity,
        string maturityMonth,
        uint16 maturityYear,
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

    function getOrderBookTokenAddress(address _token, string calldata _maturityMonth, uint16 _maturityYear) internal returns (address) {
        string memory _tokenName = string(abi.encodePacked(IERC20Metadata(_token).symbol(), _maturityMonth, _maturityYear));
        if (orderBookTokenMapping[_tokenName] == address(0)) {  
            OrderBookToken _newToken = new OrderBookToken(_token, _maturityMonth, _maturityYear, address(this));
            orderBookTokenMapping[_tokenName] = address(_newToken);
        }
        return orderBookTokenMapping[_tokenName];
    }

    function placeOrder(
        address _debtToken, // lender's token - CA USDC
        address _collateralToken, // borrower's token - CA ETH
        uint256 _amount, // amount of token whether debt token or collateral token - 500K$
        uint64 _rate, // APY percentage (18 decimals), e.g. for 100% pass 1e18 or 100e16, for 5% pass 5e16 - 4%
        uint256 _maturity, // maturity date in unix timestamp - 31 Maret 2025
        string calldata _maturityMonth, // MAR
        uint16 _maturityYear, // 2025
        LendingOrderType _lendingOrderType, // LEND
        bool _isMatchOrder
    ) external nonReentrant {
        if (
            _debtToken == address(0) ||
            _collateralToken == address(0) ||
            _amount == 0 ||
            _rate == 0 ||
            _maturity == 0
        ) revert InvalidPlaceOrderParameter();

        if (_isMatchOrder) {
            if (_lendingOrderType == LendingOrderType.LEND && IERC20(_debtToken).balanceOf(msg.sender) < _amount) {
                revert BalanceNotEnough(_debtToken, IERC20(_debtToken).balanceOf(msg.sender), _amount);
            } else if (_lendingOrderType == LendingOrderType.BORROW && IERC20(_collateralToken).balanceOf(msg.sender) < _amount) {
                revert BalanceNotEnough(_collateralToken, IERC20(_collateralToken).balanceOf(msg.sender), _amount);
            }
        }

        address debtTokenOrderBookAddress = getOrderBookTokenAddress(_debtToken, _maturityMonth, _maturityYear);
        address collateralTokenOrderBookAddress = getOrderBookTokenAddress(_collateralToken, _maturityMonth, _maturityYear);

        (uint256 orderId, Status status) = orderBook.placeLimitOrder(
            debtTokenOrderBookAddress,
            collateralTokenOrderBookAddress,
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
            _matchOrder();
        }
    }

    function _matchOrder() internal nonReentrant {
        // check if there is existing lending pool
        // if it does not exist, then create the lending pool
        // if it does exist, then check the order position type
        
    }

    function cancelOrder(
        uint256 _orderId
    ) external nonReentrant {
        if (_orderId == 0) revert InvalidPlaceOrderParameter();

        orderBook.cancelOrder(msg.sender, _orderId);

        emit OrderCancelled(_orderId, Status.CANCELLED);
    }

}