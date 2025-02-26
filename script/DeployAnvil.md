# Dokumentasi DeployMocks.sol dengan Foundry dan Anvil

## Prasyarat
Sebelum menjalankan skrip, pastikan Anda telah menginstal Foundry dan Anvil. Jika belum, ikuti langkah berikut:

### 1. Instal Foundry
```sh
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Instal Dependensi Proyek
Masuk ke direktori proyek Anda dan jalankan perintah berikut untuk menginisialisasi dan mengunduh dependensi:
```sh
forge install
```

## Menjalankan Anvil
Anvil adalah jaringan blockchain lokal yang digunakan untuk menjalankan smart contract secara lokal.

### 1. Jalankan Anvil
```sh
anvil
```
Perintah ini akan menjalankan node Ethereum lokal di jaringan Anvil, memberikan Anda daftar akun pengujian dan kunci privat.

### 2. Simpan PRIVATE_KEY ke File .env
Salin salah satu private key dari output Anvil dan simpan dalam file `.env` di root proyek Anda:
```sh
echo "PRIVATE_KEY=<PRIVATE_KEY_ANVIL>" > .env
```
Gantilah `<PRIVATE_KEY_ANVIL>` dengan kunci pribadi dari akun yang disediakan oleh Anvil.

### 3. Simpan Alamat Kontrak ke File .env
Setelah deployment, catat alamat kontrak yang dihasilkan dan simpan dalam file `.env`:
```sh
echo "MOCKS_USDC_ADDRESS=<ALAMAT_MOCK_USDC>" >> .env
echo "MOCKS_ORACLE_USDC_ADDRESS=<ALAMAT_MOCK_ORACLE_USDC>" >> .env
```
Pastikan mengganti `<ALAMAT_MOCK_USDC>` dan `<ALAMAT_MOCK_ORACLE_USDC>` dengan alamat yang didapat dari deployment.

## Menggunakan Makefile untuk Deployment dan Testing
Untuk mempermudah proses deployment dan testing, Anda dapat menggunakan Makefile dengan konfigurasi berikut:

Buat file `Makefile` di root proyek Anda dan tambahkan isi berikut:
```makefile
-include .env

deploy-mocks-anvil:
	@forge script script/DeployMocks.s.sol:DeployMocks --rpc-url http://127.0.0.1:8545 --private-key $(PRIVATE_KEY) --broadcast

cast-mocks-usdc-anvil:
	@cast call $(MOCKS_USDC_ADDRESS) "name()(string)" --rpc-url http://127.0.0.1:8545

cast-mocks-oracle-usdc-anvil:
	@cast call $(MOCKS_ORACLE_USDC_ADDRESS) "getPrice()(uint256)" --rpc-url http://127.0.0.1:8545
```

Kemudian jalankan perintah berikut sesuai kebutuhan:

### 1. Compile Smart Contract
```sh
forge build
```

### 2. Deploy dengan Makefile
```sh
make deploy-mocks-anvil
```

### 3. Panggil Kontrak Mock USDC
```sh
make cast-mocks-usdc-anvil
```

### 4. Panggil Mock Oracle USDC
```sh
make cast-mocks-oracle-usdc-anvil
```

## Kesimpulan
Dokumentasi ini menjelaskan cara menginstal Foundry, menjalankan jaringan lokal Anvil, mengeksekusi skrip deployment untuk `DeployMocks.sol`, serta mengintegrasikan Makefile untuk mempermudah proses deployment dan testing. Dengan langkah-langkah ini, Anda dapat dengan mudah mengembangkan dan menguji smart contract secara lokal.

