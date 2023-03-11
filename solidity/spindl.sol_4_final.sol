// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MyTokenERC20 is ERC20, EIP712, ERC20Burnable, Pausable, Ownable {
    //using Counters for Counters.Counter;
    
    //Counters.Counter private _tokenIdCounter;
    string private constant SIGNING_DOMAIN = "OFFCHAINPROPOSAL";
    string private constant SIGNATURE_VERSION = "1";
    
    //event 
    event Log(address indexed client, string transaction_id);

    // redeemed mapping
    mapping (bytes32 => bool) public redeemed;
    
    // set vault as controller only
    mapping(address => bool) controllers;

    constructor() ERC20("SPI_1", "SPI1") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}


    function check(address client,string calldata transaction_id,bytes calldata signature) internal view returns (address){
        return _verify(client, transaction_id, signature);

    }

    function _verify(address client,string calldata transaction_id,bytes calldata signature) internal view returns (address) {
        bytes32 digest = _hash(client, transaction_id);
        return ECDSA.recover(digest, signature); 
    }

    function _hash(address client,string calldata transaction_id) internal view returns (bytes32){
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(address client,string transaction_id)"),
            client, 
            keccak256(bytes(transaction_id))
        )));
    }

    function verifySignature(address client,string calldata transaction_id,bytes calldata signature) public view returns (address){
        //require (_verify(id, walletaddress, amount, signature) == msg.sender, "Invalid coupon");

        return _verify(client, transaction_id, signature);
    } // change check to return true if = owner


    function logSignature(address[] calldata clients,string[] calldata transaction_ids,bytes[] calldata signatures) public {
        address client;
        string calldata transaction_id;
        bytes calldata signature;
        
        // ensure no duplicate entry
        for (uint i = 0; i < transaction_ids.length; i++) {
        
        client = clients[i];
        transaction_id = transaction_ids[i];
        signature = signatures[i];

        bytes32 txHash = _hash(client,transaction_id);
        require(!redeemed[txHash], "Tx executed");

        require (_verify(client, transaction_id, signature) == msg.sender, "Invalid signature");
        redeemed[txHash] = true;

        emit Log(client, transaction_id);
        }

        _mint(msg.sender, transaction_ids.length*5*10**18);

    } 

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function renounceOwnership() public override view onlyOwner {
        revert("Don't send this smart contract to a null address");
    }

    // Rewards protocol for vault storers

    function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only the Vault Address can mint");
    _mint(to, amount*10**18);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

}
