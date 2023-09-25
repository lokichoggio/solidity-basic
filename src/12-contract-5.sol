// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// 抽象合约
/*
当合约中至少有一个函数没有被实现，或者合约没有为其所有的基本合约构造函数提供参数时， 合约必须被标记为 abstract。 
即使不是这种情况，合约仍然可以被标记为 abstract， 例如，当您不打算直接创建合约时。 
抽象（abstract）合约类似于 接口（interface）合约， 但是接口（interface）合约可以声明的内容更加有限。

如果一个合约继承自一个抽象合约，并且没有通过重写实现所有未实现的函数，那么它也需要被标记为抽象的。


*/

// 这个合约需要被定义为 abstract，因为函数 utterance() 被声明了， 但没有提供实现（没有给出实现体 { }）。
abstract contract Feline {
    function utterance() public virtual returns (bytes32);
}

// 抽象合约作为基类
contract Cat is Feline {
    function utterance() public pure override returns (bytes32) {
        return "miao2";
    }
}

// 接口合约

/*
接口（interface）合约类似于抽象（abstract）合约，但是它们不能实现任何函数。并且还有进一步的限制：

它们不能继承其他合约，但是它们可以继承其他接口合约。

在接口合约中所有声明的函数必须是 external 类型的，即使它们在合约中是 public 类型的。

它们不能声明构造函数。

它们不能声明状态变量。

它们不能声明修饰器。
*/

interface Token {
    enum TokenType {
        Fungible,
        NonFUngible
    }

    struct Coin {
        string obverse;
        string reverse;
    }

    function transfer(address recipient, uint amount) external ;
}

// 接口合约可以从其他接口合约继承。这与普通的继承有着相同的规则。

interface ParentA {
    function test() external returns (uint256);
}

interface ParentB {
    function test() external returns (uint256);
}

interface SubInterface is ParentA, ParentB {
    // 必须重新定义test，以便断言父类的含义是兼容的。
    function test() external override(ParentA, ParentB) returns (uint256);
}

// 库合约
/*
库合约可以看作是使用他们的合约的隐式的基类合约

与合约相比，库在以下方面受到限制：
    它们不能有状态变量
    它们不能继承，也不能被继承
    它们不能接收以太
    它们不能被销毁
*/

struct Data {
    mapping (uint => bool) flag;
}

library Set {
    // 注意第一个参数是 “storage reference”类型，
    // 因此在调用中参数传递的只是它的存储地址而不是内容。
    // 这是库函数的一个特性。如果该函数可以被视为对象的方法，
    // 则习惯称第一个参数为 `self` 。
    function insert(Data storage self, uint value) public returns (bool) {
        if (self.flag[value]) {
            return false;
        }
        self.flag[value] = true;
        return true;
    } 

    function remove(Data storage self, uint value) public returns (bool) {
        if (!self.flag[value]) {
            return false;
        }
        delete self.flag[value];
        return true;
    }

    function contains(Data storage self, uint value) public view returns (bool) {
        return self.flag[value];
    }
}

contract TestSet {
    Data data;

    function register(uint value) public {
        // 不需要库的特定实例就可以调用库函数，
        // 因为当前合约就是 “instance”。
        require(Set.insert(data, value));
    }

    function unregister(uint value) public {
        require(Set.remove(data, value));
    }

    function exist(uint value) public view returns (bool) {
        return Set.contains(data, value);
    }

    // 如果我们愿意，我们也可以在这个合约中直接访问 data.flags。
}

struct bigint {
    uint[] limbs;
}

library BigInt {
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }

    function limb(bigint memory a, uint index) internal pure returns (uint) {
        return index < a.limbs.length ? a.limbs[index] : 0;
    }

    function fromUint(uint x) internal pure returns (bigint memory r) {
        r.limbs = new uint[](1);
        r.limbs[0] = x;
    }

    function add(bigint memory a, bigint memory b) internal pure returns (bigint memory r) {
        r.limbs = new uint[](max(a.limbs.length, b.limbs.length));
        uint carry = 0;

        for (uint i = 0; i < r.limbs.length; ++i) {
            uint limbA = limb(a, i);
            uint limbB = limb(b, i);

            unchecked {
                r.limbs[i] = limbA + limbB + carry;
                
                if (limbA + limbB < limbA || (limbA + limbB == type(uint).max && carry > 0)) {
                    carry = 1;
                } else {
                    carry = 0;
                }
            }
        }

        // 进位
        if (carry > 0) {
            uint[] memory newLimbs = new uint[](r.limbs.length + 1);
            uint j;

            for (j = 0; j < r.limbs.length; ++j) {
                newLimbs[j] = r.limbs[j];
            }
            newLimbs[j] = carry;
            r.limbs = newLimbs;
        }
    }
}

contract TestBigInt {
    using BigInt for bigint;

    function f() public pure {
        bigint memory x = BigInt.fromUint(7);
        bigint memory y = BigInt.fromUint(type(uint).max);

        bigint memory z = x.add(y);

        assert(z.limb(1) > 0);
    }
}

// 库合约中的函数签名和选择器
library L {
    function f(uint256) external {}
}

contract C1 {
    function g() public pure returns (bytes4) {
        return L.f.selector;
    } 
}

// Using For
/*
指令 using A for B 可用于将函数（ A） 作为运算符附加到用户定义的值类型 或作为成员函数附加到任何类型（ B）。 
成员函数将调用它们的对象作为第一个参数 （类似于 Python 中的 self 变量）。 
运算符函数将接收操作数作为参数。
*/

library Search {
    function indexOf(uint[] storage self, uint value) public view returns (uint r) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == value) {
                return i;
            }
        }
        return type(uint).max;
    } 
}

using  Search for uint[];

contract C2 {
    uint[] public data;

    function append(uint value) public {
        data.push(value);
    } 

    function replace(uint from, uint to) public  {
        uint index = data.indexOf(from);
        if (index == type(uint).max) {
            data.push(to);
        } else {
            data[index] = to;
        }
    }
}