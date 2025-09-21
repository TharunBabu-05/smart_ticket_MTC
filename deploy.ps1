# Smart Ticket MTC - ICP Mainnet Deployment Script (PowerShell)

Write-Host "🚀 Smart Ticket MTC - ICP Blockchain Deployment" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green

# Check if dfx is installed
try {
    dfx --version | Out-Null
    Write-Host "✅ DFX is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ DFX is not installed. Please install DFX first." -ForegroundColor Red
    Write-Host "📖 Visit: https://internetcomputer.org/docs/current/developer-docs/setup/install" -ForegroundColor Yellow
    exit 1
}

# Start local replica for testing
Write-Host "🔧 Starting local DFX replica..." -ForegroundColor Yellow
dfx start --clean --background

# Deploy to local network first for testing
Write-Host "📦 Deploying to local network for testing..." -ForegroundColor Yellow
dfx deploy --network local

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Local deployment successful!" -ForegroundColor Green
    
    # Get canister IDs
    Write-Host "📋 Canister Information:" -ForegroundColor Cyan
    $localCanisterId = dfx canister id smart_ticket_backend --network local
    Write-Host "Local Canister ID: $localCanisterId" -ForegroundColor White
    
    # Ask user if they want to deploy to mainnet
    Write-Host ""
    $deploy = Read-Host "🌐 Do you want to deploy to IC mainnet? (y/N)"
    
    if ($deploy -eq "y" -or $deploy -eq "Y") {
        Write-Host "🚨 WARNING: Deploying to mainnet will consume cycles!" -ForegroundColor Red
        $confirm = Read-Host "Are you sure you want to continue? (y/N)"
        
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            Write-Host "🌐 Deploying to IC mainnet..." -ForegroundColor Yellow
            dfx deploy --network ic --with-cycles 1000000000000
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "🎉 Mainnet deployment successful!" -ForegroundColor Green
                Write-Host "📋 Mainnet Canister Information:" -ForegroundColor Cyan
                $mainnetCanisterId = dfx canister id smart_ticket_backend --network ic
                Write-Host "Mainnet Canister ID: $mainnetCanisterId" -ForegroundColor White
                
                # Generate canister URLs
                Write-Host "🔗 Canister URL: https://$mainnetCanisterId.ic0.app" -ForegroundColor Blue
                Write-Host "🔗 Candid Interface: https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=$mainnetCanisterId" -ForegroundColor Blue
            } else {
                Write-Host "❌ Mainnet deployment failed!" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "📝 Mainnet deployment cancelled." -ForegroundColor Yellow
        }
    } else {
        Write-Host "📝 Only local deployment completed." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Local deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Deployment process completed!" -ForegroundColor Green
Write-Host "📖 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Update your Flutter app with the canister ID" -ForegroundColor White
Write-Host "   2. Test the integration with Internet Identity" -ForegroundColor White
Write-Host "   3. Update constants in icp_service.dart if deploying to mainnet" -ForegroundColor White