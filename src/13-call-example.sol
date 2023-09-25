// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract B {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(uint256 _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint256 public num;
    address public sender;
    uint256 public value;

    // uint256 public numA;
    // address public senderA;
    // uint256 public valueA;

    function setVars(address _contract, uint256 _num) public payable {
        (bool success,) = _contract.call(abi.encodeWithSignature("setVars(uint256)", _num));
        if (!success) {
            revert("call failed");
        }
    }
}
