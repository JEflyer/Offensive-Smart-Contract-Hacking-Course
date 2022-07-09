//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

contract DAO3 {
    using Address for address;
    using Address for address payable;

    mapping(address => uint256) private balances;

    address public proposedTarget;
    bytes public proposedData;
    uint256 private votesFor;
    uint256 private proposedAmount;

    function deposit() external payable {
        require(msg.value >= 0, "ERR:ZA"); //ZA => Zero Amount
        balances[msg.sender] += msg.value;
    } 

    function withdraw() external {
        uint256 amountDeposited = balances[msg.sender];

        require(amountDeposited > 0, "ERR:ND"); //ND => Nothing Deposited

        delete balances[msg.sender];

        payable(msg.sender).sendValue(amountDeposited);
    }

    function propose(address target, bytes calldata data,uint256 amount) external {
        uint256 userBal = balances[msg.sender];

        uint256 totalBal = address(this).balance;

        require(userBal > 0, "ERR:ND"); //ND => No Deposits

        if ((userBal * 100) / totalBal >= 51) {
            target.functionCallWithValue(data,amount);
        } else {
            votesFor += userBal;
            proposedTarget = target;
            proposedData = data;
            proposedAmount = amount;
        }
    }

    function vote(bool vote) external {
        if (vote) {
            votesFor += balances[msg.sender];
            if ((votesFor * 100) / address(this).balance >= 51) {
                proposedTarget.functionCallWithValue(proposedData,proposedAmount);
            }
        } else {
            delete votesFor;
            delete proposedData;
            delete proposedTarget;
            delete proposedAmount;
        }
    }
}

interface IDao {
    function deposit() external payable;

    function withdraw() external;

    function propose(address target, bytes calldata data,uint256 amount) external;

    function vote(bool vote) external;
}


