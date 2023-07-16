// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @title WorkCredentialNFT
 * @dev An ERC-721 compliant NFT contract with additional functionalities for administrative control and enumeration.
 */
contract WorkCredentialNFT is
    ERC721,
    ERC721Enumerable,
    Pausable,
    AccessControl,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct TokenData {
        address minterAddress;
        string description;
        string imageUrl;
    }

    /**
     * @dev Modifier to restrict access to admin only.
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    mapping(uint256 => TokenData) private _tokenData;
    string public _imageUrl =
        "https://gateway.pinata.cloud/ipfs/QmWJhNrFAQSFkT8svf4QC9mZdA7wkpcN5DRqkL2GXHLRkn";

    /**
     * @dev Sets the image URL of a specific NFT.
     * @param tokenId The ID of the token for which the image URL will be set.
     * @param imageUrl The new image URL to be set for the specified token.
     * Requirements:
     * - The token with the given tokenId must exist.
     * - Only addresses with the admin role can call this function.
     */
    function setImageUrl(
        uint256 tokenId,
        string memory imageUrl
    ) public onlyAdmin {
        require(_exists(tokenId), "URI query for nonexistent token");
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        TokenData storage tokenData = _tokenData[tokenId];
        tokenData.imageUrl = imageUrl;
    }

    constructor(address admin) ERC721("D-WorkCredentialNFT 2023", "DWC2023") {
        _setupRole(ADMIN_ROLE, admin);
    }

    /**
     * @dev Mints a single NFT and assigns it to the given address.
     * @param minterAddress The address to whom the NFT will be minted.
     * @param description The description of the NFT.
     */
    function mint(
        address minterAddress,
        string memory description
    ) public payable whenNotPaused onlyAdmin {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(minterAddress, tokenId);

        TokenData storage tokenData = _tokenData[tokenId];
        tokenData.minterAddress = minterAddress;
        tokenData.description = description;
    }

    /**
     * @dev Mints multiple NFTs in a batch and assigns them to the given addresses.
     * @param minterAddresses The addresses to whom the NFTs will be minted.
     * @param descriptions The descriptions of the NFTs.
     */
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

    /**
     * @dev Returns the token URI with additional metadata.
     * @param tokenId The ID of the token.
     */
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

    /**
     * @dev Performs actions before transferring tokens.
     * @param from The address from which the tokens are being transferred.
     * @param to The address to which the tokens are being transferred.
     * @param tokenId The ID of the token being transferred.
     * @param batchSize The size of the batch (not used in this contract).
     */
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

    /**
     * @dev Burns an NFT by admin.
     * @param tokenId The ID of the token to be burned.
     */
    function burn(uint256 tokenId) external onlyAdmin {
        _burn(tokenId);
    }

    /**
     * @dev Checks if the contract supports the given interface.
     * @param interfaceId The interface ID to check.
     */
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

    /**
     * @dev Pauses the contract by admin.
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpauses the contract by admin.
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    /**
     * @dev Sets approval for all tokens (reverts to prevent usage for non-transferable NFTs).
     * @param to The address for which the approval is set.
     * @param approved True if the address is approved, false otherwise.
     */
    function setApprovalForAll(
        address to,
        bool approved
    ) public virtual override(ERC721, IERC721) {
        revert(
            "You can't approve this NFT because this is Non Transferable NFT."
        );
    }

    /**
     * @dev Grants admin role to a new address by the owner.
     * @param newadmin The address to which the admin role will be granted.
     */
    function addAdmin(address newadmin) external onlyOwner {
        grantRole(ADMIN_ROLE, newadmin);
    }

    /**
     * @dev Revokes admin role from an address by the owner.
     * @param admin The address from which the admin role will be revoked.
     */
    function revoke_adminRole(address admin) external onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
    }

    /**
     * @dev Gets the token IDs and metadata for tokens owned by the given address.
     * @param owner The address for which the tokens are owned.
     */
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