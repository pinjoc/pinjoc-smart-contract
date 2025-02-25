-include .env

deploy-mocks-anvil:
	@forge script script/DeployMocks.s.sol:DeployMocks --rpc-url http://127.0.0.1:8545 --private-key $(PRIVATE_KEY) --broadcast

cast-mocks-usdc-anvil:
	@cast call 0x0165878A594ca255338adfa4d48449f69242Eb8F "name()(string)" --rpc-url http://127.0.0.1:8545

cast-mocks-oracle-usdc-anvil:
	@cast call 0x67d269191c92Caf3cD7723F116c85e6E9bf55933 "getPrice()(uint256)" --rpc-url http://127.0.0.1:8545

