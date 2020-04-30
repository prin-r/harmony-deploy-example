const { Harmony, HarmonyExtension } = require("@harmony-js/core");
const { ChainID, ChainType } = require("@harmony-js/utils");

const url = "https://api.s0.b.hmny.io";
const hmy = new Harmony(url, {
  chainType: ChainType.Harmony,
  chainId: ChainID.HmyLocal,
});

const countContractAddress = "0x37958987Dc85393016f9E08a56418Bcc97E58103";

const alice = hmy.wallet.addByPrivateKey(
  "613A09658CD9E3A11D7F65908DA8423C25A5A4D43FD76F56F1F8B7C4AB3F97D8"
);
console.log("alice", alice.bech32Address);

(async () => {
  const tx = hmy.transactions.newTx({
    to: countContractAddress,
    data:
      "0xd14e62b8000000000000000000000000000000000000000000000000000000000000000a",
    value: "0",
    shardID: 0,
    toShardID: 0,
    gasLimit: "5000000",
    gasPrice: "1000000000",
  });

  hmy.wallet.addByPrivateKey(
    "0x01F903CE0C960FF3A9E68E80FF5FFC344358D80CE1C221C3F9711AF07F83A3BD"
  );
  hmy.wallet.setSigner("0x3aea49553Ce2E478f1c0c5ACC304a84F5F4d1f98");

  const signedTX = await hmy.wallet.signTransaction(tx);
  const [sentTX, txHash] = await signedTX.sendTransaction();

  console.log(sentTX);
  console.log("=-=-=-=-=-=-=-=-=-=");
  console.log(txHash);
  console.log("done");
})();
