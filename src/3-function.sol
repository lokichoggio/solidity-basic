// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Func {

    // 函数成员

    function f() public payable returns (bytes4) {
        assert(this.f.address == address(this));
        return this.f.selector;
    }

    function g() public {
        this.f{gas: 10, value: 800}();
    }
}
