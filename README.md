# PerpDex

### One position for the whole thesis.

PerpDex is an onchain perpetual protocol built around **fixed-weight market indexes**.

Instead of trading every asset individually, PerpDex lets users express an entire market thesis through a single perpetual position.

```text
LONG AI20
SHORT TECH100
LONG RWA10
```

One position.
One thesis.
Multiple assets.

---

## Overview

PerpDex bundles multiple assets into a single index with predefined weights.

Example:

```text
AI20

NVDA    25%
MSFT    25%
GOOGL   20%
AMD     15%
AMZN    15%
```

Rather than opening five separate positions, a trader can simply trade:

```text
LONG AI20
```

The position tracks the performance of the entire basket.

---

## The Idea

Traditional trading requires managing multiple positions to express a single market view.

```text
LONG NVDA
LONG MSFT
LONG GOOGL
LONG AMD
LONG AMZN
```

PerpDex compresses that thesis into one position:

```text
LONG AI20
```

The index maintains its predefined composition and weights.

---

## Fixed-Weight Index

Each index consists of a basket of supported assets.

Weights are represented in basis points.

```text
10000 = 100%
```

Example:

```text
NVDA    2500
MSFT    2500
GOOGL   2000
AMD     1500
AMZN    1500
```

Total:

```text
10000 = 100%
```

The index price is calculated as:

```text
Index Price = Σ(Asset Price × Weight)
```

For example:

```text
NVDA  × 25%
MSFT  × 25%
GOOGL × 20%
AMD   × 15%
AMZN  × 15%
```

---

## Perpetual Trading

PerpDex turns indexes into perpetual markets.

Each market supports:

* Long positions
* Short positions
* Margin
* Leverage
* Funding
* Liquidation
* Onchain settlement

Example:

```text
AI20

Index Price: $1,000

Position:
LONG

Margin:
$1,000

Leverage:
5x

Notional:
$5,000
```

If the index increases by 10%:

```text
PnL = +$500
```

If the index decreases by 10%:

```text
PnL = -$500
```

---

## Position Model

A position contains:

```text
Trader
Index
Direction
Notional
Entry Price
Margin
```

Conceptually:

```solidity
struct Position {
    address trader;
    uint256 indexId;
    int256 notional;
    uint256 entryPrice;
    uint256 margin;
    bool open;
}
```

Positive notional:

```text
LONG
```

Negative notional:

```text
SHORT
```

---

## PnL

For a long position:

```text
PnL =
Notional ×
(Current Price - Entry Price)
÷ Entry Price
```

For a short position:

```text
PnL =
Notional ×
(Entry Price - Current Price)
÷ Entry Price
```

The final implementation uses fixed-point arithmetic to handle precision and rounding.

---

## Architecture

```text
                         ┌───────────────┐
                         │    Trader     │
                         └───────┬───────┘
                                 │
                                 ▼
                       ┌──────────────────┐
                       │     PerpDex      │
                       │  Trading Engine  │
                       └────────┬─────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
      ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
      │    Index     │  │    Margin    │  │   Funding    │
      │   Registry   │  │     Vault    │  │    Engine    │
      └──────┬───────┘  └──────────────┘  └──────────────┘
             │
             ▼
      ┌──────────────┐
      │ Index Oracle │
      └──────┬───────┘
             │
      ┌──────┼──────┬──────┬──────┐
      ▼      ▼      ▼      ▼      ▼
     Asset  Asset  Asset  Asset  Asset
```

---

## Smart Contracts

### `PerpDex.sol`

Main trading engine.

Responsible for:

* Opening positions
* Closing positions
* Position accounting
* PnL calculation
* Margin checks
* Liquidation logic

---

### `IndexRegistry.sol`

Stores index definitions and their components.

Example:

```text
AI20

NVDA  → 25%
MSFT  → 25%
GOOGL → 20%
AMD   → 15%
AMZN  → 15%
```

---

### `IndexOracle.sol`

Calculates the live index price from the underlying asset prices.

```text
Asset Oracle
      ↓
Asset Prices
      ↓
IndexOracle
      ↓
Weighted Index Price
      ↓
PerpDex
```

---

### `MarginVault.sol`

Handles trader collateral and margin accounting.

The production version should use an approved ERC-20 collateral asset such as a supported stablecoin.

---

### `FundingRate.sol`

Handles periodic funding between long and short positions.

Funding is designed to help keep the perpetual market aligned with the underlying index.

---

