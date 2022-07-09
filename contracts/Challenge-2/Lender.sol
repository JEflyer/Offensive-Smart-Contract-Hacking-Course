//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

contract Lender2 {
    using Address for address payable;
    using Address for address;

    address private admin;

    mapping(address => uint256) private deposits;

    constructor() {
        admin = msg.sender;
    }

    function deposit() external payable {
        require(msg.value >= 0, "ERR:ZA"); //ZA => Zero Amount
        deposits[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amountDeposited = deposits[msg.sender];

        require(amountDeposited > 0, "ERR:ND"); //ND => Nothing Deposited

        delete deposits[msg.sender];

        payable(msg.sender).sendValue(amountDeposited);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "ERR:BA"); //BA => Borrow Amount

        require(msg.sender.isContract(), "ERR:NC"); //NS => Not Contract

        payable(msg.sender).functionCallWithValue(
            abi.encodeWithSignature("receiveLoan()"),
            amount
        );

        uint256 balanceAfter = address(this).balance;
        require(balanceAfter >= balanceBefore, "ERR:NP"); //NP => Not Paid
    }
}

interface IFlash {
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

