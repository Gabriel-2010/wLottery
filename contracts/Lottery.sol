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

  // uint private constant EPOCH_BLOCKS = uint(10000);
  uint private constant EPOCH_BLOCKS = uint(100);

  /* Who trigger the draw action will get 1/1000 of total funds up to 1 WAN */
  uint private constant DRAW_AWARD_DENOMINATOR = uint(1000);
  uint private constant DRAW_AWARD_MAXIMUM = 1 ether;


  struct Player {
    address payable addr;
    uint            fund;
  }
  mapping(uint => Player) public mapPlayers;

  uint public totalPlayers = 0;
  uint public startBlock = 0;

  event PlayerAddedEvent(address indexed player, uint indexed amount);
  event RandomEvent(uint indexed random, uint indexed totalAmount, uint indexed offset);
  event WinnerAwardEvent(address indexed player, uint indexed amount);
  event DrawAwardEvent(address indexed player, uint indexed amount);
  
  function toWin(uint value) private pure returns(uint) {
    return value.mul(1 ether);
  }

  function fromWin(uint value) private pure returns(uint) {
    return value.div(1 ether);
  }

  function getPlayers() external view returns(address payable [] memory, uint[] memory) {
    address payable[] memory addrs = new address payable[](totalPlayers);
    uint[]    memory funds = new uint[](totalPlayers);
    
    for (uint i = 0; i < totalPlayers; i++) {
      Player memory player = mapPlayers[i];
      addrs[i] = player.addr;
      funds[i] = player.fund;
    }
    return (addrs, funds);
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encodePacked(now, blockhash(block.number - 1))));
  }

  function resetEpoch() private {
    totalPlayers = 0;
  }

  function min(uint a, uint b) private pure returns (uint) {
      return a < b ? a : b;
  }

  function draw() private {
    startBlock = 0;

    uint funds = address(this).balance.sub(msg.value);
    uint totalAmount = fromWin(funds);

    uint randomNumber = random();
    uint offset = randomNumber % totalAmount;
    emit RandomEvent(randomNumber, totalAmount, offset);

    for (uint j = 0; j < totalPlayers; j++) {
      Player memory player = mapPlayers[j];
      uint wanAmount = player.fund;
      if (offset < wanAmount) {
        uint drawAward = min(funds.div(DRAW_AWARD_DENOMINATOR), DRAW_AWARD_MAXIMUM);
        uint award = funds.sub(drawAward);

        msg.sender.transfer(drawAward);
        emit DrawAwardEvent(msg.sender, drawAward);
        
        player.addr.transfer(award);
        emit WinnerAwardEvent(player.addr, award);
        break;
      }
      offset = offset.sub(wanAmount);
    }

    resetEpoch();
  }

  function addPlayer(address payable playerAddr, uint wanAmount) private {
    mapPlayers[totalPlayers].addr = playerAddr;
    mapPlayers[totalPlayers].fund = wanAmount;
    totalPlayers = totalPlayers.add(1);
    emit PlayerAddedEvent(playerAddr, wanAmount);
  }

  function () 
    external
    payable
    notHalted
  {
    /* Avoid being called by contract */
    require(msg.sender == tx.origin);

    if (startBlock != 0 && block.number >= startBlock.add(EPOCH_BLOCKS)) {
      draw();
    }

    /* The bet amount should be the integer times of 1 WAN */
    uint wanAmount = fromWin(msg.value);
    if (wanAmount != 0) {
      if (startBlock == 0) {
        startBlock = block.number;
      }
      addPlayer(msg.sender, wanAmount);
    }
    uint rest = msg.value.sub(toWin(wanAmount));
    if (rest > 0 ether) {
      msg.sender.transfer(rest);
    }
  }

 
}