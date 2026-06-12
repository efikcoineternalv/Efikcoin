Module Description
Blockchain Connection Web3Modal + ethers.js v5 – supports MetaMask, WalletConnect, Coinbase Wallet. Connects to BNB Smart Chain (chainId 56).
Token Contract Interaction Uses minimal ERC20 ABI to fetch balanceOf, decimals, symbol, and transfer. Your token address: 0x677ce9cba67f7484ea951a12897ce780cfd8fed1
Real‑Time Data Fetches EFC price from DexScreener API every 30 seconds. Displays wallet’s EFC balance, BNB balance, and total portfolio value in USD.
Send Functionality Modal appears to enter recipient address and amount – calls transfer() on the token contract.
Add Token to Wallet Uses MetaMask wallet_watchAsset to add EFC token to user’s wallet.
Client Registration Stores username + wallet address in localStorage (key: efc_users). No backend, no data sharing. Shows registered username in dashboard.
Admin Monitor Toggle button displays list of all registered users (wallet addresses + usernames) from localStorage.
Toast Notifications Small floating messages for success/error/info.
Particles Background particles.js config – floating purple/blue circles with hover repulse effect.
Staking / Deposit / Withdraw Placeholder buttons with toast messages – actual smart contract integration can be added later.
