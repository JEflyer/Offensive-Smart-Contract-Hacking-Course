//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

interface IReciever {
    function receiveLoan() external payable;
}

contract Lender3 {
    // using Address for address payable;
    using Address for address;

    mapping(address => uint256) private deposits;

    constructor() {}

    function deposit() external payable {}

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "ERR:BA"); //BA => Borrow Amount

        require(msg.sender.isContract(), "ERR:NC"); //NS => Not Contract

        IReciever(msg.sender).receiveLoan{value: amount}();

        uint256 balanceAfter = address(this).balance;
        require(balanceAfter >= balanceBefore, "ERR:NP"); //NP => Not Paid
    }
}

interface IFlash {
    function flashLoan(uint256 amount) external;

    function deposit() external payable;
}
