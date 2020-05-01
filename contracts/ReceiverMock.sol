pragma solidity >=0.5.14;
pragma experimental ABIEncoderV2;
import {IBridge, Bridge} from "./Bridge.sol";


contract ReceiverMock {
    Bridge.RequestPacket public latestReq;
    Bridge.ResponsePacket public latestRes;

    function relayAndSafe(IBridge bridge, bytes calldata _data) external {
        (latestReq, latestRes) = bridge.relayAndVerify(_data);
    }
}
