// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract Oracle {
    struct Request {
        bytes data;
        function(uint) external callback;
    }

    Request[] private requests;

    event NewRequest(uint);

    function query(bytes memory data, function(uint) external callback) public {
        requests.push(Request(data, callback));
        emit NewRequest(requests.length-1);
    }

    function reply(uint requestID, uint response) public {
        // 这里要检查的是调用返回是否来自可信的来源
        requests[requestID].callback(response);
    }
}

contract OracleUser {
    // 已知的合约地址
    Oracle constant private ORACLE_CONST = Oracle(address(0x00000000219ab540356cBB839Cbe05303d7705Fa));
    uint private exchangeRate;

    function oracleResponse(uint response) public {
        require(
            msg.sender == address(ORACLE_CONST), 
            "Only oracle can call this."
        );

        exchangeRate = response;
    }

    function buySomething() public {
        ORACLE_CONST.query("USD", this.oracleResponse);
    }
}
