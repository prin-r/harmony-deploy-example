# Harmony Example Deploy

## Setup

```bash
yarn install
```

## Deployment

#### Compile and Deploy Your Contract

```bash
yarn truffle compile
yarn truffle deploy --network=testnet --reset
```

### Check Contract Deploy

To check that your contract has been successfully deployed, run the following command:

```bash
yarn truffle networks
```

If the contract deployment was successful, you should something similar to this

```bash
Network: local (id: 2)
  No contracts deployed.

Network: mainnet0 (id: 1)
  No contracts deployed.

# Successful contract deploy will show some info here
Network: testnet (id: 2)
  Bridge: 0x3fF2B9215e191825ea3d5D6B63f7FE4F569D8832
  Migrations: 0x8cA91d1B5EBc07D8EDdb0670E9d9AE5e8c79ba2b
  ReceiverMock: 0xccc5D7A1A87191C116c69c5240506268267B63dA
```

### Test ReceiverMock contract

- Please see the [`index.js`](/index.js) for sending tx relayAndSafe

- Ask chain if the transaction was successful or not

```bash
curl --location --request POST 'https://api.s0.b.hmny.io' \
--header 'Content-Type: application/json' \
--header 'Content-Type: text/plain' \
--data-raw '{
    "jsonrpc":"2.0",
    "method":"hmy_getTransactionReceipt",
    "params":[
    "0xdb9e715485432bc84a1d0f8bc4ea001b4b5c4cc4659ab4bace4abe1d59d93d14"],
    "id":1
}'
```

- Ask chain for the value of "latestReq" in the ReceiverMock contract

```bash
curl --location --request POST 'https://api.s0.b.hmny.io' \
--header 'Content-Type: application/json' \
--header 'Content-Type: text/plain' \
--data-raw '{
    "jsonrpc": "2.0",
    "method": "hmy_call",
    "params": [
        {
            "to": "0xccc5D7A1A87191C116c69c5240506268267B63dA",
            "data": "0x8a0d3c31"
        },
        "latest"
    ],
    "id": 1
}'
```
