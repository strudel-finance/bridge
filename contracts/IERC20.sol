// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

interface IERC20 {
  function mint(address to, uint256 amount) external returns (bool);
  function burn(address from, uint256 amount) external returns (bool);
  function burnFrom(address from, uint256 amount) external returns (bool);
}
