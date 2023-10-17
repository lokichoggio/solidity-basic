// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// So why do we care about all this encoding stuff?

// In order to call a function using only the data field of call, we need to encode:
// The function name
// The parameters we want to add
// Down to the binary level

// Now each contract assigns each function it has a function ID. This is known as the "function selector".
// The "function selector" is the first 4 bytes of the function signature.
// The "function signature" is a string that defines the function name & parameters.
// Let's look at this

contract CallAnything {
    address public s_someAddress;
    uint256 public s_amount;

    function transfer(address someAddress, uint256 amount) public {
        s_someAddress = someAddress;
        s_amount = amount;
    }

    // We can get a function selector as easy as this.
    // "transfer(address,uint256)" is our function signature
    // and our resulting function selector of "transfer(address,uint256)" is output from this function
    // one thing to note here is that there shouldn't be any spaces in "transfer(address,uint256)"
    function getSelectorOne() public pure returns (bytes4 selector) {
        // 0xa9059cbb
        selector = bytes4(keccak256(bytes("transfer(address,uint256)")));
    }

    // 0xd9145CCE52D386f254917e481eB44e9943F39138 123
    // 0xa9059cbb000000000000000000000000d9145cce52d386f254917e481eb44e9943f39138000000000000000000000000000000000000000000000000000000000000007b
    function getDataToCallTransfer(address someAddress, uint256 amount) public pure returns (bytes memory) {
        return abi.encodeWithSelector(getSelectorOne(), someAddress, amount);
    }

    // @param 0xd9145CCE52D386f254917e481eB44e9943F39138 123
    // @return 0x00000000 true
    // s_someAddress => 0xd9145CCE52D386f254917e481eB44e9943F39138
    // s_amount => 123
    function callTransferFunctionDirectly(address someAddress, uint256 amount) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) =
            address(this).call(abi.encodeWithSelector(getSelectorOne(), someAddress, amount));
        return (bytes4(returnData), success);
    }

    // Using encodeWithSignature
    // @param 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 222
    // @return 0x00000000 true
    // s_someAddress => 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // s_amount => 222
    function callTransfreFunctionDirectlyTwo(address someAddress, uint256 amount) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) =
            address(this).call(abi.encodeWithSignature("transfer(address,uint256)", someAddress, amount));
        return (bytes4(returnData), success);
    }

    // We can also get a function selector from data sent into the call
    // 0xa9059cbb
    function getSelectorTwo() public view returns (bytes4 selector) {
        bytes memory functionCallData = abi.encodeWithSignature("transfer(address,uint256)", address(this), 123);

        selector =
            bytes4(bytes.concat(functionCallData[0], functionCallData[1], functionCallData[2], functionCallData[3]));
    }

    // Another way to get data (hard coded)
    // 0xa9059cbb000000000000000000000000d9145cce52d386f254917e481eb44e9943f39138000000000000000000000000000000000000000000000000000000000000007b
    function getCallData() public view returns (bytes memory) {
        return abi.encodeWithSignature("transfer(address,uint256)", address(this), 123);
    }

    // Pass this:
    // 0xa9059cbb000000000000000000000000d7acd2a9fd159e69bb102a1ca21c9a3e3a5f771b000000000000000000000000000000000000000000000000000000000000007b
    // This is output of `getCallData()`
    // This is another low level way to get function selector using assembly
    // You can actually write code that resembles the opcodes using the assembly keyword!
    // This in-line assembly is called "Yul"
    // It's a best practice to use it as little as possible - only when you need to do something very VERY specific
    // 0xa9059cbb
    function getSelectorThree(bytes calldata functionCallData) public pure returns (bytes4 selector) {
        assembly {
            selector := calldataload(functionCallData.offset)
        }
    }

    // Another way to get your selector with "this" keywork
    // 0xa9059cbb
    function getSelectorFour() public pure returns (bytes4 selector) {
        return this.transfer.selector;
    }

    // Just a function that gets the signature
    function getSignatureOne() public pure returns (string memory) {
        return "transfer(address,uint256)";
    }
}

contract CallFuntionWithoutContract {
    address public s_selectorAndSignatureAddress;

    constructor(address add) {
        s_selectorAndSignatureAddress = add;
    }

    // pass in 0xa9059cbb000000000000000000000000d7acd2a9fd159e69bb102a1ca21c9a3e3a5f771b000000000000000000000000000000000000000000000000000000000000007b
    // you could use this to change state
    // return 0xa9059cbb true
    function callFunctionDirectly(bytes calldata callData) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) =
            s_selectorAndSignatureAddress.call(abi.encodeWithSignature("getSelectorThree(bytes)", callData));
        return (bytes4(returnData), success);
    }

    // @return 0xa9059cbb true
    function staticCallFunctionDirectly() public returns (bytes4, bool) {
        (bool success, bytes memory returnData) =
            s_selectorAndSignatureAddress.call(abi.encodeWithSignature("getSelectorOne()"));
        return (bytes4(returnData), success);
    }

    // @param 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 333
    // @return true 0x00000000
    // s_someAddress => 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // s_amount => 333
    function callTransferFunctionDirectlyThree(address someAddress, uint256 amount) public returns (bytes4, bool) {
        (bool success, bytes memory returnData) = s_selectorAndSignatureAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", someAddress, amount)
        );
        return (bytes4(returnData), success);
    }
}
