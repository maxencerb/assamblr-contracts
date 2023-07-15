// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract AssamblrV2 {
  // name variable (must be less than 32 bytes)
  // slot 0

  // symbol variable (must be less than 32 bytes)
  // slot 1

  constructor(string memory _name, string memory _symbol) {
    assembly {
      let _nameLength := mload(_name)
      let _symbolLength := mload(_symbol)

      let incorrect := or(gt(_nameLength, 0x1f), gt(_symbolLength, 0x1f))

      if eq(incorrect, 0x01) {
        revert(0, 0)
      }

      // store name
      sstore(0x00, or(mload(add(_name, 0x20)), mul(_nameLength, 2)))
      // store symbol
      sstore(0x01, or(mload(add(_symbol, 0x20)), mul(_symbolLength, 2)))
    }
  }

  fallback() external payable {

  }
}