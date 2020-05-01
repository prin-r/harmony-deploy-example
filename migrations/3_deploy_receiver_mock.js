var ReceiverMock = artifacts.require("ReceiverMock");

module.exports = function (deployer) {
  deployer.deploy(ReceiverMock);
};
