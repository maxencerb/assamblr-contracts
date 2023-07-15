// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract AssamblrV1Dummy is IERC721, IERC721Metadata {

  event Upgraded(address indexed implementation);

  constructor(string memory _name, string memory _symbol, address _dummyImpl) {}

  function name() external view override returns (string memory _name) {}

  function name2() external view returns (string memory _name) {}

  function symbol() external view override returns (string memory _symbol) {}

  function balanceOf(address _owner) external view override returns (uint256 _balance) {}

  function ownerOf(uint256 _tokenId) external view override returns (address _owner) {}

  function approve(address _to, uint256 _tokenId) external override {}

  function getApproved(uint256 _tokenId) external view override returns (address _operator) {}

  function setApprovalForAll(address _operator, bool _approved) external override {}

  function isApprovedForAll(address _owner, address _operator) external view override returns (bool _approved) {}

  function transferFrom(address _from, address _to, uint256 _tokenId) external override {}

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {}

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external override {}

  function supportsInterface(bytes4 _interfaceId) external view override returns (bool _supported) {}

  function tokenURI(uint256 _tokenId) external view override returns (string memory _tokenURI) {}
}