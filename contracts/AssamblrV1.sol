// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract AssamblrV1 {

  event Upgraded(address indexed implementation);
    
  // name variable (must be less than 32 bytes)
  // slot 0 0x00

  // symbol variable (must be less than 32 bytes)
  // slot 1 0x20

  // owner address slot 2 0x40

  // dummy implementation
  // keccak-256 hash of "eip1967.proxy.implementation"

  // balances mapping (address => uint256) slot 3 0x60

  // tokens mapping (uint256 => address) slot 4 0x80

  // token counter slot 5 0xa0

  // token burned slot 6 0xc0

  // approval mapping (uint256 => address) slot 7 0xe0

  // approval for all mapping (address => (address => bool)) slot 8 0x100

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

      function shortStrToMem(sP, mP) {
        let slot := sload(sP)
        mstore(mP, div(and(slot, 0xff), 2))
        mstore(add(mP, 0x20), and(slot, not(0xff)))
      }

      function ensureOwner() {
        if iszero(eq(caller(), sload(0x40))) {
          revert(0, 0)
        }
      }

      // make the next 2 slots unavailable
      // next slot contains the mapping slot
      // 2nd next slot contains the owner address
      function ownerOf(tokenIdSlot) -> _ownerSlot {
        // store the mapping slot in the next slot
        mstore(add(tokenIdSlot, 0x20), 0x80)
        // store owner in the next slot
        _ownerSlot := add(tokenIdSlot, 0x40)
        mstore(_ownerSlot, sload(keccak256(tokenIdSlot, 0x40)))
      }

      // same as before
      function ensureOwnerOf(tokenIdSlot) {
        if iszero(eq(caller(), mload(ownerOf(tokenIdSlot)))) {
          revert(0, 0)
        }
      }

      function approvedOrOwner(tokenIdSlot) -> _approvedSlot {
        // first check if owner, then check if approved
        let _caller := caller()
        // token mapping slot
        mstore(add(tokenIdSlot, 0x20), 0x80)
        // store the owner in the next slot

        let _ownerSlot := add(tokenIdSlot, 0x40)
        mstore(_ownerSlot, sload(keccak256(tokenIdSlot, 0x40)))

        switch eq(_caller, mload(_ownerSlot)) 
        case 0 {
          // check approval mapping
          // overwrite token mapping with approval mapping
          mstore(add(tokenIdSlot, 0x20), 0xe0)
          // store the approved address in the next slot
          let _spenderSlot := add(tokenIdSlot, 0x60)
          mstore(_spenderSlot, sload(keccak256(0x20, 0x40)))

          switch eq(_caller, mload(_spenderSlot))
          case 0 {
            // Check approved for all mapping
            // put the approved for all mapping right after the owner slot
            mstore(add(_ownerSlot, 0x20), 0x100)
            // store the keccak256 hash 3 slots after the owner slot
            mstore(add(_ownerSlot, 0x60), keccak256(_ownerSlot, 0x40))
            // store caller in the second slot after the owner slot
            mstore(add(_ownerSlot, 0x40), _caller)
            _approvedSlot := add(_ownerSlot, 0x80)
            mstore(_approvedSlot, sload(keccak256(add(_ownerSlot, 0x40), 0x40)))
          }
          default {
            _approvedSlot := add(tokenIdSlot, 0x80)
            mstore(_approvedSlot, 0x01)
          }
        }
        default {
          _approvedSlot := add(tokenIdSlot, 0x60)
          mstore(_approvedSlot, 0x01)
        }
      }

      function _increase_balance_unsafe(_user) {
        mstore(add(_user, 0x20), 0x60)
        let _balanceSlot := keccak256(add(_user, 0x20), 0x40)
        sstore(_balanceSlot, add(sload(_balanceSlot), 0x01))
      }

      function _decrease_balance_unsafe(_user) {
        mstore(add(_user, 0x20), 0x60)
        let _balanceSlot := keccak256(add(_user, 0x20), 0x40)
        sstore(_balanceSlot, sub(sload(_balanceSlot), 0x01))
      }

      // TODO: bug => balances mapping resolves to the same keccack256 hash however the slot is supposed different
      // Have to ensure owner of token before calling this function
      function _transfer_unsafe(_from, _to, _tokenId) {
        // TODO: transfer from _from to _to
        // decrement balance of _from
        mstore(0x1000, _to)
        _increase_balance_unsafe(0x1000)
        // increment balance of _to
        mstore(0x1000, _from)
        _decrease_balance_unsafe(0x1000)
        // update token mapping
        mstore(0x1000, _tokenId)
        mstore(0x1020, 0x80)
        sstore(keccak256(0x1000, 0x40), mload(_to))
        // remove approval
        mstore(0x1020, 0xe0)
        sstore(keccak256(0x1000, 0x40), 0x00)
      }

      // copying function selector to first slot
      // Selector is 4 bytes so we store starting from 0x1c
      // it will padd the first 0x1c bytes with 0s
      calldatacopy(0x1c, 0x00, 0x04)

      // RESERVED SLOT: 0x00

      // load selector and started comparing
      switch mload(0x00)
      // name() returns (string memory _name)
      case 0x06fdde03 {
        // return data length
        mstore(0x20, 0x20)
        shortStrToMem(0x00, 0x40)

        return(0x20, 0x60)
      }
      // symbol() returns (string memory _symbol)
      case 0x95d89b41 {
        // return data length
        mstore(0x20, 0x20)
        shortStrToMem(0x20, 0x40)

        return(0x20, 0x60)
      }
      // owner() public view virtual returns (address)
      case 0x8da5cb5b {
        mstore(0x20, sload(0x40))
        return(0x20, 0x20)
      }
      // transferOwnership(address newOwner) public virtual
      case 0xf2fde38b {
        // check if caller is owner
        ensureOwner()

        // store new owner
        sstore(0x40, calldataload(0x04))

        // return
        return(0, 0)
      }
      // renounceOwnership() public virtual
      case 0x715018a6 {
        // check if caller is owner
        ensureOwner()

        // store new owner
        sstore(0x40, 0)

        // return
        return(0, 0)
      }
      // balanceOf(address _owner) external view override returns (uint256 _balance)
      case 0x70a08231 {
        // copy address to slot 0x20 (key of the mapping)
        calldatacopy(0x20, 0x04, 0x20)
        // store the mapping slot in slot 0x40
        mstore(0x40, 0x60)
        // store the value of the mapping in slot 0x60
        mstore(0x60, sload(keccak256(0x20, 0x40)))
        // return the value of the mapping
        return(0x60, 0x20)
      }
      // mint(address _to) external override
      case 0x6a627842 {
        // check if caller is owner
        ensureOwner()

        let tokenCounter := add(sload(0xa0), 1)
        // increase token counter
        sstore(0xa0, tokenCounter)
        
        
        // copy address to slot 0x20 (key of the mapping)
        calldatacopy(0x20, 0x04, 0x20)

        
        // increase token balance of the address (balance mapping at slot 0x60)
        mstore(0x40, 0x60)
        let balanceSlot := keccak256(0x20, 0x40)
        sstore(balanceSlot, add(sload(balanceSlot), 1))

        // store token id owner in mapping (tokens mapping at slot 0x80)
        mstore(0x60, tokenCounter)
        mstore(0x80, 0x80)
        sstore(keccak256(0x60, 0x40), mload(0x20))

        // return
        return(0, 0)
      }
      // totalSupply() external view override returns (uint256 _totalSupply)
      case 0x18160ddd {
        mstore(0x20, sub(sload(0xa0), sload(0xc0)))
        return(0x20, 0x20)
      }
      // function ownerOf(uint256 _tokenId) external view override returns (address _owner)
      case 0x6352211e {
        // copy token id to slot 0x20 (key of the mapping)
        calldatacopy(0x20, 0x04, 0x20)
        // return the value of the mapping
        return(ownerOf(0x20), 0x20)
      }
      // function approve(address _to, uint256 _tokenId) external override {}
      case 0x095ea7b3 {
        // copy _to at slot 0x20 and _tokenId at slot 0x40
        calldatacopy(0x20, 0x04, 0x40)

        ensureOwnerOf(0x40)
        // owner address is now at slot 0x80

        let to := mload(0x20)
        if eq(mload(0x80), to) {
          // if owner is spender, revert
          revert(0, 0)
        }
        // mapping slot
        mstore(0x60, 0xe0)
        // store spender in mapping
        sstore(keccak256(0x40, 0x40), to)
      }
      // function getApproved(uint256 _tokenId) external view override returns (address _operator) {}
      case 0x081812fc {
        // copy _tokenId at slot 0x20
        calldatacopy(0x20, 0x04, 0x20)

        // mapping slot
        mstore(0x40, 0xe0)

        // store spender
        mstore(0x60, sload(keccak256(0x20, 0x40)))

        // return spender
        return(0x60, 0x20)
      }
      // function setApprovalForAll(address _operator, bool _approved) external override {}
      case 0xa22cb465 {
        // keccack from owner to (operator => approved)
        // set the owner to 0x20
        mstore(0x20, caller())
        // approvall for all mapping slot to 0x40
        mstore(0x40, 0x100)
        // store the value of the mapping in slot 0x80
        mstore(0x80, keccak256(0x20, 0x40))

        // keccak from owner => operator to approved
        // copy operator to slot 0x60
        calldatacopy(0x60, 0x04, 0x20)

        // copy approved to slot 0xa0
        calldatacopy(0xa0, 0x24, 0x20)

        // store the value in the mapping
        sstore(keccak256(0x60, 0x40), mload(0xa0))
      }
      // function isApprovedForAll(address _owner, address _operator) external view override returns (bool _approved) {}
      case 0xe985e9c5 {
        // copy the owner to slot 0x20
        calldatacopy(0x20, 0x04, 0x20)
        // copy the mapping slot to 0x40
        mstore(0x40, 0x100)

        // copy the first mapping slot to 0x80
        mstore(0x80, keccak256(0x20, 0x40))
        // copy the operator to 0x60
        calldatacopy(0x60, 0x24, 0x20)

        // store the value of the mapping in slot 0xa0
        mstore(0xa0, sload(keccak256(0x60, 0x40)))

        // return the value of the mapping
        return(0xa0, 0x20)
      }
      // function transferFrom(address _from, address _to, uint256 _tokenId) external override {}
      case 0x23b872dd {
        // store the tokenId in slot 0x60
        calldatacopy(0x20, 0x04, 0x60)
        
        // check if the caller is approved for the tokenId
        if iszero(mload(approvedOrOwner(0x60))) {
          revert(0, 0)
        }

        // check if the _from is the owner of the tokenId
        if iszero(eq(mload(ownerOf(0x60)), mload(0x20))) {
          revert(0, 0)
        }

        // do the transfer
        _transfer_unsafe(0x20, 0x40, 0x60)

        // TODO: raise events
      }
      // function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {}
      case 0x42842e0e {
        // call transferFrom
        calldatacopy(0, 0, calldatasize())

        // change selector to safeTransferFrom with data 0xb88d4fde
        mstore8(0x00, 0xb8)
        mstore(0x01, 0x8d)
        mstore(0x20, 0x4f)
        mstore(0x40, 0xde)

        // Add 0x20 to calldatasize for empty string
        let result := delegatecall(gas(), address(), 0x00, add(calldatasize(), 0x40), 0x00, 0x00)

        switch result
        case 0 {
          revert(0, 0)
        }
        default {
          return(0x00, 0x00)
        }
      }
      // function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {}
      case 0xb88d4fde {
        // call transferFrom
        // ignore _data for the moment
        calldatacopy(0, 0, 0x64)

        // change selector to transferFrom
        mstore8(0x00, 0x23)
        mstore(0x01, 0xb8)
        mstore(0x20, 0x72)
        mstore(0x40, 0xdd)

        // call data is 0x64 (selector + _from + _to + _tokenId)
        let result := delegatecall(gas(), address(), 0x00, 0x64, 0x00, 0x00)

        switch result
        case 0 {
          revert(0, 0)
        }
        default {
          // todo check safe transfer
          return(0x00, 0x00)
        }
      }
      // function supportsInterface(bytes4 interfaceID) external view override returns (bool) {}
      case 0x01ffc9a7 {
        // copy interfaceID to slot 0x20
        calldatacopy(0x3c, 0x04, 0x04)
        mstore(0x40, 0x1)
        mstore(0x60, 0x0)
        if eq(mload(0x20), 0x01ffc9a7) {
          return (0x40, 0x20)
        }
        if eq(mload(0x20), 0x80ac58cd) {
          return (0x40, 0x20)
        }
        if eq(mload(0x20), 0x5b5e139f) {
          return (0x40, 0x20)
        }
        return(0x60, 0x20)
      }
      // function tokenURI(uint256 _tokenId) external view override returns (string memory _tokenURI) {}
      case 0xc87b56dd {
        // TODO: implement
      }

    }
  }
}