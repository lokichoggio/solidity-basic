// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// 函数内部调用
contract C {
    function g(uint a) public pure returns (uint ret) {
        return a + f();
    }

    function f() internal pure returns (uint ret) {
        return g(7);
    }

    function f1() public view  returns (uint ret) {
        uint b = this.g(8);
        return b;
    }
}

// 函数外部调用
contract InfoFeed {
    function info() public payable returns (uint ret) {
        return 42;
    }
}

contract Consumer {
    InfoFeed feed;

    function setFeed(InfoFeed addr) public {
        feed = addr;
    }

    function callFeed() public {
        // feed.info();
        
        // 当调用其他合约的函数时，您可以用特殊的选项 {value: 10, gas: 10000} 指定随调用发送的Wei或气体（gas）数量。 
        feed.info{value: 10, gas: 800}();
    }
}

// 带命名参数的函数调用
contract C1 {
    mapping (uint => uint) data;

    function set(uint key, uint value) public {
        data[key] = value;
    }

    function f() public {
        // set(key, value);
        set({value: 2, key: 3});
    }
}

// 函数定义中省略的名称
/*
函数声明中的参数和返回值的名称可以省略。 
那些名字被省略的参数仍然会出现在堆栈中，但是无法通过名字访问。 
省略的返回值名称仍然可以通过使用 return 语句向调用者返回一个值。
*/
contract C2 {
    // 省略参数名称
    function func(uint k, uint) public pure returns (uint) {
        return k;
    }
}

// 通过new创建合约
contract D {
    uint public x;

    constructor(uint a) payable {
        x = a;
    }
}

contract C3 {
    // // 将作为合约 C4 构造函数的一部分执行
    D d = new D(4);

    function createD(uint arg) public {
        D newD = new D(arg);
        newD.x();
    }

    function createAndEndowD(uint arg, uint amount) public payable {
        // 随合约的创建发送 ether
        D newD = new D{value: amount}(arg);
        newD.x();
    }
}

// 加盐合约创建
/*
当创建一个合约时，合约的地址是由创建合约的地址和一个计数器计算出来的， 这个计数器在每次创建合约时都会增加。
如果您指定了选项 salt （一个32字节的值）， 那么合约的创建将使用一种不同的机制来得出新合约的地址。


*/
contract E {
    uint public x;

    constructor(uint a) {
        x = a;
    }
}

contract C4 {
    function createDSalted(bytes32 salt, uint arg) public {
        // 这个复杂的表达式只是告诉您如何预先计算出地址。
        // 它只是用于说明问题。
        // 实际上您只需要 ``new D{salt: salt}(arg)``。

        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(E).creationCode,
                abi.encode(arg)
            ))
        )))));

        D d = new D{salt: salt}(arg);
        require(address(d) == predictedAddress);
    } 
}

// 赋值

// 解析赋值和返回多个值 元组 tuple
contract C5 {
    uint index;

    function f() public pure returns (uint, bool, uint) {
        return (7, true, 2);
    }

    function g() public {
        // 用类型声明的变量，并从返回的元组中分配，
        // 不是所有的元素都必须被指定（但数量必须匹配）。
        (uint x, , uint y) = f();
        // 交换数值的常见技巧 -- 对非数值存储类型不起作用。
        (x, y) = (y, x);
        // 元素可以不使用（也适用于变量声明）。
        // 将index设置为 7
        (index, , ) = f();
    }
}

// 数组和结构体的复杂情况
/*
在下面的例子中，调用 g(x) 对 x 没有影响， 因为它在内存中创建了一个独立的存储值的副本。
然而， h(x) 成功地修改了 x， 因为传递了一个引用而不是一个拷贝。
*/
contract C6 {
    uint[20] x;

    function g(uint[20] memory y) internal pure {
        y[2] = 3;
    }

    function h(uint[20] storage y) internal {
        y[3] = 4;
    }
 
    function f() public {
        g(x);
        h(x);
    }
}

