// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract Example {

    // 隐式转换
    uint8 y;
    uint16 z;
    uint32 x = y + z;

    // 显式转换
    // x 变成 0xfffff..fd 的值（64个十六进制字符）， 这在256位的二进制补码中表示是-3。
    int a = -3;
    uint b = uint(a);

    // 一个整数被明确地转换为一个较小的类型，高阶位就会被切断
    uint32 c = 0x12345678;
    // d 现在会是 0x5678
    uint16 d = uint16(c);

    // 如果一个整数被明确地转换为一个更大的类型，它将在左边被填充（即在高阶的一端）。 转换的结果将与原整数比较相等
    uint16 e = 0x1234;
    // f 现在会是 0x00001234
    uint32 f = uint32(e);
    // assert(e == f);

    //固定大小的字节类型在转换过程中的行为是不同的。 它们可以被认为是单个字节的序列，转换到一个较小的类型将切断序列：
    bytes2 g = 0x1234;
    // h 现在会是 0x12
    bytes1 h = bytes1(g);

    // 如果一个固定大小的字节类型被明确地转换为一个更大的类型，它将在右边被填充。 访问固定索引的字节将导致转换前后的数值相同（如果索引仍在范围内）：
    bytes2 i = 0x1234;
    // j 现在会是 0x12340000
    bytes4 j = bytes4(i);
    // assert(i[0] == j[0]);
    // assert(i[1] == j[1]);

    // 于整数和固定大小的字节数组在截断或填充时表现不同， 只有在整数和固定大小的字节数组具有相同大小的情况下，才允许在两者之间进行显式转换。 如果您想在不同大小的整数和固定大小的字节数组之间进行转换，您必须使用中间转换， 使所需的截断和填充规则明确：
    bytes2 k  = 0x1234;
    // l 将会是 0x00001234
    uint32 l = uint16(k);
    // m 将会是 0x12340000
    uint32 m = uint32(bytes4(k));
    // n 将会是 0x34
    uint8 n = uint8(uint16(k));
    // o 将会是 0x12
    uint8 o = uint8(bytes1(k));


    bytes s = "abcdefgh";
    function func(bytes calldata p, bytes memory q) public view returns (bytes16, bytes3) {
        require(p.length == 16, "");

        // 如果q的长度大于16，将发生截断。
        bytes16 r = bytes16(q);

        // 右边进行填充，所以结果是 "abcdefgh\0\0\0\0\0\0\0\0"
        r = bytes16(s);

        // 发生截断, b1 相当于 "abc"
        bytes3 b1 = bytes3(s);

        // 同样用0进行填充
        r = bytes16(p[:8]);

        return (r, b1);
    }

    // 十进制和十六进制的数字字面常数可以隐含地转换为任何足够大的整数类型去表示它而不被截断：
    uint8 t = 12;
    uint32 u = 1234;
    // 报错, 因为这将会截断成 0x3456
    // uint16 v = 0x123456;

    // 十进制字面常数不能被隐含地转换为固定大小的字节数组。 十六进制数字字面常数是可以的，但只有当十六进制数字的数量正好符合字节类型的大小时才可以。 但是有一个例外，数值为0的十进制和十六进制数字字面常数都可以被转换为任何固定大小的字节类型：
    // 不行
    // bytes2 a1 = 123456;
    // bytes2 b2 = 0x12;
    // 可行
    bytes2 c1 = 0x1234;
    bytes2 d1 = 0x0012;
    bytes4 e1 = 0;
    bytes4 f1 = 0x0;

    //字符串和十六进制字符串字面常数可以被隐含地转换为固定大小的字节数组， 如果它们的字符数与字节类型的大小相匹配：
    bytes2 g1 = hex"1234";
    bytes2 i1 = hex"12";
    // 不行
    // bytes2 j1 = hex"123";

    bytes2 h1 = "xy";
    bytes2 k1 = "x";
    // 不行
    // bytes2 l1 = "xyz";

    // 只允许从 bytes20 和 uint160 显式转换到 address。
    // address a 可以通过 payable(a) 显式转换为 address payable。

}