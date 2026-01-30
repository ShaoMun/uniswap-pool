// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SimplePool
 * @notice A simple constant product AMM (x * y = k)
 * @dev Based on Uniswap V2 but simplified for learning purposes
 */
contract SimplePool is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address to);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor(IERC20 _token0, IERC20 _token1) ERC20("SimplePool LP", "SPL") {
        require(address(_token0) < address(_token1), "SimplePool: INVALID_TOKEN_ORDER");
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice Add liquidity to the pool
     * @param amount0Desired Amount of token0 to add
     * @param amount1Desired Amount of token1 to add
     * @return amount0 Actual amount of token0 added
     * @return amount1 Actual amount of token1 added
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1, uint256 liquidity)
    {
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            // Initial liquidity provision
            amount0 = amount0Desired;
            amount1 = amount1Desired;
            liquidity = _sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;

            require(liquidity > 0, "SimplePool: INSUFFICIENT_LIQUIDITY_MINTED");

            _mint(address(this), MINIMUM_LIQUIDITY); // Permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            // Calculate optimal amount of token0 to deposit
            uint256 amount1Optimal = (amount0Desired * reserve1) / reserve0;

            if (amount1Optimal <= amount1Desired) {
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                // Calculate optimal amount of token1 to deposit
                uint256 amount0Optimal = (amount1Desired * reserve0) / reserve1;
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }

            liquidity = (amount0 * _totalSupply) / reserve0;
        }

        require(liquidity > 0, "SimplePool: INSUFFICIENT_LIQUIDITY_MINTED");

        // Transfer tokens from sender
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        // Update reserves
        _update(reserve0 + amount0, reserve1 + amount1);

        // Mint LP tokens to sender
        _mint(msg.sender, liquidity);

        emit Mint(msg.sender, amount0, amount1);
    }

    /**
     * @notice Remove liquidity from the pool
     * @param liquidity Amount of LP tokens to burn
     * @return amount0 Amount of token0 returned
     * @return amount1 Amount of token1 returned
     */
    function removeLiquidity(uint256 liquidity)
        external
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        require(liquidity > 0, "SimplePool: INSUFFICIENT_LIQUIDITY_BURNED");

        uint256 _totalSupply = totalSupply();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;

        require(amount0 > 0 && amount1 > 0, "SimplePool: INSUFFICIENT_LIQUIDITY_BURNED");

        // Burn LP tokens
        _burn(msg.sender, liquidity);

        // Transfer tokens to sender
        IERC20(token0).safeTransfer(msg.sender, amount0);
        IERC20(token1).safeTransfer(msg.sender, amount1);

        // Update reserves
        _update(balance0 - amount0, balance1 - amount1);

        emit Burn(msg.sender, amount0, amount1, msg.sender);
    }

    /**
     * @notice Swap tokens using constant product formula
     * @param amount0In Amount of token0 to swap in (0 if swapping token1)
     * @param amount1In Amount of token1 to swap in (0 if swapping token0)
     * @param amount0OutMinimum Minimum amount of token0 to receive (0 if receiving token1)
     * @param amount1OutMinimum Minimum amount of token1 to receive (0 if receiving token0)
     * @param to Address to receive the output tokens
     * @return amount0Out Amount of token0 received
     * @return amount1Out Amount of token1 received
     */
    function swap(
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0OutMinimum,
        uint256 amount1OutMinimum,
        address to
    ) external nonReentrant returns (uint256 amount0Out, uint256 amount1Out) {
        require(amount0In == 0 || amount1In == 0, "SimplePool: ONLY_ONE_INPUT");
        require(amount0Out == 0 || amount1Out == 0, "SimplePool: ONLY_ONE_OUTPUT");

        if (amount0In > 0) {
            // Swapping token0 for token1
            // Uniswap formula: dy = (y * dx * 997) / (x * 1000 + dx * 997)
            uint256 amountInWithFee = (amount0In * 997) / 1000;
            amount1Out = (reserve1 * amountInWithFee) / (reserve0 + amountInWithFee);

            require(amount1Out < reserve1, "SimplePool: INSUFFICIENT_LIQUIDITY");

            reserve0 += amount0In;
            reserve1 -= amount1Out;

            IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0In);
            IERC20(token1).safeTransfer(to, amount1Out);

            require(amount1Out >= amount1OutMinimum, "SimplePool: INSUFFICIENT_OUTPUT_AMOUNT");
        } else {
            // Swapping token1 for token0
            // Uniswap formula: dx = (x * dy * 997) / (y * 1000 + dy * 997)
            uint256 amountInWithFee = (amount1In * 997) / 1000;
            amount0Out = (reserve0 * amountInWithFee) / (reserve1 + amountInWithFee);

            require(amount0Out < reserve0, "SimplePool: INSUFFICIENT_LIQUIDITY");

            reserve1 += amount1In;
            reserve0 -= amount0Out;

            IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1In);
            IERC20(token0).safeTransfer(to, amount0Out);

            require(amount0Out >= amount0OutMinimum, "SimplePool: INSUFFICIENT_OUTPUT_AMOUNT");
        }

        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @notice Get the amount of token1 that would be obtained for a given amount of token0
     * @param amountIn Amount of token0 to swap
     * @return amountOut Amount of token1 that would be received
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "SimplePool: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimplePool: INSUFFICIENT_LIQUIDITY");

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @notice Sync reserves to current balances (emergency function)
     */
    function sync() external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }

    /**
     * @notice Force token balances to match reserves (emergency function)
     */
    function skim(address to) external nonReentrant {
        IERC20(token0).safeTransfer(to, IERC20(token0).balanceOf(address(this)) - reserve0);
        IERC20(token1).safeTransfer(to, IERC20(token1).balanceOf(address(this)) - reserve1);
    }

    function _update(uint256 balance0, uint256 balance1) private {
        require(balance0 <= type(uint256).max && balance1 <= type(uint256).max, "SimplePool: OVERFLOW");
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(balance0, balance1);
    }

    function _sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
