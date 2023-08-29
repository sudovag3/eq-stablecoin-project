// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import {Script} from "forge-std/Script.sol";
import {EQuicoin} from "../src/EQuicoin.sol";

contract DeployEQuicoin is Script {
    function run() external returns (EQuicoin) {
        vm.startBroadcast();
        //After startBroadcast -> REAL tx!
        EQuicoin equicoin = new EQuicoin(
            1000000000,
            "EQuicoin EUR",
            "EUREQ",
            6
        );
        vm.stopBroadcast();
        return equicoin;
    }
}
