// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// 定义一个包含两个属性的新类型。
// 在合约之外声明一个结构，可以让它被多个合约所共享。
struct Funder {
    address addr;
    uint amount;
}

contract CrowFunding {
    // 结构体也可以被定义在合约内部，这使得它们只在本合约和派生合约中可见。
    struct Campaign {
        address payable beneficiary;
        uint fundingGoal;
        uint amount;
        uint numFunders;
        mapping (uint => Funder) funders;
    }

    uint numCampaigns;
    
    mapping (uint => Campaign) campaigns;

    function newCampaign(address payable beneficiary, uint goal) public returns (uint campaignID) {
        campaignID = numCampaigns++;
        // 我们不能使用 "campaigns[campaignID] = Campaign(beneficiary, goal, 0, 0)"
        // 因为右侧创建了一个内存结构 "Campaign"，其中包含一个映射。
        Campaign storage c = campaigns[campaignID];
        c.beneficiary = beneficiary;
        c.fundingGoal = goal;
    }

    function contribute(uint campaignID) public payable {
        Campaign storage c = campaigns[campaignID];
        // 以给定的值初始化，创建一个新的临时 memory 结构体，并将其拷贝到 storage 中。
        // 注意您也可以使用 Funder(msg.sender, msg.value) 来初始化。
        c.funders[c.numFunders++] = Funder(msg.sender, msg.value);
        c.amount += msg.value;
    }

    function checkGoalReached(uint campaignID) public returns (bool reached) {
        Campaign storage c = campaigns[campaignID];
        if (c.amount < c.fundingGoal) {
            return false;
        }

        uint amount = c.amount;
        c.amount = 0;
        c.beneficiary.transfer(amount);
        return true;
    }

}