// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

// this contract is written in inline assembly
// this is a base ERC721 with metadata (token URI not implemented)
// The owner of the contract has no specific role 

contract Assamblr {
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

  // specifics

  // paused slot 9 0x120

  // last block minted (address => uint256) slot 10 0x140

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

      // emit event Upgraded
      log2(0x00, 0x00, 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b, _dummyImpl)

      // emit OwnershipTransferred
      log3(0x00, 0x00, 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0, 0x00, caller())
    }
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

      function _mapping_slot(_key_s, _mapping_pos) -> _storagePos {
        mstore(add(_key_s, 0x20), _mapping_pos)
        _storagePos := keccak256(_key_s, 0x40)
      }

      // make the next 2 slots unavailable
      // next slot contains the mapping slot
      // 2nd next slot contains the owner address
      function ownerOf(tokenIdSlot) -> _ownerSlot {
        // store owner in the next slot
        let _ownerStorageSlot := _mapping_slot(tokenIdSlot, 0x80)
        _ownerSlot := add(tokenIdSlot, 0x20)
        mstore(_ownerSlot, sload(_ownerStorageSlot))
      }

      // same as before
      function ensureOwnerOf(tokenIdSlot) -> _ownerSlot {
        _ownerSlot := ownerOf(tokenIdSlot)
        if iszero(eq(caller(), mload(_ownerSlot))) {
          revert(0, 0)
        }
      }

      function approvedOrOwner(tokenIdSlot) -> _approvedSlot {
        // first check if owner
        let _caller := caller()
        let _ownerSlot := ownerOf(tokenIdSlot)
        let _owner := mload(_ownerSlot)

        switch eq(_caller, _owner) 
        case 0 {
          // check if approved for token
          let _spenderStorageSlot := _mapping_slot(tokenIdSlot, 0xe0)

          switch eq(_caller, sload(_spenderStorageSlot))
          case 0 {
            // approval for all
            let _baseSlot := add(tokenIdSlot, 0x20)
            // store operator at _baseSlot
            mstore(_baseSlot, _caller)
            // store owner at _baseSlot + 0x20
            mstore(add(_baseSlot, 0x20), _owner)
            let _approvedForAllSlot := _mapping_slot(_baseSlot, _mapping_slot(add(_baseSlot, 0x20), 0x100))
            _approvedSlot := add(_ownerSlot, 0x20)
            mstore(_approvedSlot, sload(_approvedForAllSlot))
          }
          default {
            _approvedSlot := add(_ownerSlot, 0x40)
            mstore(_approvedSlot, 0x01)
          }
        }
        default {
          _approvedSlot := add(_ownerSlot, 0x20)
          mstore(_approvedSlot, 0x01)
        }
      }

      function _increase_balance_unsafe(_user) {
        let _balanceSlot := _mapping_slot(_user, 0x60)
        sstore(_balanceSlot, add(sload(_balanceSlot), 0x01))
      }

      function _decrease_balance_unsafe(_user) {
        let _balanceSlot := _mapping_slot(_user, 0x60)
        sstore(_balanceSlot, sub(sload(_balanceSlot), 0x01))
      }

      // TODO: bug => balances mapping resolves to the same keccack256 hash however the slot is supposed different
      // Have to ensure owner of token before calling this function
      function _transfer_unsafe(_from, _to, _tokenId) {
        // decrement balance of _from
        let addrSlot := add(msize(), 0x20)
        mstore(addrSlot, mload(_to))
        _increase_balance_unsafe(addrSlot)
        // increment balance of _to
        mstore(addrSlot, mload(_from))
        _decrease_balance_unsafe(addrSlot)
        // update token mapping
        sstore(_mapping_slot(_tokenId, 0x80), mload(_to))
        // remove approval
        sstore(_mapping_slot(_tokenId, 0xe0), 0x00)
        // emit transfer event
        log4(0x00, 0x00, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, mload(_from), mload(_to), mload(_tokenId))
      }

      function ensureNotPaused() {
        if sload(0x120) {
          revert(0, 0)
        }
      }

      function lastMint() -> _lastMintBlock {
        let _callerSlot := add(msize(), 0x20)
        mstore(_callerSlot, caller())
        let _lastMintBlockStorage := _mapping_slot(_callerSlot, 0x140)
        _lastMintBlock := sload(_lastMintBlockStorage)
      }

      function setLastMintofCaller() {
        let _callerSlot := add(msize(), 0x20)
        mstore(_callerSlot, caller())
        sstore(_mapping_slot(_callerSlot, 0x140), number())
      }

      function mathlog10(_v) -> _res {
        _res := 0x00
        // 1e64
        if gt(_v, sub(0x184f03e93ff9f50000000000000000000000000000000000000000, 0x1)) {
          _res := add(_res, 0x40)
          _v := div(_v, 0x184f03e93ff9f50000000000000000000000000000000000000000)
        }
        // 1e32
        if gt(_v, sub(0x4ee2d6d415b85c0000000000000, 0x1)) {
          _res := add(_res, 0x20)
          _v := div(_v, 0x4ee2d6d415b85c0000000000000)
        }
        // 1e16
        if gt(_v, sub(0x2386f26fc10000, 0x1)) {
          _res := add(_res, 0x10)
          _v := div(_v, 0x2386f26fc10000)
        }
        // 1e8
        if gt(_v, sub(0x5f5e100, 0x1)) {
          _res := add(_res, 0x08)
          _v := div(_v, 0x5f5e100)
        }
        // 1e4
        if gt(_v, sub(0x2710, 0x1)) {
          _res := add(_res, 0x04)
          _v := div(_v, 0x2710)
        }
        // 1e2
        if gt(_v, 0x63) {
          _res := add(_res, 0x02)
          _v := div(_v, 0x64)
        }
        // 1e1
        if gt(_v, 0x09) {
          _res := add(_res, 0x01)
        }
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

        let _prevOwner := sload(0x40)
        let _newOwner := calldataload(0x04)

        // store new owner
        sstore(0x40, _newOwner)

        // emit event
        log3(0x00, 0x00, 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0, _prevOwner, _newOwner)

        // return
        return(0, 0)
      }
      // renounceOwnership() public virtual
      case 0x715018a6 {
        // check if caller is owner
        ensureOwner()

        let _prevOwner := sload(0x40)
        // store new owner
        sstore(0x40, 0x00)

        // emit event
        log3(0x00, 0x00, 0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0, _prevOwner, 0x00)

        // return
        return(0, 0)
      }
      // balanceOf(address _owner) external view override returns (uint256 _balance)
      case 0x70a08231 {
        // copy address to slot 0x20 (key of the mapping)
        calldatacopy(0x20, 0x04, 0x20)
        // store balance in slot 0x40
        mstore(0x40, sload(_mapping_slot(0x20, 0x60)))
        // return the value of the mapping
        return(0x40, 0x20)
      }
      // mint() external override
      case 0x1249c58b {
        // check if mint is paused
        ensureNotPaused()

        let _lastMintedBlock := lastMint()
        let _neverMinted := eq(_lastMintedBlock, 0x00)
        let _atLeastOneMonth := gt(sub(number(), _lastMintedBlock), 0x13c680) // 1 month in blocks

        // if and(not(_neverMinted), not(_atLeastOneMonth)) {
        //   revert(0, 0)
        // }

        let _isOwner := eq(sload(0x40), caller())

        if and(not(or(or(_neverMinted, _atLeastOneMonth), _isOwner)), 0x1) {
          revert(0, 0)
        }


        let tokenCounter := add(sload(0xa0), 1)
        // increase token counter
        sstore(0xa0, tokenCounter)
        
        
        // copy address to slot 0x20 (key of the mapping)
        mstore(0x20, caller())

        // increase token balance
        // let _balanceSlot := _mapping_slot(0x20, 0x60)
        // sstore(_balanceSlot, add(sload(_balanceSlot), 0x01))
        _increase_balance_unsafe(0x20)

        // copy token id to slot 0x40 (value of the mapping)
        mstore(0x40, tokenCounter)

        // store token id owner in mapping
        sstore(_mapping_slot(0x40, 0x80), mload(0x20))

        // set last mint
        setLastMintofCaller()

        // emit transfer event
        log4(0x00, 0x00, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, 0x00, mload(0x20), tokenCounter)

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

        let _owner := mload(ensureOwnerOf(0x40))
        // owner address is now at slot 0x80

        let to := mload(0x20)
        if eq(_owner, to) {
          // if owner is spender, revert
          revert(0, 0)
        }
        // // store spender in mapping
        let _spenderSlot := _mapping_slot(0x40, 0xe0)
        sstore(_spenderSlot, to)
        // fire Approval event
        log4(0x00, 0x00, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, _owner, to, mload(0x40))
      }
      // function getApproved(uint256 _tokenId) external view override returns (address _operator) {}
      case 0x081812fc {
        // copy _tokenId at slot 0x20
        calldatacopy(0x20, 0x04, 0x20)

        // store spender
        mstore(0x60, sload(_mapping_slot(0x20, 0xe0)))

        // return spender
        return(0x60, 0x20)
      }
      // function setApprovalForAll(address _operator, bool _approved) external override {}
      case 0xa22cb465 {
        // copy the operator to slot 0x20
        calldatacopy(0x20, 0x04, 0x20)
        // copy the caller to slot 0x40
        mstore(0x40, caller())

        // only upper slots are overwritten, so the caller slot must be bigger than the operator slot
        let _approvedForAllSlot := _mapping_slot(0x20, _mapping_slot(0x40, 0x100))
        sstore(_approvedForAllSlot, and(calldataload(0x24), 0x01))

        calldatacopy(0x60, 0x24, 0x20)

        // fire ApprovalForAll event
        log3(0x60, 0x20, 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31, caller(), calldataload(0x04))
      }
      // function isApprovedForAll(address _owner, address _operator) external view override returns (bool _approved) {}
      case 0xe985e9c5 {
        // copy the operator to slot 0x20
        calldatacopy(0x20, 0x24, 0x20)
        // copy the owner to slot 0x40
        calldatacopy(0x40, 0x04, 0x20)

        let _approvedForAllSlot := _mapping_slot(0x20, _mapping_slot(0x40, 0x100))
        mstore(0x60, sload(_approvedForAllSlot))

        // return the value of the mapping
        return(0x60, 0x20)
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
      

      // specifics
      // function paused() public view virtual returns (bool) {}
      case 0x5c975abb {
        mstore(0x20, sload(0x120))
        return(0x20, 0x20)
      }
      // function pause() public virtual onlyPauser {}
      case 0x8456cb59 {
        ensureOwner()
        sstore(0x120, 0x01)

        mstore(0x20, caller())

        log1(0x20, 0x20, 0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258)

        return(0x00, 0x00)
      }
      // function unpause() public virtual onlyPauser {}
      case 0x3f4ba83a {
        ensureOwner()
        sstore(0x120, 0x00)

        mstore(0x20, caller())

        log1(0x20, 0x20, 0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa)

        return(0x00, 0x00)
      }
      // base URI at 0xd7bb13ec486ed16fdf30f21c81b0b0901102df35ffc65a9e5359fdc2cc57b752 keccack256("storage.ERC721.baseURI")
      // function setBaseURI(string memory baseURI_) external virtual {}
      case 0x55f804b3 {
        ensureOwner()
        // storage slot for base URI
        let baseURIStorageSlot := 0xd7bb13ec486ed16fdf30f21c81b0b0901102df35ffc65a9e5359fdc2cc57b752
        // copy the string param starting from slot 0x20
        calldatacopy(0x20, 0x04, sub(calldatasize(), 0x04))
        // length of the string in the first word
        let _start := add(mload(0x20), 0x20)
        let len := mload(_start)

        switch gt(len, 0x1F)
        case 0x00 {
          // if length is 31 bytes or less, store the string in the slot with the length in the last byte
          // length * 2
          sstore(baseURIStorageSlot, or(mload(add(_start, 0x20)), mul(len, 2)))
        }
        default {
          // if more than 31 bytes, store length in the first word
          // length * 2 + 1
          sstore(baseURIStorageSlot, add(mul(len, 0x02), 0x01))
          // store content in the next slot
          let dataSlot := add(baseURIStorageSlot, 0x20)

          for { let i := 0 } lt(mul(i, 0x20), len) { i := add(i, 0x01) } {
            sstore(add(dataSlot, mul(i, 0x20)), mload(add(_start, add(0x20, mul(i, 0x20)))))
          }
        }
      }
      // function baseURI() external view virtual returns (string memory) {}
      case 0x6c0360eb {
        // storage slot for base URI
        let baseURIStorageSlot := 0xd7bb13ec486ed16fdf30f21c81b0b0901102df35ffc65a9e5359fdc2cc57b752
        // load the length
        let len := sload(baseURIStorageSlot)
        
        switch and(len, 0x01)
        case 0x00 {
          // if length is 31 bytes or less, load the string from the slot
          mstore(0x20, 0x20)
          mstore(0x40, div(and(len, 0xff), 2))
          mstore(0x60, and(len, not(0xff)))
          return(0x20, 0x60)
        }
        default {
          let decodedStringLength := div(len, 2)
          let dataSlot := add(baseURIStorageSlot, 0x20)

          mstore(0x20, 0x20)
          mstore(0x40, decodedStringLength)

          let returnDataSize := 0x40
          
          // Write to memory as many blocks of 32 bytes as necessary taken from data storage variable slot + i
          for {let i := 0} lt(i, decodedStringLength) {i := add(i, 0x20)} {
            mstore(add(0x60, i), sload(add(dataSlot, i)))
            returnDataSize := add(returnDataSize, 0x20)
          }

          return(0x20, returnDataSize)
        }
      }
      // function tokenURI(uint256 _tokenId) external view override returns (string memory _tokenURI) {}
      case 0xc87b56dd {
        // storage slot for base URI
        let baseURIStorageSlot := 0xd7bb13ec486ed16fdf30f21c81b0b0901102df35ffc65a9e5359fdc2cc57b752
        // load the length
        let len := sload(baseURIStorageSlot)

        let _lenSlot := 0x40
        let _dataSlot := 0x60

        let decodedStringLength

        let returnDataSize
        
        switch and(len, 0x01)
        case 0x00 {
          // if length is 31 bytes or less, load the string from the slot
          mstore(0x20, 0x20)
          decodedStringLength := div(and(len, 0xff), 2)
          mstore(_lenSlot, decodedStringLength)
          mstore(_dataSlot, and(len, not(0xff)))
          returnDataSize := 0x60
        }
        default {
          decodedStringLength := div(len, 2)
          let dataSlot := add(baseURIStorageSlot, 0x20)

          mstore(0x20, 0x20)
          mstore(0x40, decodedStringLength)

          returnDataSize := 0x40
          
          // Write to memory as many blocks of 32 bytes as necessary taken from data storage variable slot + i
          for {let i := 0} lt(i, decodedStringLength) {i := add(i, 0x20)} {
            mstore(add(_dataSlot, i), sload(add(dataSlot, i)))
            returnDataSize := add(returnDataSize, 0x20)
          }
        }

        // 0123456789abcdef
        let symbols := shl(0x80, 0x30313233343536373839616263646566)

        // load the token id
        let _tokenId := calldataload(0x04)
        let _tokenStrLen := add(mathlog10(_tokenId), 0x01)
        let ptr := sub(add(add(_dataSlot, decodedStringLength), _tokenStrLen), 0x1)

        for { } _tokenId { ptr := sub(ptr, 0x01) } {
          mstore8(ptr, byte(mod(_tokenId, 10), symbols))
          // mstore8(ptr, 0x30)
          _tokenId := div(_tokenId, 0x0a)
        }

        mstore(_lenSlot, add(mload(_lenSlot), _tokenStrLen))

        for {  } gt(add(mload(_lenSlot), 0x40), returnDataSize) { } {
          returnDataSize := add(returnDataSize, 0x20)
        }

        return (0x20, returnDataSize)
      }
    }
  }
}