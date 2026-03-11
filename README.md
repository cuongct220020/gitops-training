# btc-blueprint ⛓️

![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

> A modular, deep-dive implementation of a Bitcoin-like blockchain in pure Go. 

This repository is not a "toy blockchain". It is built from the ground up as a practical companion to Andreas M. Antonopoulos's *Mastering Bitcoin*, focusing heavily on the core distributed systems and cryptographic engineering concepts that make Bitcoin work.

## 🎯 Core Features & Deep Dives

Unlike basic blockchain tutorials, this project implements the true architectural pillars of Bitcoin:

- **UTXO Transaction Model:** Pure Unspent Transaction Output architecture using ECDSA (secp256k1) and Base58Check encoding.
- **Fee-Prioritized Mempool:** Transactions are not blindly mined. The mempool prioritizes and sorts pending transactions based on their `Fee-per-Byte` ratio, maximizing miner profitability.
- **Stack-based Script VM:** A minimal Virtual Machine built from scratch to parse and execute Bitcoin's Stack-based Scripting Language (specifically targeting `P2PKH` - Pay-to-Public-Key-Hash).
- **SPV Light Client (Merkle Proofs):** Implements Simplified Payment Verification (SPV). The light client verifies transactions using Merkle Paths and Block Headers without downloading the entire blockchain state.
- **P2P Network Protocol:** Custom TCP-based peer-to-peer networking using Go routines and channels to handle node discovery, mempool syncing, and longest-chain consensus.

## 📂 Repository Structure

The project follows a standard Go modular layout:

```text
btc-from-scratch/
├── cmd/
│   ├── miner/             # Full Node daemon with Proof-of-Work mining capabilities
│   ├── spv-client/        # Light Node daemon (downloads headers only)
│   └── cli/               # Command-line wallet interface for key gen and tx creation
├── pkg/
│   ├── wallet/            # ECDSA cryptography, Base58Check, Address generation
│   ├── script/            # Stack-based VM for OP_CODE execution (OP_DUP, OP_CHECKSIG, etc.)
│   ├── transaction/       # TxIn, TxOut, UTXO Set management, and Mempool logic
│   ├── blockchain/        # Block architecture, Merkle Tree construction, State management
│   ├── consensus/         # Proof-of-Work algorithm, Difficulty target adjustment
│   └── p2p/               # TCP peer-to-peer synchronization and message protocols
└── docker-compose.yml     # Local P2P testnet simulation

```

## 🗺️ Roadmap (Long-term Vision)

This project is actively being developed. The current roadmap:

* [ ] **Phase 1: Cryptography & Data Structures** (Wallet, Hash functions, Block & Merkle Tree structs).
* [ ] **Phase 2: Transactions & VM** (UTXO logic, Mempool creation, Stack-based Script execution).
* [ ] **Phase 3: Consensus & Mining** (PoW implementation, block rewarding, fee calculation).
* [ ] **Phase 4: Networking** (P2P protocol, state synchronization, handling orphan blocks).
* [ ] **Phase 5: SPV Integration** (Light client implementation and Merkle Proof verification).

## 🚀 Getting Started

*(Instructions will be updated as the networking phase is completed)*

To spin up a local testnet simulation with 3 Miners and 1 SPV Client:

```bash
# Clone the repository
git clone [https://github.com/yourusername/btc-from-scratch.git](https://github.com/yourusername/btc-from-scratch.git)
cd btc-from-scratch

# Start the P2P network simulation
docker-compose up --build
```
## 📚 References

* [Mastering Bitcoin (2nd Edition)](https://github.com/bitcoinbook/bitcoinbook) by Andreas M. Antonopoulos.
* [Bitcoin Core Source Code](https://github.com/bitcoin/bitcoin)