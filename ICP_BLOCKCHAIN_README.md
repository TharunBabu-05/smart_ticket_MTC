# Smart Ticket MTC - ICP Blockchain Integration

This document explains the Internet Computer Protocol (ICP) blockchain integration in the Smart Ticket MTC app.

## 🏗️ Architecture

The ICP integration consists of:

- **Flutter Frontend**: Mobile app with ICP wallet integration
- **Motoko Backend**: Smart contract on IC mainnet for ticket management
- **Internet Identity**: Decentralized authentication system

## 📁 Project Structure

```
├── dfx.json                          # DFX configuration
├── src/
│   └── smart_ticket_backend/
│       ├── main.mo                   # Motoko backend canister
│       └── main.did                  # Candid interface
├── lib/services/
│   ├── icp_service.dart              # ICP blockchain service
│   └── icp_ticket_service.dart       # High-level ticket service
├── deploy.sh                         # Bash deployment script
└── deploy.ps1                        # PowerShell deployment script
```

## 🚀 Deployment

### Prerequisites

1. Install DFX CLI:
   ```bash
   sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"
   ```

2. Create an Internet Identity:
   - Visit: https://identity.ic0.app
   - Create your digital identity

### Local Development

1. Start local replica:
   ```bash
   dfx start --clean --background
   ```

2. Deploy locally:
   ```bash
   dfx deploy --network local
   ```

### Mainnet Deployment

1. **Option 1: Use deployment script**
   ```bash
   # Linux/Mac
   chmod +x deploy.sh
   ./deploy.sh
   
   # Windows
   .\deploy.ps1
   ```

2. **Option 2: Manual deployment**
   ```bash
   # Deploy to mainnet (requires cycles)
   dfx deploy --network ic --with-cycles 1000000000000
   
   # Get canister ID
   dfx canister id smart_ticket_backend --network ic
   ```

## 🔧 Configuration

After deployment, update the canister ID in your Flutter app:

1. Open `lib/services/icp_service.dart`
2. Update the `canisterId` constant with your deployed canister ID:
   ```dart
   static const String canisterId = "your-canister-id-here";
   ```

## 📱 Flutter Integration Features

### Authentication
- Internet Identity wallet connection
- Principal-based user identification
- Secure authentication flow

### Ticket Management
- Purchase tickets with ICP tokens
- Blockchain-based ticket validation
- Immutable ticket records
- Real-time ticket status

### Smart Contract Functions

| Function | Description | Type |
|----------|-------------|------|
| `purchaseTicket` | Buy a new ticket | Update |
| `validateTicket` | Check ticket validity | Query |
| `getTicket` | Get ticket details | Query |
| `getUserTickets` | Get user's tickets | Query |
| `invalidateTicket` | Mark ticket as used | Update |
| `healthCheck` | System status | Query |

## 🌐 Mainnet Information

- **Network**: Internet Computer Mainnet
- **Internet Identity**: `rdmx6-jaaaa-aaaaa-aaadq-cai`
- **Candid UI**: `https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=<canister-id>`

## 💰 Cycles Management

Your canister needs cycles to run on mainnet:

1. **Get cycles**: Visit [Cycles Faucet](https://faucet.dfinity.org/)
2. **Top up canister**:
   ```bash
   dfx canister deposit-cycles <amount> smart_ticket_backend --network ic
   ```

## 🔍 Monitoring

Check canister status:
```bash
# Check canister info
dfx canister status smart_ticket_backend --network ic

# Check cycles balance
dfx canister status smart_ticket_backend --network ic
```

## 📚 Resources

- [Internet Computer Documentation](https://internetcomputer.org/docs)
- [Motoko Programming Language](https://internetcomputer.org/docs/current/motoko/intro)
- [DFX CLI Reference](https://internetcomputer.org/docs/current/references/cli-reference)
- [Internet Identity Integration](https://internetcomputer.org/docs/current/tokenomics/identity-auth)

## 🔐 Security Notes

- Never commit private keys or seed phrases
- Use Internet Identity for secure authentication
- Test thoroughly on local network before mainnet deployment
- Monitor canister cycles regularly
- Keep your DFX identity secure

## 🐛 Troubleshooting

### Common Issues

1. **DFX not found**: Install DFX CLI
2. **Insufficient cycles**: Top up your canister
3. **Network timeout**: Check internet connection
4. **Compilation errors**: Ensure Motoko syntax is correct

### Debug Commands

```bash
# Check DFX version
dfx --version

# List canisters
dfx canister id --all --network ic

# View logs
dfx canister logs smart_ticket_backend --network ic
```

## 📞 Support

For ICP integration issues:
1. Check the [Internet Computer Forum](https://forum.dfinity.org/)
2. Review [DFINITY Developer Discord](https://discord.gg/jnjVVQaE2C)
3. Consult [IC Developer Documentation](https://internetcomputer.org/docs)