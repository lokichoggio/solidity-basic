// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*
盲拍

在 竞标期间，竞标者实际上并没有发送他们的出价， 而只是发送一个哈希版本的出价。 由于目前几乎不可能找到两个（足够长的）值， 其哈希值是相等的，因此竞标者可通过该方式提交报价。 在竞标结束后， 竞标者必须公开他们的出价：他们发送未加密的值， 合约检查出价的哈希值是否与竞标期间提供的值相同。

另一个挑战是如何使拍卖同时做到 绑定和秘密 ： 唯一能阻止竞标者在赢得拍卖后不付款的方式是，让他们将钱和竞标一起发出。 但由于资金转移在以太坊中不能被隐藏，因此任何人都可以看到转移的资金。

下面的合约通过接受任何大于最高出价的值来解决这个问题。 当然，因为这只能在揭示阶段进行检查，有些出价可能是 无效 的， 而这是有目的的（它甚至提供了一个明确的标志，以便在高价值的转移中进行无效的出价）： 竞标者可以通过设置几个或高或低的无效出价来迷惑竞争对手。
*/

contract BlindAuction {
    // 哈希版本的出价
    struct Bid {
        bytes32 blindedBid;  // 哈希值
        uint deposit;  // 出价
    }

    address payable public beneficiary;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;

    mapping (address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    // 允许取回以前的竞标。
    mapping (address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    /// 该函数被过早调用。
    /// 在 `time` 时间再试一次。
    error TooEarly(uint time);
    /// 该函数被过晚调用。
    /// 它不能在 `time` 时间之后被调用。
    error TooLate(uint time);
    /// 函数 auctionEnd 已经被调用。
    error AuctionEndAlreadyCalled();

    modifier onlyBefore(uint time) {
        if (block.timestamp >= time) {
            revert TooLate(time);
        }
        _;
    }

    modifier onlyAfter(uint time) {
        if (block.timestamp <= time) {
            revert TooEarly(time);
        }
        _;
    }

    constructor(uint biddingTime, uint revealTime, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        biddingEnd = block.timestamp + biddingTime;
        revealEnd = biddingEnd + revealTime;
    }

    /// 可以通过 `_blindedBid` = keccak256(value, fake, secret)
    /// 设置一个盲拍。
    /// 只有在出价披露阶段被正确披露，已发送的以太币才会被退还。
    /// 如果与出价一起发送的以太币至少为 "value" 且 "fake" 不为真，则出价有效。
    /// 将 "fake" 设置为 true ，
    /// 然后发送满足订金金额但又不与出价相同的金额是隐藏实际出价的方法。
    /// 同一个地址可以放置多个出价。
    function bid(bytes32 blindedBid) external payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid: blindedBid,
            deposit: msg.value
        }));
    }

    function placeBid(address bidder, uint value) internal returns (bool success) {
        if (value <= highestBid) {
            return false;
        }

        if (highestBidder != address(0)) {
            // 返还之前的最高出价
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// 披露你的盲拍出价。
    /// 对于所有正确披露的无效出价以及除最高出价以外的所有出价，您都将获得退款。
    function reveal(uint[] calldata values, bool[] calldata fakes, bytes32[] calldata secrets) external onlyAfter(biddingEnd) onlyBefore(revealEnd) {
        uint length = bids[msg.sender].length;
        require(length == values.length);
        require(length == fakes.length);
        require(length == secrets.length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint value, bool fake, bytes32 secret) = (values[i], fakes[i], secrets[i]);
            if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value, fake, secret))) {
                // 出价未能正确披露。
                // 不返还订金。
                continue;
            }

            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value)) {
                    refund -= value;
                }
            }
            // 使发送者不可能再次认领同一笔订金。
            bidToCheck.blindedBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }

    /// 撤回出价过高的竞标。
    function withdraw() external {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 这里很重要，首先要设零值。
            // 因为，作为接收调用的一部分，
            // 接收者可以在 `transfer` 返回之前重新调用该函数。
            //（可查看上面关于 条件 -> 影响 -> 交互 的标注）
            pendingReturns[msg.sender] = 0;

            payable(msg.sender).transfer(amount);
        }
    }

    /// 结束拍卖，并把最高的出价发送给受益人。
    function auctionEnd() external onlyAfter(revealEnd) {
        if (ended) {
            revert AuctionEndAlreadyCalled();
        }

        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
}