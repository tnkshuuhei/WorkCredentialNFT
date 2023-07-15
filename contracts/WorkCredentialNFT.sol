// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WorkCredentialNFT is ERC721, Pausable, Ownable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public _imageUrl =
        "https://gateway.pinata.cloud/ipfs/QmWJhNrFAQSFkT8svf4QC9mZdA7wkpcN5DRqkL2GXHLRkn";
    uint256 public constant MINT_PRICE = 0.001 ether;

    Counters.Counter private _tokenIdCounter;

    struct TokenData {
        address minterAddress;
        string description;
    }
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }
    mapping(uint256 => TokenData) private _tokenData;

    constructor(address admin) ERC721("D-WorkCredentialNFT 2023", "DWC2023") {
        _setupRole(ADMIN_ROLE, admin);
    }

    function setImageUrl(string memory _url) public onlyAdmin{
        _imageUrl = _url;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(
        address minterAddress,
        string memory description
    ) public payable whenNotPaused onlyAdmin{
        require(msg.value == MINT_PRICE, "Error: Invalid value");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        TokenData storage tokenData = _tokenData[tokenId];
        tokenData.minterAddress = minterAddress;
        tokenData.description = description;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        TokenData memory tokenData = _tokenData[tokenId];

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            tokenId.toString(),
            '"},',
            '{"trait_type": "name", "value": "',
            "D-Work Credential NFT 2023",
            '"}'
        );
        bytes memory metadata = abi.encodePacked(
            '{"name": "D-Work Credential NFT 2023 #',
            tokenId.toString(),
            '", "description": "',
            tokenData.description,
            '", "image": "',
            _imageUrl,
            '", "attributes": [',
            attributes,
            "]}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        require(
            from == address(0) || to == address(0),
            "Err: This token is not transferable"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function renounceOwnership() public override onlyOwner {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
