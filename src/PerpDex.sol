// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IIndexOracle.sol";
import "./interfaces/IMarginVault.sol";

contract PerpDex {

    enum Side {
        LONG,
        SHORT
    }

    struct Position {
        uint256 size;
        uint256 entryPrice;
        uint256 margin;
        Side side;
        bool open;
    }

    struct Market {
        bytes32 indexId;
        bool active;
        uint256 maxLeverage;
    }

    address public owner;

    IIndexOracle public indexOracle;
    IMarginVault public marginVault;

    mapping(bytes32 => Market) public markets;

    mapping(
        bytes32 => mapping(address => Position)
    ) public positions;

    event MarketCreated(
        bytes32 indexed marketId,
        bytes32 indexed indexId
    );

    event PositionOpened(
        bytes32 indexed marketId,
        address indexed trader,
        uint256 size,
        uint256 entryPrice,
        Side side
    );

    event PositionClosed(
        bytes32 indexed marketId,
        address indexed trader,
        uint256 exitPrice,
        int256 pnl
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor(
        address _indexOracle,
        address _marginVault
    ) {
        owner = msg.sender;

        indexOracle =
            IIndexOracle(_indexOracle);

        marginVault =
            IMarginVault(_marginVault);
    }

    function createMarket(
        bytes32 marketId,
        bytes32 indexId,
        uint256 maxLeverage
    ) external onlyOwner {

        require(!markets[marketId].active, "MARKET_EXISTS");
        require(maxLeverage > 0, "INVALID_LEVERAGE");

        markets[marketId] = Market({
            indexId: indexId,
            active: true,
            maxLeverage: maxLeverage
        });

        emit MarketCreated(
            marketId,
            indexId
        );
    }

    function openPosition(
        bytes32 marketId,
        uint256 size,
        uint256 margin,
        Side side
    ) external {

        Market memory market =
            markets[marketId];

        require(market.active, "MARKET_INACTIVE");

        Position storage position =
            positions[marketId][msg.sender];

        require(!position.open, "POSITION_EXISTS");
        require(size > 0, "INVALID_SIZE");
        require(margin > 0, "INVALID_MARGIN");

        uint256 price =
            indexOracle.getIndexPrice(
                market.indexId
            );

        require(
            size <= margin * market.maxLeverage,
            "LEVERAGE_EXCEEDED"
        );

        marginVault.lockMargin(
            msg.sender,
            margin
        );

        positions[marketId][msg.sender] =
            Position({
                size: size,
                entryPrice: price,
                margin: margin,
                side: side,
                open: true
            });

        emit PositionOpened(
            marketId,
            msg.sender,
            size,
            price,
            side
        );
    }

    function closePosition(
        bytes32 marketId
    ) external {

        Position storage position =
            positions[marketId][msg.sender];

        require(position.open, "NO_POSITION");

        uint256 exitPrice =
            indexOracle.getIndexPrice(
                markets[marketId].indexId
            );

        int256 pnl =
            calculatePnl(
                position,
                exitPrice
            );

        marginVault.unlockMargin(
            msg.sender,
            position.margin
        );

        position.open = false;

        emit PositionClosed(
            marketId,
            msg.sender,
            exitPrice,
            pnl
        );
    }

    function calculatePnl(
        Position memory position,
        uint256 currentPrice
    )
        public
        pure
        returns (int256)
    {
        if (position.side == Side.LONG) {

            if (currentPrice >= position.entryPrice) {

                return int256(
                    (
                        position.size *
                        (currentPrice - position.entryPrice)
                    )
                    / position.entryPrice
                );

            } else {

                return -int256(
                    (
                        position.size *
                        (position.entryPrice - currentPrice)
                    )
                    / position.entryPrice
                );
            }

        } else {

            if (currentPrice <= position.entryPrice) {

                return int256(
                    (
                        position.size *
                        (position.entryPrice - currentPrice)
                    )
                    / position.entryPrice
                );

            } else {

                return -int256(
                    (
                        position.size *
                        (currentPrice - position.entryPrice)
                    )
                    / position.entryPrice
                );
            }
        }
    }

    function getPosition(
        bytes32 marketId,
        address trader
    )
        external
        view
        returns (Position memory)
    {
        return positions[marketId][trader];
    }
}
