// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract C {
    string s = "Storage";

    function f(bytes calldata bc, string memory sm, bytes16 b) public view {
        string memory concatString = string.concat(s, string(bc), "Literal", sm);
        assert((bytes(s).length + bc.length + 7 + bytes(sm).length) == bytes(concatString).length);

        bytes memory concatBytes = bytes.concat(bytes(s), bc, bc[:2], "Literal", bytes(sm), b);
        assert((bytes(s).length + bc.length + 2 + 7 + bytes(sm).length + b.length) == concatBytes.length);
    }

    function f1(uint len) public pure {
        uint[] memory a = new uint[](7);

        bytes memory b = new bytes(len);

        assert(a.length == 7);

        assert(b.length == len);

        a[6] = 8;
    }

    function f2() public pure {
        // uint[] memory x = [uint(1), 3, 4];

        uint[] memory x = new uint[](3);
        x[0] = 1;
        x[1] = 2;
        x[2] = 3;
    }
}

contract ArrayContract {
    uint[2**20] aLotOfIntegers;

    // 请注意，下面不是一对动态数组，
    // 而是一个动态数组对（即长度为2的固定大小数组）。
    // 在 Solidity 中，T[k]和T[]总是具有T类型元素的数组，
    // 即使T本身是一个数组。
    // 正因为如此，bool[2][]是一个动态数组对，其元素是bool[2]。
    // 这与其他语言不同，比如C，
    // 所有状态变量的数据位置都是存储。
    bool[2][] pairsOfFlags;

    // newPairs被存储在memory中，这是公开合约函数参数的唯一可能性
    function setAllFlagPairs(bool[2][] memory newPairs) public {
        // 赋值到一个storage数组 会执行 newPairs 的拷贝
        // 并替换完整的数组 pairsOfFlags
        pairsOfFlags = newPairs;
    }

    struct StructType {
        uint[] contents;
        uint moreInfo;
    }

    StructType s;

    function f(uint[] memory c) public {
        // 在g中存储一个对s的引用
        StructType storage g = s;
        // 也改变了 s.moreInfo
        g.moreInfo = 2;
        // 指定一个拷贝，因为g.contents不是一个局部变量，而是一个局部变量的成员
        g.contents = c;
    }

    function setFlagPair(uint index, bool flagA, bool flagB) public {
        // 访问一个不存在的数组索引会引发一个异常
        pairsOfFlags[index][0] = flagA;
        pairsOfFlags[index][1] = flagB;
    }

    function changeFlagArraySize(uint newSize) public {
        // 使用push和pop是改变数组长度的唯一方法
        if (newSize < pairsOfFlags.length) {
            while (pairsOfFlags.length < newSize) {
                pairsOfFlags.pop();
            }
        } else if (newSize > pairsOfFlags.length) {
            while (pairsOfFlags.length < newSize) {
                pairsOfFlags.push();
            }
        }
    }

    function addFlag(bool[2] memory flag) public returns (uint) {
        pairsOfFlags.push(flag);
        return pairsOfFlags.length;
    }

    function clear() public {
        // 这些完全清除数组
        delete pairsOfFlags;
        delete aLotOfIntegers;
        // 这里有同样的效果
        pairsOfFlags = new bool[2][](0);
    }

    bytes byteData;

    function byteArrays(bytes memory data) public {
        // 字节数组 byte 是不同的，因为它们的存储没有填充，但可以与 uint8[] 相同
        byteData = data;
        for (uint i = 0; i < 7; i++) {
            byteData.push();
        }
        byteData[3] = 0x08;
        
        delete byteData[2];
    }

    function createMemoryArray(uint size) public pure returns (bytes memory) {
        // 使用 new 创建动态memory数组
        uint[2][] memory arrayOfPairs = new uint[2][](size);
    
        // 内联数组总是静态大小的，如果您只使用字面常数表达式，您必须至少提供一种类型
        arrayOfPairs[0] = [uint(1), 2];

        // 创建一个动态字节数组
        bytes memory b = new bytes(200);
        for (uint i = 0; i < b.length; i++) {
            b[i] = bytes1(uint8(i));
        }
        return b;
    }
}

// 悬空引用
// 当使用存储数组时，您需要注意避免悬空引用。 悬空引用是指一个指向不再存在的或已经被移动而未更新引用的内容的引用。 
// 例如，如果您将一个数组元素的引用存储在一个局部变量中， 然后从包含数组中使用 .pop()，就可能发生悬空引用
contract C1 {
    uint[][] public s;

    function f() public {
        s.push();

        // 存储一个指向s的最后一个数组元素的指针
        uint[] storage ptr = s[s.length -1];

        // 删除s的最后一个元素
        s.pop();

        // 写入已不在数组内的数组元素
        ptr.push(0x42);

        // 现在向s添加一个新元素不会添加一个空数组，而是产生一个长度为1的数组，元素是0x42
        s.push();

        assert(s[s.length - 1][0] == 0x42);
    }
}

contract C2 {
    uint[] s;
    uint[] t;

    constructor() {
        // 向存储数组添加初始值
        s.push(0x07);
        t.push(0x03);
    }

    function g() internal returns (uint[] storage) {
        s.pop();
        return t;
    }

    function f() public returns (uint[] memory) {
        // 下面将首先评估 ``s.push()` 到一个索引为1的新元素的引用。
        // 之后，调用 ``g`` 弹出这个新元素，导致最左边的数组元素成为一个悬空的引用。
        // 赋值仍然发生，并将写入 ``s`` 的数据区域之外。
        (s.push(), g()[0]) = (0x42, 0x17);

        // 随后对 ``s`` 的推送将显示前一个语句写入的值，
        // 即在这个函数结束时 ``s`` 的最后一个元素将有 ``0x42`` 的值。
        s.push();
        return s;
    }

    function get() public view returns (uint) {
        return s[s.length-1];
    }
}

// 小心处理对 bytes 数组元素的引用， 因为 bytes 数组的 .push() 操作可能会 在存储中从短布局切换到长布局
contract C3 {
    bytes public  x = "012423415415135";

    // function test() external returns (uint) {
    //     (x.push(), x.push()) = (0x01, 0x02);
    //     return x.length;
    // }

    function get() public view returns (uint) {
        return x.length;
    }
}

// 数组切片对于ABI解码在函数参数中传递的二级数据很有用
contract Proxy {
    // @dev 由代理管理的客户合约的地址，即本合约的地址
    address client;

    constructor(address client_) {
        client = client_;
    }

    /// 转发对 "setOwner(address)" 的调用，
    /// 该调用在对地址参数进行基本验证后由客户端执行。
    function forward(bytes calldata payload) external {
        bytes4 sig = bytes4(payload[:4]);

        // 由于截断行为，bytes4(payload)的表现是相同的。
        // bytes4 sig = bytes4(payload);
        if (sig == bytes4(keccak256("setOwner(address)"))) {
            address owner = abi.decode(payload[4:], (address));

            require(owner != address(0), "Address of owner cannot be zero.");
        }

        (bool status,) = client.delegatecall(payload);
        require(status, "Forwarded call failed.");
    } 
}