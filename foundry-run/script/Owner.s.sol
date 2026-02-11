// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Owner} from "../src/Owner.sol";

contract OwnerScript is Script {
    Owner public owner;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        owner = new Owner();

        vm.stopBroadcast();
    }
}
