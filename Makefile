-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployEQ.s.sol:DeployEQuicoin --rpc-url $(SEPOLIA_RPC) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv