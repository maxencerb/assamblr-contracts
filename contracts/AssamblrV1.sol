// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract AssamblrV1 {

  event Upgraded(address indexed implementation);
    
  // name variable (must be less than 32 bytes)
  // slot 0

  // symbol variable (must be less than 32 bytes)
  // slot 1

  // owner address slot 2

  // dummy implementation
  // keccak-256 hash of "eip1967.proxy.implementation"

  constructor(string memory _name, string memory _symbol, address _dummyImpl) {
    assembly {
      let _nameLength := mload(_name)
      let _symbolLength := mload(_symbol)

      if eq(or(gt(_nameLength, 0x1f), gt(_symbolLength, 0x1f)), 0x01) {
        revert(0, 0)
      }

      // store name
      sstore(0x00, or(mload(add(_name, 0x20)), mul(_nameLength, 2)))
      // store symbol
      sstore(0x20, or(mload(add(_symbol, 0x20)), mul(_symbolLength, 2)))

      // store owner
      sstore(0x40, caller())

      // store dummy implementation
      sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _dummyImpl)
    }

    emit Upgraded(_dummyImpl);
  }

  fallback() external payable {

    assembly {

      // copying function selector to first slot
      // Selector is 4 bytes so we store starting from 0x1c
      // it will padd the first 0x1c bytes with 0s
      calldatacopy(0x1c, 0x00, 0x04)

      // RESERVED SLOT: 0x00

      // load selector and started comparing
      switch mload(0x00)
      // name() returns (string memory _name)
      case 0x06fdde03 {
        let nameSlot := sload(0x00)

        // return data length
        mstore(0x20, 0x20)
        mstore(0x40, div(and(nameSlot, 0xff), 2))
        mstore(0x60, and(nameSlot, not(0xff)))

        return(0x20, 0x60)
      }
      // symbol() returns (string memory _symbol)
      case 0x95d89b41 {
        let symbolSlot := sload(0x20)

        // return data length
        mstore(0x20, 0x20)
        mstore(0x40, div(and(symbolSlot, 0xff), 2))
        mstore(0x60, and(symbolSlot, not(0xff)))

        return(0x20, 0x60)
      }
    }
  }

}