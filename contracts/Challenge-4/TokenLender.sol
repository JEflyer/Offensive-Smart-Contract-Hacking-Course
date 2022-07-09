//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashReceiver {
    function receiveLoan() external;
}

contract Lender4 {
    using Address for address;
    // using Address for address payable;

    IERC20 private tokenA;

    constructor(address token) {
        tokenA = IERC20(token);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = tokenA.balanceOf(address(this));
        require(balanceBefore >= amount, "ERR:BA"); //BA => Borrow Amount

        require(msg.sender.isContract(), "ERR:NC"); //NS => Not Contract

        tokenA.transfer(msg.sender,amount);

        //How to call with Address library
        // msg.sender.functionCall(
        //     abi.encodeWithSignature("receiveLoan()")
        // );

        IFlashReceiver(msg.sender).receiveLoan();

        uint256 balanceAfter = tokenA.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "ERR:NP"); //NP => Not Paid
    }
}

//An interface of the flashloan pool contract
interface IPool {
    function flashLoan(uint256 amount) external;
}