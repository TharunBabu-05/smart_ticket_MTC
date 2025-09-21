#!/bin/bash

# Smart Ticket MTC - ICP Mainnet Deployment Script

echo "🚀 Smart Ticket MTC - ICP Blockchain Deployment"
echo "==============================================="

# Check if dfx is installed
if ! command -v dfx &> /dev/null; then
    echo "❌ DFX is not installed. Please install DFX first."
    echo "📖 Visit: https://internetcomputer.org/docs/current/developer-docs/setup/install"
    exit 1
fi

# Start local replica for testing
echo "🔧 Starting local DFX replica..."
dfx start --clean --background

# Deploy to local network first for testing
echo "📦 Deploying to local network for testing..."
dfx deploy --network local

if [ $? -eq 0 ]; then
    echo "✅ Local deployment successful!"
    
    # Get canister IDs
    echo "📋 Canister Information:"
    dfx canister id smart_ticket_backend --network local
    
    # Ask user if they want to deploy to mainnet
    echo ""
    read -p "🌐 Do you want to deploy to IC mainnet? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚨 WARNING: Deploying to mainnet will consume cycles!"
        read -p "Are you sure you want to continue? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🌐 Deploying to IC mainnet..."
            dfx deploy --network ic --with-cycles 1000000000000
            
            if [ $? -eq 0 ]; then
                echo "🎉 Mainnet deployment successful!"
                echo "📋 Mainnet Canister Information:"
                dfx canister id smart_ticket_backend --network ic
                
                # Generate canister URLs
                CANISTER_ID=$(dfx canister id smart_ticket_backend --network ic)
                echo "🔗 Canister URL: https://${CANISTER_ID}.ic0.app"
                echo "🔗 Candid Interface: https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=${CANISTER_ID}"
            else
                echo "❌ Mainnet deployment failed!"
                exit 1
            fi
        else
            echo "📝 Mainnet deployment cancelled."
        fi
    else
        echo "📝 Only local deployment completed."
    fi
else
    echo "❌ Local deployment failed!"
    exit 1
fi

echo ""
echo "✅ Deployment process completed!"
echo "📖 Next steps:"
echo "   1. Update your Flutter app with the canister ID"
echo "   2. Test the integration with Internet Identity"
echo "   3. Update constants in icp_service.dart if deploying to mainnet"