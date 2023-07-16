// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract WorkCredentialNFT is
    ERC721,
    Pausable,
    Ownable,
    AccessControl,
    ERC721Enumerable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    struct TokenData {
        address minterAddress;
        string description;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }
    mapping(uint256 => TokenData) private _tokenData;
    string public _imageUrl =
        "https://gateway.pinata.cloud/ipfs/QmWJhNrFAQSFkT8svf4QC9mZdA7wkpcN5DRqkL2GXHLRkn";

    function setImageUrl(string memory _url) public onlyAdmin {
        _imageUrl = _url;
    }

    constructor(address admin) ERC721("D-WorkCredentialNFT 2023", "DWC2023") {
        _setupRole(ADMIN_ROLE, admin);
    }

    function mint(
        address minterAddress,
        string memory description
    ) public payable whenNotPaused onlyAdmin {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        TokenData storage tokenData = _tokenData[tokenId];
        tokenData.minterAddress = minterAddress;
        tokenData.description = description;
    }

    function mintBatch(
        address[] memory minterAddresses,
        string[] memory descriptions
    ) public payable whenNotPaused onlyAdmin {
        require(
            minterAddresses.length == descriptions.length,
            "Input array lengths must be equal"
        );

        for (uint256 i = 0; i < minterAddresses.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(minterAddresses[i], tokenId);

            TokenData storage tokenData = _tokenData[tokenId];
            tokenData.minterAddress = minterAddresses[i];
            tokenData.description = descriptions[i];
        }
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
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        require(
            from == address(0) || to == address(0),
            "Err: This token is not transferable"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function setApprovalForAll(
        address,
        bool
    ) public virtual override(ERC721, IERC721) {
        revert(
            "You can't approve this NFT because this is Non Transferable NFT."
        );
    }

    function addAdmin(address newadmin) external onlyOwner {
        grantRole(ADMIN_ROLE, newadmin);
    }

    function revoke_adminRole(address admin) external onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
    }

    function getTokensByAddress(
        address owner
    ) public view returns (uint256[] memory, string[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        string[] memory metadata = new string[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            tokenIds[i] = tokenId;
            metadata[i] = tokenURI(tokenId);
        }

        return (tokenIds, metadata);
    }
}
