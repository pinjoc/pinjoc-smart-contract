// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {MockGTXOrderBook} from "./mocks/MockGTXOrderBook.sol";
import {LendingOrderType, Status} from "./types/Types.sol";
import {OrderBookToken} from "./OrderBookToken.sol";
import {IMockGTXOrderBook} from "./interfaces/IMockGTXOrderBook.sol";
import {ILendingPoolManager} from "./interfaces/ILendingPoolManager.sol";
import {ILendingPool} from "./interfaces/ILendingPool.sol";
import {Uint256Library, Side} from "./types/Types.sol";

using Uint256Library for uint256;

contract PinjocRouter is Ownable, ReentrancyGuard {
    ILendingPoolManager public lendingPoolManager;
    mapping(string => address) public orderBookTokenMapping;
    mapping(string => address) public orderBookMapping;

    error InvalidAddressParameter();
    error InvalidPlaceOrderParameter();
    error BalanceNotEnough(address token, uint256 balance, uint256 amount);
    error OrderBookNotFound();
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

    event OrderCancelled(uint256 orderId, Status status);

    constructor(address _lendingPoolManager) Ownable(msg.sender) {
        setLendingPoolManager(_lendingPoolManager);
    }

    function setLendingPoolManager(
        address _lendingPoolManager
    ) public onlyOwner {
        if (_lendingPoolManager == address(0)) revert InvalidAddressParameter();
        lendingPoolManager = ILendingPoolManager(_lendingPoolManager);
    }

    function createOrderBook(
        address _debtToken,
        address _collateralToken,
        string calldata _maturityMonth,
        uint256 _maturityYear
    ) external onlyOwner {
        if (_debtToken == address(0) || _collateralToken == address(0))
            revert InvalidAddressParameter();
        string memory debtTokenOBSymbol = getOrderBookSymbol(
            _debtToken,
            _maturityMonth,
            _maturityYear
        );

        string memory collateralTokenOBSymbol = getOrderBookSymbol(
            _collateralToken,
            _maturityMonth,
            _maturityYear
        );
        orderBookMapping[
            string(abi.encodePacked(debtTokenOBSymbol, collateralTokenOBSymbol))
        ] = address(new MockGTXOrderBook(_debtToken, _collateralToken));
    }

    function getOrderBookAddress(
        address _debtToken,
        address _collateralToken,
        string calldata _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (address) {
        return
            orderBookMapping[
                string(
                    abi.encodePacked(
                        getOrderBookSymbol(
                            _debtToken,
                            _maturityMonth,
                            _maturityYear
                        ),
                        getOrderBookSymbol(
                            _collateralToken,
                            _maturityMonth,
                            _maturityYear
                        )
                    )
                )
            ];
    }

    function getOrderBookSymbol(
        address _token,
        string calldata _maturityMonth,
        uint256 _maturityYear
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    IERC20Metadata(_token).symbol(),
                    _maturityMonth,
                    _maturityYear.toString()
                )
            );
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

        address orderBookAddr = getOrderBookAddress(
            _debtToken,
            _collateralToken,
            _maturityMonth,
            _maturityYear
        );
        if (orderBookAddr == address(0)) revert OrderBookNotFound();
        IMockGTXOrderBook orderBook = IMockGTXOrderBook(orderBookAddr);

        (uint256 orderId, Status status) = orderBook.placeLimitOrder(
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

            if (_lendingOrderType == LendingOrderType.LEND) {
                require(
                    IERC20(_debtToken).transferFrom(
                        msg.sender,
                        address(this),
                        _amount
                    ),
                    "Transfer failed"
                );
                IERC20(_debtToken).approve(lendingPoolAddress, _amount);
                ILendingPool(lendingPoolAddress).supply(msg.sender, _amount);
            } else if (_lendingOrderType == LendingOrderType.BORROW) {
                ILendingPool(lendingPoolAddress).borrow(msg.sender, _amount);
            }
        }
    }

    function cancelOrder(
        address _debtToken,
        address _collateralToken,
        string calldata _maturityMonth,
        uint256 _maturityYear,
        uint256 _orderId
    ) external nonReentrant {
        if (_orderId == 0) revert InvalidPlaceOrderParameter();

        address orderBookAddr = getOrderBookAddress(
            _debtToken,
            _collateralToken,
            _maturityMonth,
            _maturityYear
        );
        if (orderBookAddr == address(0)) revert OrderBookNotFound();
        IMockGTXOrderBook orderBook = IMockGTXOrderBook(orderBookAddr);
        orderBook.cancelOrder(msg.sender, _orderId);

        emit OrderCancelled(_orderId, Status.CANCELLED);
    }
}
