pragma solidity >=0.5.14;


contract Count {
    uint256 public count;

    constructor() public {
        count = 0;
    }

    function setCount(uint256 _count) public {
        count = _count;
    }
}