## Oracle

Reliable pricing is critical to PerpDex.

The production architecture should use a robust oracle system with:

* Freshness checks
* Heartbeat validation
* Price deviation limits
* Stale-price protection
* Decimal normalization
* Circuit breakers

Conceptually:

```text
Underlying Assets
       ↓
 Price Oracle
       ↓
 Index Oracle
       ↓
 Index Price
       ↓
 PerpDex
```

---

## Liquidation

A position becomes eligible for liquidation when its equity falls below the required maintenance margin.

```text
Equity =
Margin + Unrealized PnL
```

Liquidation condition:

```text
Equity < Maintenance Margin
```

A production implementation should additionally account for:

* Funding
* Trading fees
* Liquidation penalties
* Oracle risk
* Position limits
* Maximum leverage
* Insurance fund

---

## Robinhood Chain

PerpDex is designed for deployment on **Robinhood Chain**, an EVM-compatible network.

### Mainnet

```text
Network: Robinhood Chain
Chain ID: 4663
Native Gas: ETH
```

### Testnet

```text
Network: Robinhood Chain Testnet
Chain ID: 46630
Native Gas: ETH
```

PerpDex should be developed and tested on Robinhood Chain Testnet before any production deployment.

---

## Repository Structure

```text
perpdex/
│
├── README.md
├── LICENSE
├── foundry.toml
├── remappings.txt
├── .env.example
│
├── src/
│   ├── PerpDex.sol
│   ├── IndexRegistry.sol
│   ├── IndexOracle.sol
│   ├── MarginVault.sol
│   ├── FundingRate.sol
│   │
│   └── interfaces/
│       ├── IPriceOracle.sol
│       └── IIndexOracle.sol
│
├── script/
│   ├── Deploy.s.sol
│   ├── DeployIndex.s.sol
│   └── ConfigureOracle.s.sol
│
└── test/
    ├── PerpDex.t.sol
    ├── IndexRegistry.t.sol
    ├── IndexOracle.t.sol
    └── PositionManager.t.sol
```

---

## Development

PerpDex uses Foundry for smart-contract development.

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/perpdex.git
cd perpdex
```

Install dependencies:

```bash
forge install
```

Build:

```bash
forge build
```

Run tests:

```bash
forge test
```

---

## Environment

Create an environment file:

```bash
cp .env.example .env
```

Example:

```env
PRIVATE_KEY=0xYOUR_PRIVATE_KEY

RH_RPC_URL=https://rpc.mainnet.chain.robinhood.com

RH_TESTNET_RPC_URL=https://rpc.testnet.chain.robinhood.com
```

Never commit `.env` to the repository.

---

## Deployment

Deploy to Robinhood Chain Testnet:

```bash
forge script script/Deploy.s.sol \
  --rpc-url $RH_TESTNET_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

After deployment, configure the index registry and oracle before enabling trading.

---

## Example Indexes

PerpDex can support different market theses.

```text
TECH100
AI20
CRYPTO10
RWA10
MEME20
```

Example:

```text
RWA10

COIN_A    30%
COIN_B    25%
COIN_C    20%
COIN_D    15%
COIN_E    10%
```

The exact assets and weights are determined by the index configuration.

---

## Roadmap

### Phase 01 — Core

* Fixed-weight indexes
* Index registry
* Oracle integration
* Position engine
* Margin accounting

### Phase 02 — Perpetuals

* Long / short
* Leverage
* Funding
* Liquidations
* Trading fees

### Phase 03 — Risk

* Insurance fund
* Position limits
* Circuit breakers
* Oracle fallback
* Advanced liquidation engine

### Phase 04 — Permissionless Indexes

* Create custom indexes
* Configure weights
* Index governance
* Automated rebalancing

### Phase 05 — Trading Interface

* Web trading terminal
* Index explorer
* Position dashboard
* PnL analytics
* Risk dashboard
* Portfolio view

---

## Security

PerpDex is experimental software.

The protocol should not be considered production-ready until it has undergone:

* Unit testing
* Fuzz testing
* Invariant testing
* Oracle stress testing
* Liquidation simulations
* Economic simulations
* Smart-contract audit

Never use production funds with unaudited contracts.

---

## Disclaimer

PerpDex is experimental software and does not constitute financial, investment, legal, or trading advice.

Perpetual contracts involve substantial risk, including liquidation and loss of collateral.

Users are responsible for understanding the risks associated with leveraged trading.

---

## License

MIT
