// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ITokenRecipient.sol";

contract MockStrudel is ERC20 {
    constructor(uint256 initialSupply) ERC20("Mock", "MCK") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) external returns (bool) {
      _mint(to, amount);
      return true;
    }
    function burn(address from, uint256 amount) external returns (bool) {
      _burn(from, amount);
      return true;
    }
    function burnFrom(address from, uint256 amount) external {
      _burn(from, amount);
    }

    function approveAndCall(ITokenRecipient _spender,
                            uint256 _value,
                            bytes memory _extraData
                            ) public returns (bool) {
      // not external to allow bytes memory parameters
      if (approve(address(_spender), _value)) {
        _spender.receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
      }
      return false;
    }
}
