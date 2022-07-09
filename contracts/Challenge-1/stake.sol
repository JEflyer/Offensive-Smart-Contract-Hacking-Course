//SPDX-License-Identifier: MIT
pragma solidity 0.8.15; 


contract Stake1  {
    
    address private admin;

    mapping(address => uint256) private stakedBalance;
    

    constructor() {
        admin = msg.sender;
    }

    function stake() external payable {
        
        uint256 amountSent = msg.value;

        require(amountSent > 0, "ERR:NS"); //NS => Nothing Sent

        stakedBalance[msg.sender] += amountSent;
    }

    function unstake() external  {
        uint256 amountStaked = stakedBalance[msg.sender];

        require(amountStaked > 0, "ERR:NS"); //NS => Nothing Staked

        require(address(this).balance >= amountStaked,"ERR:NF");//NF => No Funds

        (bool success, ) = msg.sender.call{value: amountStaked}("");

        require(success, "ERR:OT"); //OT => On Transfer

        stakedBalance[msg.sender] = 0;
    }

}

interface IStake {
    function stake() external payable;

    function unstake() external;
}