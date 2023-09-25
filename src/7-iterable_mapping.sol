// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

struct IndexValue {
    uint keyIndex;
    uint value;
}

struct KeyFlag {
    uint key;
    bool deleted;
}

struct itmap {
    KeyFlag[] keys;
    uint size;
    // key => {keyIndex, value}
    mapping (uint => IndexValue) data;
}

// 自定义类型
type Iterator is uint;

library IterableMapping {
    function insert(itmap storage self, uint key, uint value) internal returns (bool replaced) {
        uint keyIndex = self.data[key].keyIndex;

        // 存在
        if (keyIndex > 0) {
            self.data[key].value = value;
            return true;
        } else { // 不存在
            keyIndex = self.keys.length;

            // self.keys.push();
            // self.keys[keyIndex].key = key;
            // self.data[key].keyIndex = keyIndex + 1;
            // self.data[key].value = value;

            self.keys.push(KeyFlag(key, false));
            self.data[key] = IndexValue(keyIndex+1, value);
            self.size++;

            return false;
        }
    }

    function remove(itmap storage self, uint key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0) {
            return false;
        }

        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size--;
    }

    function contains(itmap storage self, uint key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterateGet(itmap storage self, Iterator iterator) internal view returns (uint key, uint value) {
        uint keyIndex = Iterator.unwrap(iterator);
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }

    function iteratorSkipDeleted(itmap storage self, uint keyIndex) private view returns (Iterator) {
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted) {
            keyIndex++;
        }
        return Iterator.wrap(keyIndex);
    }

    function iterateValid(itmap storage self, Iterator iterator) internal view returns (bool) {
        return Iterator.unwrap(iterator) < self.keys.length;
    }

    function iterateStart(itmap storage self) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, 0);
    }

    function iterateNext(itmap storage self, Iterator iterator) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, Iterator.unwrap(iterator) + 1);
    }
}

contract User {
    itmap public data;
    using IterableMapping for itmap;

    

    function insert(uint k, uint v) public returns (uint size) {
        // 这将调用 IterableMapping.insert(data, k, v)
        data.insert(k, v);
        // 我们仍然可以访问结构中的成员， 但我们应该注意不要乱动他们。
        return data.size;
    }

    function remove(uint k) public returns (bool) {
        return data.remove(k);
    }

    function sum() public view returns (uint s) {
        for (
            Iterator i = data.iterateStart();
            data.iterateValid(i);
            i = data.iterateNext(i)
        ) {
            (, uint value) = data.iterateGet(i);
            s += value;
        }
    }
}