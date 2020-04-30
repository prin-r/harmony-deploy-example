# Harmony Example Deploy

## Directory Breakdown

### `.env`

Where we will store our environment variables. Contains the private key, mnemonic, and urls for each of the network we want to deploy to.

Specifically, your `.env` file will need to have a line with the content `ENV='[DESIRED_NETWORK]'` where `DESIRED_NETWORK` is one of localnet/testnet/mainnet

In addition, for each network you'll need:

- deploying account's private key
- network url
- `GAS_LIMIT`, `GAS_PRICE` (can use the same as example in this repo, don't touch)

### `truffle-config.js`

This file handles network deploy & migrate. Generally, this file will stay the same for all projects.

### `contracts/`

Created when you run `truffle init`. This is where you will put any smart contracts you write.

#### `Inbox.sol`

Our simple example contract.

#### `Migrations.sol`

Wrapper contract created when you run `truffle init`.

### `migrations/`

Files to handle our contract migration and deployment.

#### `1_initial_migration.js`

Created when `truffle init` is run.

#### `2_deploy_contracts.js`

The file we will create to specify the deployment process for our `Inbox.sol`.

## Development

The following sections will outline how to recreate this repository from scratch.

### Project Directory Setup

#### Create Project Directory

```bash
mkdir harmony-example-deploy
cd harmony-example-deploy
```

#### Initialize Truffle and NPM

```bash
npm init
truffle init
```

#### Install Required Start Packages

```bash
npm install dotenv
npm install @harmony-js/core@next
npm install tslib
```

### Update ENV and Config Files

Create a `.env` file with the following contents.

**Remeber to change the `MAINNET_PRIVATE_KEY` and `MAINNET_MNEMONIC` with your own before deploying to mainnet.**

```env
//LOCAL
//Local uses account one103q7qe5t2505lypvltkqtddaef5tzfxwsse4z7 on Shard 0
LOCAL_PRIVATE_KEY='45e497bd45a9049bcb649016594489ac67b9f052a6cdf5cb74ee2427a60bf25e'
LOCAL_MNEMONIC='urge clog right example dish drill card maximum mix bachelor section select'
LOCAL_0_URL='http://localhost:9500'

//TESTNET
//Account: one18t4yj4fuutj83uwqckkvxp9gfa0568uc48ggj7
TESTNET_PRIVATE_KEY='01F903CE0C960FF3A9E68E80FF5FFC344358D80CE1C221C3F9711AF07F83A3BD'
TESTNET_MNEMONIC='urge clog right example dish drill card maximum mix bachelor section select'

TESTNET_0_URL='https://api.s0.b.hmny.io'
TESTNET_1_URL='https://api.s1.b.hmny.io'

//MAINNET
//Please replace MAINNET_PRIVATE_KEY and MAINNET_MNEMONIC with your own!
//Account: 'one1vqpf94xctamtzatlyjmerjtx7gp93hyzekyh87'
MAINNET_PRIVATE_KEY='0x98aac0f92593d4e9189de6db67e71434c8c6599c0fed358cdc4ced8e26b92d25'
MAINNET_MNEMONIC='share ten economy toast disorder moon path matter crew moment poet tribe'
MAINNET_0_URL='https://api.s0.t.hmny.io'

GAS_LIMIT=3321900
GAS_PRICE=1000000000

//HRC20 Contract Addresses
//TESTNET
TESTNET_HRC20CROWDSALE='0x2FF6EB68B34D4e3c8e2B2b2f485ad6BB0531116F'
TESTNET_HARMONYMINTABLE='0xD1c6B0f49A934BFc40e57e9953913fAB30C728cB'
TESTNET_MIGRATIONS='0x91AFbAd45ebbeC130c479dC3faF2A9fB8066DE92'

//MAINNET
MAINNET_HRC20CROWDSALE='0x68aC62E3ed67faC6A0df4c5DC9f6423e2d454EED'
MAINNET_HARMONYMINTABLE='0xBcF2Be2474DB5A08B4B25D921729FC424c74F583'
MAINNET_MIGRATIONS='0x6D904b33A4Af28353BEEb65D0a65bb7CD4B6Dc91'

ENV='testnet'
```

Also, replace the contents of `truffle-config.js` with:

```js
// * Use this file to configure your truffle project. It's seeded with some
// * common settings for different networks and features like migrations,
// * compilation and testing. Uncomment the ones you need or modify
// * them to suit your project as necessary.
// *
// * More information about configuration can be found at:
// *
// * truffleframework.com/docs/advanced/configuration
// *
// * To deploy via Infura you'll need a wallet provider (like truffle-hdwallet-provider)
// * to sign your transactions before they're sent to a remote public node. Infura accounts
// * are available for free at: infura.io/register.
// *
// * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
// * public/private key pairs. If you're publishing your code to GitHub make sure you load this
// * phrase from a file you've .gitignored so it doesn't accidentally become public.
// *
// */
require("dotenv").config();
const { TruffleProvider } = require("@harmony-js/core");
//Local
const local_mnemonic = process.env.LOCAL_MNEMONIC;
const local_private_key = process.env.LOCAL_PRIVATE_KEY;
const local_url = process.env.LOCAL_0_URL;
//Testnet
const testnet_mnemonic = process.env.TESTNET_MNEMONIC;
const testnet_private_key = process.env.TESTNET_PRIVATE_KEY;
const testnet_url = process.env.TESTNET_0_URL;
//const testnet_0_url = process.env.TESTNET_0_URL
//const testnet_1_url = process.env.TESTNET_1_URL
//Mainnet
const mainnet_mnemonic = process.env.MAINNET_MNEMONIC;
const mainnet_private_key = process.env.MAINNET_PRIVATE_KEY;
const mainnet_url = process.env.MAINNET_0_URL;

//GAS - Currently using same GAS accross all environments
gasLimit = process.env.GAS_LIMIT;
gasPrice = process.env.GAS_PRICE;

module.exports = {
  networks: {
    local: {
      network_id: "2",
      provider: () => {
        const truffleProvider = new TruffleProvider(
          local_url,
          { memonic: local_mnemonic },
          { shardID: 0, chainId: 2 },
          { gasLimit: gasLimit, gasPrice: gasPrice }
        );
        const newAcc = truffleProvider.addByPrivateKey(local_private_key);
        truffleProvider.setSigner(newAcc);
        return truffleProvider;
      },
    },
    testnet: {
      network_id: "2",
      provider: () => {
        const truffleProvider = new TruffleProvider(
          testnet_url,
          { memonic: testnet_mnemonic },
          { shardID: 0, chainId: 2 },
          { gasLimit: gasLimit, gasPrice: gasPrice }
        );
        const newAcc = truffleProvider.addByPrivateKey(testnet_private_key);
        truffleProvider.setSigner(newAcc);
        return truffleProvider;
      },
    },
    mainnet0: {
      network_id: "1",
      provider: () => {
        const truffleProvider = new TruffleProvider(
          mainnet_url,
          { memonic: mainnet_mnemonic },
          { shardID: 0, chainId: 1 },
          { gasLimit: gasLimit, gasPrice: gasPrice }
        );
        const newAcc = truffleProvider.addByPrivateKey(mainnet_private_key);
        truffleProvider.setSigner(newAcc);
        return truffleProvider;
      },
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.5.14",
    },
  },
};
```

Creating Your Smart Contracts

We will create a simple smart contract. In your `contracts/` folder, create a `Inbox.sol` file with the following contents.

```solidity
pragma solidity >= 0.5.14;

contract Inbox {
    string public message;

    constructor() public {
        message = "hello world";
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}
```

And in the `migrations` folder, create a file name `2_deploy_contracts.js` and copy the following code into it.

```js
var Inbox = artifacts.require("Inbox");

module.exports = function (deployer) {
  deployer.deploy(Inbox);
};
```

## Deployment

#### Compile and Deploy Your Contract

```bash
truffle compile
truffle deploy --network=testnet --reset
```

### Check Contract Deploy

To check that your contract has been successfully deployed, run the following command:

```bash
truffle networks
```

If the contract deployment was successful, you should something similar to this

```bash
Network: local (id: 2)
  No contracts deployed.

Network: mainnet0 (id: 1)
  No contracts deployed.

# Successful contract deploy will show some info here
Network: testnet (id: 2)
  Inbox: 0xf97DeD9b8C3a07D6FE799d138752a995e48a98B4
  Migrations: 0x658aDB885f6D7F120b1d6612962674954046A5a9
```
