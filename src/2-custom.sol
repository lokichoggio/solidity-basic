// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// 使用用户定义的值类型表示一个18位小数，256位宽的定点类型。
type UFixed256x18 is uint256;

/// 一个在UFixed256x18上进行定点操作的最小库。
library FixedMath {
    uint constant multiplier = 10**18;

    /// 将两个UFixed256x18的数字相加。溢出时将返回，依靠uint256的算术检查。
    function add(UFixed256x18 a, UFixed256x18 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) + UFixed256x18.unwrap(b));
    }
    /// 将UFixed256x18和uint256相乘。溢出时将返回，依靠uint256的算术检查。
    function mul(UFixed256x18 a, uint256 b) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(UFixed256x18.unwrap(a) * b);
    }
    /// 对一个UFixed256x18类型的数字相下取整。
    /// @return 不超过 `a` 的最大整数。
    function floor(UFixed256x18 a) internal pure returns (uint256) {
        return UFixed256x18.unwrap(a) / multiplier;
    }
    /// 将一个uint256转化为相同值的UFixed256x18。
    /// 如果整数太大，则恢复计算。
    function toUFixed256x18(uint256 a) internal pure returns (UFixed256x18) {
        return UFixed256x18.wrap(a * multiplier);
    }
}