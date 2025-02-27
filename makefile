-include .env

deploy-mocks-anvil:
	@forge script script/DeployMocks.s.sol:DeployMocks --rpc-url http://127.0.0.1:8545 --private-key $(PRIVATE_KEY) --broadcast 

cast-mocks-usdc-anvil:
	@cast call $(MOCKS_USDC_ADDRESS) "name()(string)" --rpc-url http://127.0.0.1:8545

cast-mocks-oracle-usdc-anvil:
	@cast call $(MOCKS_ORACLE_USDC_ADDRESS) "getPrice()(uint256)" --rpc-url http://127.0.0.1:8545
