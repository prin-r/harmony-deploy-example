# Harmony Example Deploy

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
