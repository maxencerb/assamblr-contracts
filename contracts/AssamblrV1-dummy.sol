// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "hardhat/console.sol";

contract AssamblrV1Dummy is IERC721, IERC721Metadata {

  event Upgraded(address indexed implementation);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor(string memory _name, string memory _symbol, address _dummyImpl) {}

  function name() external view override returns (string memory _name) {}

  function symbol() external view override returns (string memory _symbol) {}

  function balanceOf(address _owner) external view override returns (uint256 _balance) {}

  function totalSupply() external view returns (uint256 _totalSupply) {}

  function ownerOf(uint256 _tokenId) external view override returns (address _owner) {}

  function approve(address _to, uint256 _tokenId) external override {}

  function getApproved(uint256 _tokenId) external view override returns (address _operator) {}

  function setApprovalForAll(address _operator, bool _approved) external override {}

  function isApprovedForAll(address _owner, address _operator) external view override returns (bool _approved) {}

  function transferFrom(address _from, address _to, uint256 _tokenId) external override {}

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {}

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external override {}

  function supportsInterface(bytes4 _interfaceId) external view override returns (bool _supported) {
    console.logBytes4(type(IERC165).interfaceId);
    console.logBytes4(type(IERC721).interfaceId);
    console.logBytes4(type(IERC721Metadata).interfaceId);
    return _interfaceId == type(IERC165).interfaceId || _interfaceId == type(IERC721).interfaceId || _interfaceId == type(IERC721Metadata).interfaceId;
  }

  function tokenURI(uint256 _tokenId) external view override returns (string memory _tokenURI) {}

  function owner() public view virtual returns (address) {}

  function transferOwnership(address newOwner) public virtual {}

  function renounceOwnership() public virtual {}


  function mint(address to) public virtual {}
}