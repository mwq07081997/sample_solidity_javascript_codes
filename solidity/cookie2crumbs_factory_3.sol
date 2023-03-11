// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0; // change to appropriate 

import "https://github.com/mwq07081997/cookie2crumbs/Cookie2Council.sol"; // child contract (Cookie2Council)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";



// parent contract - factory, delegator, signature-minting
contract CookieFactory is ERC20, EIP712, ERC20Burnable, Pausable, Ownable{

    // instantiate Bank contract
    Cookie2Council council;

    //keep track of created Bank addresses in array 
    Cookie2Council[] public list_of_councils;

    //Counters.Counter private _tokenIdCounter;
    string private constant SIGNING_DOMAIN = "OFFCHAINPROPOSAL";
    string private constant SIGNATURE_VERSION = "1";
    
    //event log (controller call contract, tx caller address, ipfs cid)
    event Log(address indexed client, address indexed origin , string transaction_id);

    // redeemed mapping - for minted signature
    mapping (bytes32 => bool) public redeemed;
    
    // set child contracts as controller only
    mapping(address => bool) public controllers;

    constructor() ERC20("SPI_1", "SPI1") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}


    // function for factory of Cookie2Council
    function createCouncil(address _owner, string memory _name) public returns (address){
      council = new Cookie2Council(_name, _owner);
      council.transferOwnership(_owner);
      
      list_of_councils.push(council); // array for easy calling 
      controllers[address(council)] = true; // add child contract as controller

      return address(council);  // use it to redirect to the childcontract's URL
    }

    // functions for signature-based activities ----
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

    // ---- functions for signature-based activities

    // single event logging - CONVERT to MINT BY SIGNATURE function
    function signatureMint(address client, string calldata transaction_id) public {

        //if add mapping of txHash, cost how much = XX
        bytes32 txHash = _hash(client, transaction_id);
        require(!redeemed[txHash], "Tx executed");

        //verify signature only, do u really need this if u have nodes??? cost how much = 33K gas
        //require (_verify(clients, transaction_ids, signatures) == clients, "Invalid signature");
        redeemed[txHash] = true;

        _mint(msg.sender, 200*18**10);  // YOUR MATH IS WRONG
        // only event log, cost how much = 
        //emit Log(msg.sender, tx.origin, transaction_ids); // having msg.sender makes them accountable and can filter thier faulty data if bad actor
    }     
 
    
    // delegatecall-able function for Cookie2Council child contracts
    function logSignatures(string[] calldata transaction_ids) external {
        
        // for logging ids
        string calldata transaction_id;
        require(controllers[msg.sender], "Only whitelister can execute"); // msg.sender is not the contract address

        for (uint i = 0; i < transaction_ids.length; i++) {
            
            transaction_id = transaction_ids[i];
            emit Log(msg.sender, tx.origin, transaction_id);  // tx.origin instead of msg.sender because call() is used.
        }
    } 


    function pause() public 
    {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function renounceOwnership() public override view onlyOwner {
        revert("Don't send this smart contract to a null address");
    }

    // Controllers manual function - obsolete
    /*
    function whitelister(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only the Vault Address can mint");
    _mint(to, amount*10**18);
    }
    

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
    */
}

