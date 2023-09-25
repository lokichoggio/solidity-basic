// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract DeleteExample {
    uint data;
    uint[] dataArray;

    function f() public {
        uint x = data;
        // 将 x 设为 0，并不影响data变量
        delete x;
        // 将 data 设为 0，并不影响 x
        delete data;

        uint[] storage y = dataArray;
        // 将 dataArray.length 设为 0，但由于 uint[] 是一个复杂的对象，
        // y 也将受到影响，它是一个存储位置是 storage 的对象的别名。
        // 另一方面："delete y" 是非法的，引用了 storage 对象的局部变量只能由已有的 storage 对象赋值。
        delete dataArray;
        assert(y.length == 0);
    }
}