// 作用域和声明
// 下面的例子在编译时不会出现警告，因为这两个变量的名字虽然相同，但作用域不同。
contract C7 {
    function minimalScoping() pure public {
        {
            uint same;
            same = 1;
        }

        {
            uint same;
            same = 3;
        }
    }
}


contract C8 {

    // 告警
    function f() pure public returns (uint) {
        uint x = 1;

        {
            // this will assign to the outer variable
            x = 2;
            // This declaration shadows an existing declaration.
            // uint x;
        }

        // x has value 2
        return x;
    }

    function f1() public pure returns (uint) {
        // x = 2;
        uint x;
        return x;
    }
}

// 检查或不检查的算术
contract C9 {
    // 调用 f(2, 3) 将返回 2**256-1
    function f(uint a, uint b) public pure returns (uint) {
        unchecked {
            // 这个减法将在下溢时被包起来。
            return a - b;
        }
    }

    // g(2, 3) 将导致一个失败的断言。
    function g(uint a, uint b) public pure returns (uint) {
        // 这个减法在下溢时将被还原。
        return a - b;
    }
}

// 错误处理：Assert, Require, Revert and Exceptions
/*
Solidity 使用状态恢复异常来处理错误。 
这种异常将撤消对当前调用（及其所有子调用）中的状态所做的所有更改， 并且还向调用者标记错误。

通过 assert 引起Panic异常和通过 require 引起Error异常
*/

// 下面的例子显示了如何使用 require 来检查输入的条件 和 assert 进行内部错误检查。

contract Sharer {
    function sendHalf(address payable addr) public payable returns (uint balance) {
        require(
            msg.value % 2 == 0,
            "Even value required."
        );

        uint balanceBeforeTransfer = address(this).balance;
        addr.transfer(msg.value / 2);

        // 由于转账失败后抛出异常并且不能在这里回调，
        // 因此我们应该没有办法 仍然有一半的钱。
        assert(
            address(this).balance == balanceBeforeTransfer - msg.value /2
        );

        return address(this).balance;
    }
}

/*
下面的例子显示了如何将一个错误字符串和一个自定义的错误实例 与 revert 和相应的 require 一起使用。

if (!condition) revert(...); 和 require(condition, ...); 这两种方式是等价的， 
只要 revert 和 require 的参数没有副作用，比如说它们只是字符串。
*/
contract VendingMachine {
    address owner;

    error Unauthorized();

    function buy(uint amount) public payable {
        if (amount > msg.value / 2 ether) {
            revert("Not enough Ether provided.");
        }

        // 另一种写法
        require(
            amount <= msg.value / 2 ether,
            "Not enough Ether provided."
        );

        // 执行购买
    }

    function withdraw() public {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        payable(msg.sender).transfer(address(this).balance);
    }
}

// 外部调用的失败可以用 try/catch 语句来捕获

interface DataFeed {
    function getData(address token) external returns (uint value);
}

contract FeedConsumer {
    DataFeed feed;
    uint errorCount;

    function rate(address token) public returns (uint value, bool success) {
        // 如果有10个以上的错误，就永久停用该机制。
        require(errorCount < 10);

        try feed.getData(token) returns (uint v) {
            return (v, true);
        } catch Error(string memory /*reason*/) { // revert("reasonString") 或 require(false, "reasonString") 造成的 （或内部错误造成的）。
            // 如果在getData中调用revert，
            // 并且提供了一个原因字符串，
            // 则执行该命令。
            errorCount++;
            return (0, false);
        } catch Panic(uint /*errorCode*/) { //如果错误是由Panic异常引起的， 例如由失败的 assert、除以0、无效的数组访问、算术溢出和其他原因引起的，
            // 在发生Panic异常的情况下执行，
            // 即出现严重的错误，如除以零或溢出。
            // 错误代码可以用来确定错误的种类。
            errorCount++;
            return (0, false);
        } catch (bytes memory /*lowLevelData*/) { // 如果错误签名与其他子句不匹配， 或者在解码错误信息时出现了错误，或者没有与异常一起提供错误数据， 那么这个子句就会被执行
            // 在使用revert()的情况下，会执行这个命令。
            errorCount++;
            return (0, false);
        }
    }
}