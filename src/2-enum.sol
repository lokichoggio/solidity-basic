// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract test {
    enum ActionChoices {
        GoLeft,
        GoRigtt,
        GoStrainght,
        SitStill
    }

    ActionChoices choice;

    ActionChoices constant defaultChoice = ActionChoices.GoStrainght;

    function setGoStraight() public {
        choice = ActionChoices.GoStrainght;
    }

    // 由于枚举类型不属于ABI的一部分，因此对于所有来自 solidity 外部的调用，
    // getChoice 的签名会自动改成 getChoice() returns (uint8)
    function getChoice() public view returns (ActionChoices) {
        return choice;
    }

    function getDefaultChoice() public pure returns (uint256) {
        return uint256(defaultChoice);
    }

    function getLargestValue() public pure returns (ActionChoices) {
        return type(ActionChoices).max;
    }

    function getSmallestValue() public pure returns (ActionChoices) {
        return type(ActionChoices).min;
    }
}
