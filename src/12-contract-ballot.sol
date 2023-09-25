// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/*
投票

它实现了一个投票合约。当然， 电子投票的主要问题是如何将投票权分配给正确的人以及如何防止人为操纵。 我们不会在这里解决所有的问题，但至少我们会展示如何进行委托投票， 与此同时，使计票是 自动且完全透明的。

我们的想法是为每张选票创建一份合约， 为每个选项提供一个简称。 然后，作为合约的创造者——即主席， 将给予每个地址单独的投票权。

地址后面的人可以选择自己投票，或者委托给他们信任的人来投票。

在投票时间结束时， winningProposal() 将返回拥有最大票数的提案。

当前，为了把投票权分配给所有参与者，需要执行很多交易。 此外，如果两个或更多的提案有相同的票数， winningProposal() 无法登记平局。
*/

contract Ballot {
    // 它用来表示一个选民。
    struct Voter {
        uint weight;  // 计票的权重
        bool voted;  // 若为真，代表该人已投票
        address delegate;  // 被委托人
        uint vote;  // 投票提案的索引
    }

    // 提案的类型
    struct Proposal {
        bytes32 name;  // 简称（最长32个字节）
        uint voteCount;  // 得票数
    }

    address public chairperson;

    // 这声明了一个状态变量，为每个可能的地址存储一个 `Voter`。
    mapping (address => Voter) public voters;

    // 一个 `Proposal` 结构类型的动态数组。
    Proposal[] public proposals;

    // 为 `proposalNames` 中的每个提案，创建一个新的（投票）表决
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // 给予 `voter` 在这张选票上投票的权利。
    // 只有 `chairperson` 可以调用该函数。
    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );

        require(
            !voters[voter].voted,
            "The voter already voted."
        );

        require(voters[voter].weight == 0);

        voters[voter].weight = 1;
    }

    // 把您的投票委托给投票者 `to`。
    function delegate(address to) external {
        // 委托人
        Voter storage sender = voters[msg.sender];

        require(
            sender.weight != 0,
            "You have no right to vote"
        );

        require(
            !sender.voted,
            "You already voted."
        );

        require(
            to != msg.sender,
            "Self-delegation is disallowed."
        );

        // 委托是可以传递的，只要被委托者 `to` 也设置了委托。
        // 一般来说，这样的循环委托是非常危险的，因为如果传递的链条太长，
        // 可能需要消耗的gas就会超过一个区块中的可用数量。
        // 这种情况下，委托不会被执行。
        // 但在其他情况下，如果形成闭环，则会导致合约完全被 "卡住"。
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // 不允许闭环委托
            require(to != msg.sender, "Found loop in delegation.");
        }

        // 受托人
        Voter storage delegate_ = voters[to];

        // 投票者不能将投票权委托给不能投票的账户。
        require(delegate_.weight >= 1);

        // 委托
        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
             // 若被委托者已经投过票了，直接增加得票数。
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // 若被委托者还没投票，增加委托者的权重。
            delegate_.weight += sender.weight;
        }
    }

    // 把您的票(包括委托给您的票), 投给提案 `proposals[proposal].name`。
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];

        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");

        sender.voted = true;
        sender.vote = proposal;

        // 如果 `proposal` 超过了数组的范围，
        // 则会自动抛出异常，并恢复所有的改动。
        proposals[proposal].voteCount += sender.weight;
    }

    // 结合之前所有投票的情况下，计算出获胜的提案。
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}