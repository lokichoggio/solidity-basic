// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// 内部函数类型
library ArrayUtils {
    // 内部函数可以在内部库函数中使用，因为他们将是同一代码上下文的一部分
    function map(uint[] memory self, function (uint) pure returns (uint) f) internal pure returns (uint[] memory r) {
        r = new uint[](self.length);
        for (uint i = 0; i < self.length; i++) {
            r[i] = f(self[i]);
        }
    }

    function reduce(uint[] memory self, function (uint, uint) pure returns (uint) f) internal pure  returns (uint r) {
        r = self[0];
        for (uint i = 1; i < self.length; i++) {
            r = f(r, self[i]);
        }
    }

    function range(uint length) internal pure returns (uint[] memory r) {
        r = new uint[](length);
        for (uint i = 0; i < r.length; i++) {
            r[i] = i;
        }
    }
}

contract Pyramid {
    using ArrayUtils for *;

    function square(uint x) internal pure returns (uint) {
        return x * x;
    }

    function sum(uint x, uint y) internal pure returns (uint) {
        return x + y;
    }

    function pyramid(uint l) public pure returns (uint) {
        return ArrayUtils.range(l).map(square).reduce(sum);
    }
}