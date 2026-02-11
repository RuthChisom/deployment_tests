// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Owner} from "../src/Owner.sol";

contract OwnerTest is Test {
    Owner public owner;

    function setUp() public {
        owner = new Owner();
        owner.setNumber(0);
    }

    function test_Increment() public {
        owner.increment();
        assertEq(owner.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        owner.setNumber(x);
        assertEq(owner.number(), x);
    }
}
