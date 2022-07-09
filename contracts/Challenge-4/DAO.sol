//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO4 {
    using Address for address;
    using Address for address payable;

    IERC20 private tokenB;

    address public proposedTarget;
    bytes public proposedData;
    uint256 private votesFor;

    mapping(address => uint256) private balances;

    constructor(address token) {
        tokenB = IERC20(token);
    }

    function deposit() external  {
        uint256 amountApproved = tokenB.allowance(msg.sender, address(this));
        require(amountApproved > 0, "ERR:ZA"); //ZA => Zero Amount
        tokenB.transferFrom(msg.sender, address(this), amountApproved);
        balances[msg.sender] += amountApproved;
    } 

    function withdraw() external {
        uint256 amountDeposited = balances[msg.sender];

        require(amountDeposited > 0, "ERR:ND"); //ND => Nothing Deposited

        delete balances[msg.sender];

        tokenB.transfer(msg.sender, amountDeposited);
    }

    function propose(address target, bytes calldata data) external {
        uint256 userBal = balances[msg.sender];


        uint256 totalBal = tokenB.balanceOf(address(this));

        require(userBal > 0, "ERR:ND"); //ND => No Deposits


        if ((userBal * 100) / totalBal >= 51) {
            target.functionCall(data);
        } else {
            votesFor += userBal;
            proposedTarget = target;
            proposedData = data;
        }
    }

    function vote(bool vote) external {
        if (vote) {
            votesFor += balances[msg.sender];
            if ((votesFor * 100) / address(this).balance >= 51) {
                proposedTarget.functionCall(proposedData);
            }
        } else {
            delete votesFor;
            delete proposedData;
            delete proposedTarget;
        }
    }
}

//An interface the DAO contract
interface IDAO {
    function deposit() external payable;
    function withdraw() external;
    function propose(address target, bytes calldata data) external;
    function vote(bool vote) external;
}