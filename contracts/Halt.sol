pragma solidity ^0.5.6;

import './Owned.sol';

contract Halt is Owned {
    
    bool private halted = false; 
    
    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier isHalted() {
        require(halted);
        _;
    }
    
    /// @notice function Emergency situation that requires 
    /// @notice contribution period to stop or not.
    function setHalt(bool halt) 
        external 
        onlyOwner
    {
        halted = halt;
    }
}