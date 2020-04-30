pragma solidity >=0.5.14;


contract Count {
    string public s;

    constructor() public {
        s = "hello";
    }

    function setS(string memory _s) public {
        s = _s;
    }
}
