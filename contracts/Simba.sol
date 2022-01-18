// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Simba is ERC20 {
    address public admin;
    constructor(uint256 initialSupply) ERC20("SimbaToken", "ST") {
        _mint(msg.sender, initialSupply);
        admin = msg.sender;
    }
    function mint(address to, uint amount) external{
        require(msg.sender == admin, "Only admin can run this function");
        _mint(to, amount);
    }

    function burn(uint amount) external{
        require(msg.sender == admin, "Only admin can run this function");
        _burn(msg.sender, amount);
    }
}

