// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract C {
    // x的存储位置是storage
    // 这是唯一可以省略数据存储位置的地方
    uint[] x;

    function g(uint[] storage) internal pure {}
    function h(uint[] memory) public pure {}

    // memoryArray的存储位置是memory
    function f(uint[] memory memoryArray) public {
        // 将整个数组拷贝到storage中，可行
        x = memoryArray;
        // 分配一个指针，其中y的数据存储位置是storage，可行
        uint[] storage y = x;
        // 返回第8个元素，可行
        y[7];
        // 通过y修改x，可行
        y.pop();
        // 清除数组，同时修改y，可行
        delete x;

        // 下面的就不可行了；需要在 storage 中创建新的未命名的临时数组， 但 storage 是“静态”分配的：
        // TypeError: Type uint256[] memory is not implicitly convertible to expected type uint256[] storage pointer.
        // y = memoryArray;


        // 同样， "delete y" 也是无效的，
        // 因为对引用存储对象的局部变量的赋值只能从现有的存储对象中进行。
        // 它将 “重置” 指针，但没有任何合理的位置可以指向它。
        // 更多细节见 "delete" 操作符的文档。
        // TypeError: Built-in unary operator delete cannot be applied to type uint256[] storage pointer.
        // delete y;

        // 调用g函数，同时移交对x的引用
        g(x);
        // 调用h函数，同时在memory中创建一个独立的临时拷贝
        h(x);
    }
}