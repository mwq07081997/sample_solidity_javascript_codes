// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0; // change to appropriate 

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// child contract
contract Cookie2Council is Ownable, Pausable{

    string public name;

    constructor(string memory _name, address _owner) {  
      name = _name;
      _grantRole(ADMIN, _owner);
    }

    // ROLE ACCESS
    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    //bytes32 - 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 private constant INDEXER = keccak256(abi.encodePacked("INDEXER"));
    //bytes32 - 0x55e51077bf24628f06725d47e76e20668b7caf5302854ee4599bd926587af502

    modifier onlyRole(bytes32 _role){
      require(roles[_role][msg.sender], "Not authorized");
      _;
    }

    // ROLE ACCESS FUNCTIONS
    function _grantRole(bytes32 _role, address _account) internal {
      roles[_role][_account] = true;
    }

    function grantRole(bytes32 _role, address _account) external onlyRole(ADMIN) {
      _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) external onlyRole(ADMIN) {
      roles[_role][_account] = false;
    }


    // call to main contract to save logs
    function logSignatures(address _contract, string[] calldata transaction_ids) external onlyRole(INDEXER) {
        // A's storage is set, B is not modified.
        string calldata transaction_id;

        (bool success, bytes memory data) = _contract.call(
            abi.encodeWithSignature("logSignatures(string[])", transaction_ids)
        );

        require (success, "delegate call failed: ");
    }

    function pause() public onlyRole(ADMIN) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN) {
        _unpause();
    }
    
}
