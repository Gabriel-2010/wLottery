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

  uint private constant DEFAULT_AWARD = uint(10000);  /* WAN unit */
  uint private constant EPOCH_BLOCKS = uint(10000);

  address payable [] private players;
  mapping(address => uint) private mapAmount;
  uint private startBlock = 0;

  event BetEvent(address indexed player, uint indexed amount);
  event RandomDebug(uint indexed random, uint indexed totalAmount, uint indexed offset);
  event Congrat(address indexed player, uint indexed amount);
  
  function toWin(uint value) private pure returns(uint) {
    return value.mul(1 ether);
  }

  function fromWin(uint value) private pure returns(uint) {
    return value.div(1 ether);
  }

  function getPlayer() external view returns(address payable[] memory) {
    return players;
  }

  function getAmount(address player) external view returns(uint) {
    return mapAmount[player];
  }

  function random(uint index) public view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, now, blockhash(block.number - 1), index)));
  }

  function resetEpoch() private {
    revert();
  }

  function draw() private {
    startBlock = 0;

    uint totalAmount = fromWin(address(this).balance);
    uint entropy = 0;

    while (address(this).balance > 0) {
      uint randomNumber = random(entropy);
      uint offset = randomNumber % totalAmount;
      emit RandomDebug(randomNumber, totalAmount, offset);

      for (uint j = 0; j < players.length; j++) {
        address payable player = players[j];
        uint wanAmount = fromWin(mapAmount[player]);
        if (offset < wanAmount) {
          uint award = address(this).balance > DEFAULT_AWARD ? DEFAULT_AWARD: address(this).balance;
          player.transfer(award);
          emit Congrat(player, award);
          break;
        }
        offset = offset.sub(wanAmount);
      }
      entropy++;
    }

    resetEpoch();
  }

  function addPlayer(address payable player, uint wanAmount) private {
    if (mapAmount[player] == 0) {
      players.push(player);
    }
    mapAmount[player] = mapAmount[player].add(wanAmount);
    emit BetEvent(player, wanAmount);
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