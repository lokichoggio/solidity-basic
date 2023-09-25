// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract Example {

    // 以太币单位
    function f() public pure {
        assert(1 wei == 1);
        assert(1 gwei == 1e9);
        assert(1 ether == 1e18);
    }

    // 时间后缀不能用于变量
    function timeF(uint start, uint dayAfter) public view {
        if (block.timestamp >= start + dayAfter * 1 days) {
            //
        }
    }

    // 区块和交易属性
    uint blockNumber = 111;
    address payable blockAddress = 0xaaa;

    function blockF() public view {
        // 当 blocknumber 是最近的256个区块之一时，给定区块的哈希值；否则返回0。
        blockhash(blockNumber)
        
        // 当前区块的基本费用
        block.basefee

        // 当前链id
        block.chainid

        // 挖出当前区块的矿工地址
        block.coinbase

        // 当前块的难度
        block.difficulty

        // 当前区块 gas 限额
        block.gaslimit

        // 当前区块号
        block.number

        // 自 unix epoch 起始到当前区块以秒计的时间戳
        block.timestamp

        // 剩余的 gas
        gasleft();

        // 完整的 calldata
        msg.data

        // calldata 的前 4 字节（也就是函数标识符）
        msg.sig

        //  随消息发送的 wei 的数量
        msg.value

        // 随消息发送的 wei 的数量
        tx.gasprice

        // 交易发起者（完全的调用链）
        tx.origin
    }

    function abiF() public view  {
        // ABI-解码给定的数据
        abi.decode

        // 对给定的参数进行ABI编码
        abi.encode(arg);

        // 对给定参数执行 紧打包编码。
        abi.encodePacked(arg);

        // ABI-对给定参数进行编码，并以给定的函数选择器作为起始的4字节数据一起返回
        abi.encodeWithSelector(bytes4, arg);

        // 相当于 abi.encodeWithSelector(bytes4(keccak256(bytes(signature))), ...)
        abi.encodeWithSignature(signatureString, arg);

        // 对 函数指针 的调用进行ABI编码，参数在元组中找到。执行全面的类型检查，确保类型与函数签名相符。
        // 结果相当于 abi.encodeWithSelector(functionPointer.selector, (...))。
        abi.encodeCall
    }

    // 将可变数量的字节和byte1, ..., byte32参数串联成一个字节数组
    bytes.concat(bytes);
    // 将可变数量的字符串参数串联成一个字符串数组
    string.concat(string);


    // 错误处理

    // 如果条件不满足，会导致异常，因此，状态变化会被恢复 - 用于内部错误
    assert(condition);
    // 如果条件不满足，则恢复状态更改 - 用于输入或外部组件的错误。
    require(condition);
    // 如果条件不满足，则恢复状态更改 - 用于输入或外部组件的错误，可以同时提供一个错误消息。
    require(bool condition, string memory message);
    // 终止运行并恢复状态更改。
    revert();
    // 终止运行并恢复状态更改，可以同时提供一个解释性的字符串。
    revert(string memory reason);

    // 数学和密码学函数

    // 计算 (x + y) % k，加法会在任意精度下执行，并且加法的结果即使超过 2**256 也不会被截取。
    addmod(x, y, k)
    // 计算 (x * y) % k，乘法会在任意精度下执行，并且乘法的结果即使超过 2**256 也不会被截取。
    mulmod(x, y, k)
    // 计算输入的 Keccak-256 哈希值。
    keccak256(x)
    // 计算输入的 SHA-256 哈希值。
    sha256(x)
    // 计算输入的 RIPEMD-160 哈希值。
    ripemd160(x)
    // 利用椭圆曲线签名恢复与公钥相关的地址，错误返回零值。 函数参数对应于签名的 ECDSA 值：
    // r = 签名的前32字节
    // s = 签名的第二个32字节
    // v = 签名的最后1个字节
    ecrecover(hash, v, r, s)


    // 地址类型成员
    function addressF() public view {
        add address = 0x99;

        // 以 Wei 为单位的 地址类型 的余额。
        add.balance
        // 在 地址类型 的代码（可以是空的）。
        add.code
        // 地址类型 的代码哈希值
        add.codehash
        // 向 地址类型 发送数量为 amount 的 Wei，失败时抛出异常，发送 2300 gas 的矿工费，不可调节。
        payable(add).transfer(uint256 amount)
        // 向 地址类型 发送数量为 amount 的 Wei，失败时返回 false 2300 gas 的矿工费用，不可调节。
        payable(add).send(uint256 amount) returns (bool)
        // 用给定的数据发出低级别的 CALL，返回是否成功的结果和数据，发送所有可用 gas，可调节。
        payable(add).call(bytes memory) returns (bool, bytes memory)
        // 用给定的数据发出低级别的 DELEGATECALL，返回是否成功的结果和数据，发送所有可用 gas，可调节。
        payable(add).delegatecall(bytes memory) returns (bool, bytes memory)
        // 用给定的数据发出低级别的 STATICCALL，返回是否成功的结果和数据，发送所有可用 gas，可调节。
        payable(add).staticcall(bytes memory) returns (bool, bytes memory)
    }

    // 合约相关

    // 当前合约，可以明确转换为 地址类型
    this
    // 继承层次结构中更高一级的合约
    super
    // 销毁当前合约，将其资金发送到给定的 地址类型 并结束执行。 
    // 注意， selfdestruct 有一些从EVM继承的特殊性：
    //   接收合约的接收函数不会被执行。
    //   合约只有在交易结束时才真正被销毁， 任何一个 revert 可能会 "恢复" 销毁。
    selfdestruct(address payable recipient)

    // 类型信息
    // 表达式 type(X) 可以用来检索关于 X 类型的信息

    // 合约的名称。
    type(C).name
    // 内存字节数组，包含合约的创建字节码
    type(C).creationCode
    // 内存字节数组，包含合约运行时的字节码
    type(C).runtimeCode

    // 一个 bytes4 值，是包含给定接口 I 的 EIP-165 接口标识符。 
    // 这个标识符被定义为接口本身定义的所有函数选择器的 XOR，不包括所有继承的函数。
    type(I).interfaceId

    // 类型 T 所能代表的最小值。
    type(T).min
    // 类型 T 所能代表的最大值。
    type(T).max

    /*
    这些关键字在 Solidity 中是保留的。它们在将来可能成为语法的一部分：

    after， alias， apply， auto， byte， case， copyof， default， define， 
    final， implements， in， inline， let， macro， match， mutable， null， 
    of， partial， promise， reference， relocatable， sealed， sizeof， static，
    supports， switch， typedef， typeof， var。
    */


}
