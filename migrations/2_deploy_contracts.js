var Bridge = artifacts.require("Bridge_v2");

module.exports = function (deployer) {
  // deployer.deploy(Bridge, [
  //   ["0x652D89a66Eb4eA55366c45b1f9ACfc8e2179E1c5", 100],
  //   ["0x88e1cd00710495EEB93D4f522d16bC8B87Cb00FE", 100],
  //   ["0xaAA22E077492CbaD414098EBD98AA8dc1C7AE8D9", 100],
  //   ["0xB956589b6fC5523eeD0d9eEcfF06262Ce84ff260", 100],
  // ]);
  deployer.deploy(Bridge);
};
