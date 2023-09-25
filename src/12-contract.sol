// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// 如果一个合约想创建另一个合约，创建者必须知道所创建合约的源代码（和二进制）。 这意味着，循环的创建依赖是不可能的。
contract OwnedToken {
    // `TokenCreator` 是如下定义的合约类型。
    // 不创建新合约的话，也可以引用它。
    TokenCreator creator;
    address owner;
    bytes32 name;

    // 这是注册 creator 和设置名称的构造函数。
    constructor(bytes32 name_) {
        // 状态变量通过其名称访问，
        // 而不是通过例如 `this.owner` 的方式访问。
        // 函数可以直接或通过 `this.f` 访问。
        // 但后者提供了一个对函数的外部可视方法。
        // 特别是在构造函数中，您不应该从外部访问函数，
        // 因为该函数还不存在。
        // 详见下一节。
        owner = msg.sender;
        // 我们进行了从 `address` 到 `TokenCreator` 的显式类型转换，
        // 并假定调用合约的类型是 `TokenCreator`，
        // 没有真正的方法来验证，
        // 这并没有创建一个新的合约。
        creator = TokenCreator(msg.sender);
        name = name_;
    }

    function changeName(bytes32 newName) public {
        // 只有创建者可以改变名称。
        // 我们根据合约的地址进行比较，
        // 它可以通过显式转换为地址来检索。
        if (msg.sender == address(creator)) {
            name = newName;
        } 
    }

    function transfer(address newOwner) public {
        // 只有当前所有者才能发送 token。
        if (msg.sender != owner) {
            return;
        }

        //
        if (creator.isTokenTransferOK(owner, newOwner)) {
            owner = newOwner;
        }

    }

}

contract TokenCreator {
    function createToken(bytes32 name) public returns (OwnedToken tokenAddress) {
        // 创建一个新的 `Token` 合约并返回其地址。
        // 从JavaScript方面来看，
        // 这个函数的返回类型是 `address`，
        // 因为这是ABI中最接近的类型。
        return new OwnedToken(name);
    }

    function changeName(OwnedToken tokenAddress, bytes32 name) public {
        // 同样，`tokenAddress` 的外部类型是简单的 `address`。
        tokenAddress.changeName(name);
    }

    function isTokenTransferOK(address currentOwner, address newOwner) public pure returns (bool ok) {
        // 检查一个任意的条件，看是否应该进行转移。
        return keccak256(abi.encodePacked(currentOwner, newOwner))[0] == 0x7f;
    }
}

// 可见性
contract C {
    uint private data;

    function f(uint a) private pure returns (uint b) {
        return a + 1;
    }

    function setData(uint a) public {
        data = a;
    }

    function getData() public view returns (uint) {
        return data;
    }

    function compute(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }
}

contract D {
    function readData() public {
        uint local;
        C c = new C();
        // 错误：成员 `f` 不可见
        // uint local = c.f(7);
        c.setData(3);
        local = c.getData();
        // 错误：成员 `compute` 不可见
        // uint local2 = c.compute(3, 5);
    }
}

contract E is C {
    function g() public pure {
        // C c = new C();
        uint local;
        local = compute(3, 5);
    }
}

