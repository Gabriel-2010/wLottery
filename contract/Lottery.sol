/*
MIT License

Copyright (c) 2019 Gabriel Guo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.5.6;

import "./SafeMath.sol";
import "./Owned.sol";
import "./Halt.sol";

contract Lottery is Halt {
  using SafeMath for uint;

  uint private constant MIN_AWARD = uint(10);
  uint private constant MAX_AWARD = uint(100000);
  uint private constant DEF_AWARD = uint(10000);

  uint public award = DEF_AWARD;  /* WAN unit */

  function toWin(uint value) private returns(uint) {
    return value.mul(1 ether);
  }

  function fromWin(uint value) private returns(uint) {
    return value.div(1 ether);
  }

  function setMaxAward(uint value) 
    external
    onlyOwner
    isHalted
    returns (bool)
  {
    if ((value >= MIN_AWARD) && (value <= MAX_AWARD)) {
      award = value;
      return true;
    } else {
      return false;
    }
  }

  function () 
    external
    payable
    notHalted
  {
    revert();
  }

 
}