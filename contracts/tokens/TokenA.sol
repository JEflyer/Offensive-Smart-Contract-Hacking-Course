//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract TokenA is ERC20PresetFixedSupply {

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalLimit
    ) ERC20PresetFixedSupply(
        name,
        symbol,
        totalLimit,
        msg.sender
    ){}
}