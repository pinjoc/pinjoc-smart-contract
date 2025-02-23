// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {LendingOrderType} from "./types/Types.sol";
import {IPoolManager, PoolKey} from "./interfaces/IPoolManager.sol";
import {IOrderBook} from "./interfaces/IOrderBook.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {OrderBookToken} from "./OrderBookToken.sol";

contract PinjocRouter is Ownable, ReentrancyGuard {

    IPoolManager public poolManager;
    IPoolManager.Pool uninitializedPool = IPoolManager.Pool(0, 0, address(0), address(0), IOrderBook(address(0)));
    mapping(string => address) public orderBookTokenMapping;

    error InvalidAddressParameter();
    error InvalidPlaceOrderParameter();

    constructor(
        address _poolManagerAddress
    ) Ownable(msg.sender) {
        setPoolManager(_poolManagerAddress);
    }

    function setPoolManager(address _poolManagerAddress) public onlyOwner {
        if(_poolManagerAddress == address(0)) revert InvalidAddressParameter();
        poolManager = IPoolManager(_poolManagerAddress);
    }

    function getOrderBookTokenAddress(address _token, string calldata _maturityMonth, uint16 _maturityYear) internal view returns (address) {
        string memory _tokenName = string(abi.encodePacked(IERC20Metadata(_token).symbol(), _maturityMonth, _maturityYear));
        if (orderBookTokenMapping[_tokenName] == address(0)) {
            orderBookTokenMapping[_tokenName] = new OrderBookToken(_token, _maturityMonth, _maturityYear); // TODO-WILL: UNFINISHED, WAIT TILL ARDI'S COMMIT
        }
        return address(orderBookTokenMapping[_tokenName]);
    }

    function getExistingPool(address _debtToken, address _collateralToken, string calldata _maturityMonth, uint16 _maturityYear) public view returns (IPoolManager.Pool memory) {
        address debtTokenOrderBookAddress = getOrderBookTokenAddress(_debtToken, _maturityMonth, _maturityYear);
        address collateralTokenOrderBookAddress = getOrderBookTokenAddress(_collateralToken, _maturityMonth, _maturityYear);

        PoolKey memory poolKey = PoolKey(debtTokenOrderBookAddress, collateralTokenOrderBookAddress);
        IPoolManager.Pool memory pool = poolManager.getPool(poolKey);
        if (pool == uninitializedPool) {
            poolManager.createPool();
            pool = poolManager.getPool(poolKey);
        }
        
        return pool;
    }

    // ERC20: SYMBOL, NAME
    // SYMBOL: ETH
    // NAME: ETHEREUM <== ETHEREUM2.0

    // SOLUSI 1: PARAMETER MENGGUNAKAN CA USDC
    // + HARUS BUAT MAPPING UNTUK MENGUBAH CA USDC KE USDCMAR2025
    // + KELEMAHANYA ADALAH TAMBAH VARIABLE DI ON CHAIN UNTUK MAPPING

    function placeOrder(
        address _debtToken, // lender's token - CA USDC
        address _collateralToken, // borrower's token - CA ETH
        uint256 _amount, // amount of token whether debt token or collateral token - 500K$
        uint256 _rate, // APY percentage (18 decimals), e.g. for 100% pass 1e18 or 100e16, for 5% pass 5e16 - 4%
        uint256 _maturity, // maturity date in unix timestamp - 31 Maret 2025
        string calldata _maturityMonth, // MAR
        uint16 _maturityYear, // 2025
        LendingOrderType _lendingOrderType // LEND
    ) external nonReentrant {
        if (
            _debtToken == address(0) ||
            _collateralToken == address(0) ||
            _amount == 0 ||
            _rate == 0 ||
            _maturity == 0
        ) revert InvalidPlaceOrderParameter();

        IPoolManager.Pool memory pool = getExistingPool(_debtToken, _collateralToken, _maturityMonth, _maturityYear);



        // if it does not exist, then create the order first
        // check if there is existing order
        // if it does not exist, then create order position
        // if it does exists, then check the order position type
        // if the order position type is the opposite of the current order type, then match the order
        // if the order position type is the same as the current order type, then add the order to the order position
    }

    function _matchOrder() internal nonReentrant {
        // create lending pool
    }

    function cancelOrder() external nonReentrant {
        // deduct order position based on the queue order position
    }
    

}