// 函数修饰器
contract owned {
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    // 这个合约只定义了一个修饰器，但没有使用它：
    // 它将在派生合约中使用。
    // 修饰器所修饰的函数体会被插入到特殊符号 `_;` 的位置。
    // 这意味着，如果所有者调用这个函数，这个函数就会被执行，
    // 否则就会抛出一个异常。
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

contract destructible is owned {
    // 这个合约从 `owned` 合约继承了 `onlyOwner` 修饰器，
    // 并将其应用于 `destroy` 函数，
    // 只有在合约里保存的 owner 调用 `destroy` 函数，才会生效。
    function destroy() public onlyOwner {
        // 这将报告一个由于废弃的 selfdestruct 而产生的警告
        selfdestruct(owner);
    }
}

contract priced {
    // 修饰器可以接受参数：
    modifier costs(uint price) {
        if (msg.value >= price) {
            _;
        }
    }
}

contract Register is priced, destructible {
    mapping (address => bool) registeredAddress;
    uint price;

    constructor(uint initialPrice) {
        price = initialPrice;
    }

    // 在这里使用关键字 `payable` 非常重要，
    // 否则函数会自动拒绝所有发送给它的以太币。
    function register() public payable costs(price) {
        registeredAddress[msg.sender] = true;
    }

    function changePrice(uint price_) public onlyOwner {
        price = price_;
    }
}

contract Mutex {
    bool locked;

    modifier noReentrancy() {
        require(
            !locked,
            "Reentrant call."
        );
        locked = true;
        _;
        locked = false;
    }

    // 这个函数受互斥量保护，这意味着 `msg.sender.call` 中的重入调用不能再次调用  `f`。
    // `return 7` 语句指定返回值为 7，但修饰器中的语句 `locked = false` 仍会执行。
    function f() public noReentrancy returns (uint) {
        (bool success, ) = msg.sender.call("");
        require(success);
        return 7;
    }
}

// Constant 和 Immutable 状态变量
/*
变量在合约构建完成后不能被修改。 对于 constant 变量，其值必须在编译时固定， 
而对于 immutable 变量，仍然可以在构造时分配。
*/

uint constant X = 32**32 + 8;

contract C1 {
    string constant TEXT = "abc";
    bytes32 constant MY_HASH = keccak256("abc");
    uint immutable decimals;
    uint immutable maxBalance;
    address immutable owner = msg.sender;

    constructor(uint decimals_, address ref) {
        decimals = decimals_;
        // 对不可变量的赋值甚至可以访问一些全局属性。
        maxBalance = ref.balance;
    }

    function isBalanceTooHigh(address other) public view returns (bool) {
        return other.balance > maxBalance;
    }
}

// 特殊函数
// receive
/*
一个合约最多可以有一个 receive 函数， 使用 receive() external payable { ... } 来声明。
（没有 function 关键字）。 这个函数不能有参数，不能返回任何东西，必须具有 external 的可见性和 payable 的状态可变性。 
它可以是虚拟的，可以重载，也可以有修饰器。

receive 函数是在调用合约时执行的，并带有空的 calldata。 
这是在纯以太传输（例如通过 .send() 或 .transfer() ）时执行的函数。 
如果不存在这样的函数，但存在一个 payable 类型的 fallback函数， 这个 fallback 函数将在纯以太传输时被调用。 
如果既没有直接接收以太（receive函数），也没有 payable 类型的 fallback 函数， 那么合约就不能通过不代表支付函数调用的交易接收以太币，还会抛出一个异常。
*/
contract Sink {
    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// fallback
/*
一个合约最多可以有一个 fallback 函数，使用 fallback () external [payable] 或 fallback (bytes calldata input) external [payable] returns (bytes memory output) 来声明（都没有 function 关键字）。 
这个函数必须具有 external 的函数可见性。 一个 fallback 函数可以被标记为 virtual，可以标记为 override，也可以有修饰器。
*/
contract Test {
    uint x;

    // 所有发送到此合约的消息都会调用此函数（没有其他函数）。
    // 向该合约发送以太币将引起异常，
    // 因为fallback函数没有 `payable` 修饰器。
    fallback() external { x = 1; }
}

contract TestPayable {
    uint x;
    uint y;

    // 所有发送到此合约的消息都会调用这个函数，
    // 除了普通的以太传输（除了receive函数，没有其他函数）。
    // 任何对该合约的非空的调用都将执行fallback函数（即使以太与调用一起被发送）。
    fallback() external payable {
        x = 1;
        y = msg.value;
    }

    // 这个函数是为纯以太传输而调用的，
    // 即为每一个带有空calldata的调用。
    receive() external payable {
        x = 2;
        y = msg.value;
    }
}

contract Caller {
    function callTest(Test test) public returns (bool) {
        (bool success, ) = address(test).call(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);
        // 结果是 test.x 等于 1。

        // address(test)将不允许直接调用 ``send``，
        // 因为 ``test`` 没有可接收以太的fallback函数。
        // 它必须被转换为 ``address payable`` 类型，才允许调用 ``send``。
        address payable testPayable = payable(address(test));

        // 如果有人向该合约发送以太币，转账将失败，即这里返回false。
        return testPayable.send(2 ether);
    }

    function callTestPayable(TestPayable test) public returns (bool) {
        (bool success, ) = address(test).call(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);
        // 结果是 test.x 等于 1，test.y 等于 0。

        (success, ) = address(test).call{value: 1}(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);
        // 结果是 test.x 等于 1，test.y 等于 1。

        // 如果有人向该合约发送以太币，TestPayable的receive函数将被调用。
        // 由于该函数会写入存储空间，它需要的气体比简单的 ``send`` 或 ``transfer`` 要多。
        // 由于这个原因，我们必须要使用一个低级别的调用。
        (success, ) = address(test).call{value: 2 ether}("");
        require(success);
        // 结果是 test.x 等于 2，test.y 等于 2 个以太。

        return true;
    }
}

// 函数重载
/*
一个合约可以有多个同名的，但参数类型不同的函数。 这个过程被称为 "重载"，也适用于继承的函数
*/
contract C2 {
    function f(uint value) public pure returns (uint out) {
        out = value;
    }

    function f(uint value, bool really) public pure returns (uint out) {
        if (really) {
            out = value;
        }
    }
}

// 继承
contract Owned {
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }
}

// 使用 `is` 从另一个合约派生。派生合约可以访问所有非私有成员，
// 包括内部函数和状态变量，但无法通过 `this` 来外部访问。
contract Destructible is Owned {
    // 关键字 `virtual` 意味着该函数可以在派生类中改变其行为（"重载"）。
    function destroy() virtual  public {
        if (msg.sender == owner) {
            // 这将报告一个由于废弃的 selfdestruct 而产生的警告
            selfdestruct(owner);
        }
    }
}

// 这些抽象合约仅用于给编译器提供接口。
// 注意函数没有函数体。
// 如果一个合约没有实现所有函数，则只能用作接口。
abstract contract Config {
    function lookup(uint id) public virtual returns (address addr);
}

abstract contract NameReg {
    function register(bytes32 name) public virtual;
    function unregister() public virtual;
}

// 多重继承是可能的。请注意， `Owned` 也是 `Destructible` 的基类，
// 但只有一个 `Owned` 实例（就像 C++ 中的虚拟继承）。
contract Named is Owned, Destructible {
    constructor(bytes32 name) {
        Config config = Config(0xD5f9D8D94886E70b06E474c3fB14Fd43E2f23970);
        NameReg(config.lookup(1)).register(name);
    }

    // 函数可以被另一个具有相同名称和相同数量/类型输入的函数重载。
    // 如果重载函数有不同类型的输出参数，会导致错误。
    // 本地和基于消息的函数调用都会考虑这些重载。
    // 如果您想重载这个函数，您需要使用 `override` 关键字。
    // 如果您想让这个函数再次被重载，您需要再指定 `virtual` 关键字。
    function destroy() public virtual override {
        if (msg.sender == owner) {
            Config config = Config(0xD5f9D8D94886E70b06E474c3fB14Fd43E2f23970);
            NameReg(config.lookup(1)).unregister();
            // 仍然可以调用特定的重载函数。
            Destructible.destroy();
        }
    }
}

// 如果构造函数接受参数，
// 则需要在声明（合约的构造函数）时提供，
// 或在派生合约的构造函数位置以修饰器调用风格提供（见下文）。
contract PriceFeed is Owned, Destructible, Named("GoldFeed") {
    uint info;

    function updateInfo(uint newInfo) public {
        if (msg.sender == owner) {
            info = newInfo;
        }
    }

    // 在这里，我们只指定了 `override` 而没有 `virtual`。
    // 这意味着从 `PriceFeed` 派生出来的合约不能再改变 `destroy` 的行为。
    function destroy() public override(Destructible, Named) {
        Named.destroy();
    }

    function get() public view returns (uint r) {
        return info;
    }
}

// 在上面，我们调用 Destructible.destroy() 来 "转发" 销毁请求。 这样做的方式是有问题的

contract Base1 is Destructible {
    function destroy() public virtual override {
        Destructible.destroy();
    }
}

contract Base2 is Destructible {
    function destroy() public virtual override {
        Destructible.destroy();
    }
}

// 调用 Final.destroy() 时会调用最后的派生重载函数 Base2.destroy， 但是会绕过 Base1.destroy， 
// 解决这个问题的方法是使用 super
contract Final is Base1, Base2 {
    function destroy() public override(Base1, Base2) {
        Base2.destroy();
    }
}

// 如果 Base2 调用 super 的函数，它不会简单在其基类合约上调用该函数。 
// 相反，它在最终的继承关系图谱的上一个基类合约中调用这个函数， 所以它会调用 Base1.destroy() （注意最终的继承序列是——从最远派生合约开始：Final, Base2, Base1, Destructible, ownerd）。 
// 在类中使用 super 调用的实际函数在当前类的上下文中是未知的，尽管它的类型是已知的。 
// 这与普通的虚拟方法查找类似。
contract Final2 is Base1, Base2 {
    function destroy() public override(Base1, Base2) {
        super.destroy();
    }
}

// 函数重载
/*
如果基函数被标记为 virtual，则可以通过继承合约来改变其行为。 
被重载的函数必须在函数头中使用 override 关键字。 
重载函数只能将被重载函数的可见性从 external 改为 public。 
可变性可以按照以下顺序改变为更严格的可变性。 
nonpayable 可以被 view 和 pure 重载。 view 可以被 pure 重写。 
payable 是一个例外，不能被改变为任何其他可变性。
*/

// 改变函数可变性和可见性
contract Base {
    function foo() virtual external view {}
}

contract Middle is Base {}

contract Inherited is Middle {
    function foo() override public pure {}
}


/*
对于多重继承，必须在 override 关键字后明确指定定义同一函数的最多派生基类合约

如果函数被定义在一个共同的基类合约中， 或者在一个共同的基类合约中有一个独特的函数已经重载了所有其他的函数， 则不需要明确的函数重载指定符。
*/
contract Base1 {
    function foo() virtual public {}
}

contract Base2 {
    function foo() virtual public {}
}

contract Inherited1 is Base1, Base2 {
    // 派生自多个定义 foo() 函数的基类合约，
    // 所以我们必须明确地重载它
    function foo() public override(Base1, Base2) {}
} 

// 修饰器重载
contract Base3 {
    modifier foo() virtual {_;}
}

contract Base4 {
    modifier foo() virtual {_;}
}

contract Inherited2 is Base3, Base4 {
    modifier foo() override(Base3, Base4) {_;}
}

// 构造函数
// 参数
contract B {
    uint x;
    constructor(uint x_) {
        x = x_;
    }
}

// 要么直接在继承列表中指定...
contract Derived1 is B(7) {
    constructor() {}
}

// 或者通过派生构造函数的一个 "修改器"……
contract Derived2 is B {
    constructor(uint y) B(y*y) {}
}

// 或者将合约声明为abstract类型……
abstract contract Derived3 is Base {}

// 并让下一个具体的派生合约对其进行初始化。
contract DerivedFromDerived is Derived3 {
    constructor() B(10+10) {}
}

// 多重继承与线性化
/*
您必须按照从 “最接近的基类”（most base-like）到 “最远的继承”（most derived）的顺序来指定所有的基类。 
注意，这个顺序与Python中使用的顺序相反。

另一种简化的解释方式是，当一个函数被调用时， 它在不同的合约中被多次定义，给定的基类以深度优先的方式从右到左（Python中从左到右）进行搜索， 在第一个匹配处停止。
如果一个基类合约已经被搜索过了，它就被跳过。



*/

/*
代码编译出错的原因是 C 要求 X 重写 A （因为定义的顺序是 A, X ）， 但是 A 本身要求重写 X， 这是一种无法解决的冲突。
*/
contract X {}
contract A is X {}
// 这段代码不会编译, Linearization of inheritance graph impossible
// contract D is A, X {}

contract B1 {
    constructor() {}
}

contract B2 {
    constructor() {}
}

// 构造函数按以下顺序执行：
//  1 - B1
//  2 - B2
//  3 - D1
contract D1 is B1, B2 {
    constructor() B1() B2() {}
}

// 构造函数按以下顺序执行：
//  1 - B2
//  2 - B1
//  3 - D2
contract D2 is B2, B1 {
    constructor() B2() B1() {}
}

// 构造函数仍按以下顺序执行：
//  1 - B2
//  2 - B1
//  3 - D3
contract D3 is B2, B1 {
    constructor() B1() B2() {}
}


