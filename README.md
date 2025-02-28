# 🚀 PINJOC Protocol

## 📜 Description

PINJOC is a decentralized fixed-rate lending protocol that revolutionizes DeFi lending by implementing a market-driven interest rate mechanism. Built on Ethereum, the protocol leverages CLOB (Central Limit Order Book) technology from GTX DEX to ensure efficient price discovery and optimal interest rate determination based on real-time supply and demand dynamics.

---

## ❌ Problems

- 🔄 **Variable Interest Rates**: Unpredictable returns & costs
- 📅 **No Fixed Loan Terms**: Open-ended, no set maturity
- 📊 **Utilization-Based Rates**: Interest rates based on utilization rate
- 🏦 **TradFi Relies on Fixed Rates**: Trustable rate by TradFi

---

## ✅ Solutions

- 📈 **CLOB Matching**: GTX DEX order book & RISE the fastest chain
- 🔒 **Fixed Rate, Fixed Term**: Lock interest rate and maturity date
- 📉 **Market-Based Rates**: Interest rates based on supply and demand
- 🔄 **Auto-Roll Supply**: Automated re-lend funds into a new loan
- 🎫 **Tokenized Bond**: Tokenized loans, tradable before maturity

---

## 🏗 Technical Stack

### 🔧 Core Technology
- 📝 **Language**: Solidity ^0.8.19
- 🏗 **Framework**: Foundry
- ⛓ **Blockchain**: Ethereum & RISE Network
- 💱 **DEX Integration**: GTX CLOB System

### 🛠 Development Tools
- 🧪 **Testing**: Forge (Foundry's testing framework)
- 🚀 **Deployment**: Foundry Cast
- 🔗 **Local Network**: Anvil
- 🧐 **Code Analysis**: Forge fmt & snapshot

### 🌐 Networks
- 🛠 **Testnet**: RISE Testnet
- 🌍 **Mainnet**: Ethereum (Planned)

### 📦 Dependencies
- OpenZeppelin Contracts ^4.8.0
- Foundry Toolchain v0.2.0

---

## 🔍 Technical Highlights

### 📑 On-Chain Order Book
- ⚡ GTX DEX order book system for loan matching
- 🚀 Deployed on RISE Network for fast execution
- 💰 Low-cost transactions and settlement
- 📊 Real-time interest rate price discovery

### 🏛 Smart Contract Architecture
- 🏦 Secure lending pool management
- 🎟 Tokenized bond issuance system
- 🛡 Collateral tracking and management
- 📈 Automated interest rate adjustment

### 🔥 Auto Liquidation System
- 📡 Real-time health factor monitoring
- 🛑 Automated collateral liquidation
- 🏷 Price oracle integration
- 📉 Safety margin calculations

---

## 🚀 Getting Started

### 📌 Prerequisites
- 🖥 **Git**
- 🏗 **Foundry**

### 📥 Installation

1. Clone the repository
```bash
git clone https://github.com/pinjoc/pinjoc-smart-contract
cd pinjoc-smart-contract
```

2. Install dependencies
```bash
forge install
```

3. Build the project
```bash
forge build
```

4. Run tests
```bash
forge test
```

---

## 🛠 Local Development

1. Start local node
```bash
anvil
```

2. Deploy contracts
```bash
forge script script/Deploy.s.sol --rpc-url localhost --broadcast
```

---

## 🌍 Deployment

1. Create .env file
```bash
cp .env.example .env
```

2. Set your environment variables in .env
```ini
PRIVATE_KEY=your_private_key
RISE_RPC_URL=your_rise_rpc_url
```

3. Deploy to RISE testnet
```bash
forge script script/Deploy.s.sol --rpc-url $RISE_RPC_URL --broadcast --private-key $PRIVATE_KEY
```

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
