# MediChain 💊⛓️
### Medicine Authenticity & Cold-Chain Tracker on Blockchain

A Flutter-based decentralized application deployed on **Ethereum Sepolia Testnet**.

---

## 🚀 Setup Steps

### Step 1 — Deploy Smart Contract
1. Open remix.ethereum.org
2. Paste `MediChain.sol`
3. Compiler: 0.8.19, Enable optimizer: 200 runs
4. Deploy to Sepolia Testnet via MetaMask
5. Copy the deployed contract address

### Step 2 — Configure App
Edit `lib/config/contract_config.dart`:
```dart
static const String contractAddress = '0xYourDeployedAddress';
static const String rpcUrl = 'https://rpc.sepolia.org';
```

### Step 3 — Run on GitHub Codespaces
1. Upload this project to a GitHub repository
2. Open Codespaces
3. Run in terminal:
```bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$(pwd)/flutter/bin"
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

### Step 4 — Get Free Sepolia ETH
Visit: https://faucet.sepolia.dev

---

## 📁 Project Structure
```
medichain/
├── MediChain.sol               ← Solidity smart contract
├── pubspec.yaml                ← Flutter dependencies
└── lib/
    ├── main.dart               ← App entry + router
    ├── config/
    │   └── contract_config.dart
    ├── models/
    │   └── medicine_batch.dart
    ├── providers/
    │   ├── wallet_provider.dart
    │   ├── medicine_provider.dart
    │   └── ai_provider.dart
    ├── widgets/
    │   └── shared_widgets.dart
    └── screens/
        ├── splash_screen.dart
        ├── home_screen.dart
        ├── scan_screen.dart
        ├── verify_screen.dart
        ├── dashboard_screen.dart
        ├── ai_chat_screen.dart
        ├── register_batch_screen.dart
        ├── transfer_screen.dart
        ├── cold_chain_screen.dart
        ├── admin_screen.dart
        ├── recall_screen.dart
        ├── actor_register_screen.dart
        └── batch_detail_screen.dart
```

## 🔑 Demo Credentials
- Admin Password: `admin2025`
- Test Batch Numbers: `BN-2025-001`, `BN-2025-002`

## 🌐 Features
- ✅ Medicine batch verification on Ethereum
- ✅ Complete supply chain tracking
- ✅ Cold-chain temperature monitoring
- ✅ AI chatbot (MediBot) for medicine guidance
- ✅ QR code generation and scanning
- ✅ Admin panel for actor verification
- ✅ Batch recall system
- ✅ Analytics dashboard with charts
