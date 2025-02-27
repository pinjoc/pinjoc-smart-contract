-include .env

deploy-mocks-anvil:
	@forge script script/DeployMocks.s.sol:DeployMocks --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast 

cast-mocks-usdc-anvil:
	@cast call $(MOCKS_USDC_ADDRESS) "name()(string)" --rpc-url http://127.0.0.1:8545

cast-mocks-oracle-usdc-anvil:
	@cast call $(MOCKS_ORACLE_USDC_ADDRESS) "getPrice()(uint256)" --rpc-url http://127.0.0.1:8545
