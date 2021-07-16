// contracts/LowbMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChessContract {

    address public lowbTokenAddress;

    address public owner;

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;
    uint public fee;

    struct ChessGame {
        bool isUsed;
        bool isPlaying;
        address redPlayer;
        address blckPlayer;
        uint value;
    }

    mapping (address => uint) public pendingWithdrawals;

    mapping (uint => ChessGame) public playingChessGame;
    mapping (address => ChessGame) public GamePlayers;


    constructor(address lowbToken_) {
        lowbTokenAddress = lowbToken_;
        owner = msg.sender;
        fee = 250;
    }

    function deposit(uint amount) public {
        require(amount > 0, "You deposit nothing!");
        IERC20 token = IERC20(lowbTokenAddress);
        require(token.transferFrom(tx.origin, address(this), amount), "Lowb transfer failed");
        pendingWithdrawals[tx.origin] +=  amount;
    }

    function withdraw(uint amount) public {
        require(amount <= pendingWithdrawals[tx.origin], "amount larger than that pending to withdraw");  
        pendingWithdrawals[tx.origin] -= amount;
        IERC20 token = IERC20(lowbTokenAddress);
        require(token.transfer(tx.origin, amount), "Lowb transfer failed");
    }

    function _makeDeal(uint amount) private returns (uint) {
        uint fee_amount = amount / INVERSE_BASIS_POINT * fee;
        uint actual_amount = amount - fee_amount;
        require(actual_amount > 0, "Fees should less than the transaction value.");
        pendingWithdrawals[address(this)] += fee_amount;
        return actual_amount;
    }

    function createRoom(uint value_) public {
        require(!GamePlayers[msg.sender].isUsed, "you are in another room");
        ChessGame memory game = ChessGame(true, true, msg.sender, address(0), value_);
        GamePlayers[msg.sender] = game;
        pendingWithdrawals[msg.sender] -= value_;
    }

    function enterRoom(uint gameId, uint value_) public {
        require(!GamePlayers[msg.sender].isUsed, "you are in another room!");
        require(playingChessGame[gameId].isUsed, "the room is not exist!");
        ChessGame memory game = playingChessGame[gameId];
        game.blckPlayer = msg.sender;
        pendingWithdrawals[msg.sender] -= value_;
        game.value += value_;
    }

    function gameOver(uint gameId, uint gameResult) public {
        require(msg.sender == owner, "Only owner can gameOver!");
        ChessGame memory game = playingChessGame[gameId];
        uint value = game.value;
        uint deal = _makeDeal(value);
        uint realValue = value - deal;
        pendingWithdrawals[game.blckPlayer] += realValue;
        game.isPlaying = false;
        game.value = 0;
    }



    function pullFunds() public {
        require(msg.sender == owner, "Only owner can pull the funds!");
        IERC20 lowb = IERC20(lowbTokenAddress);
        lowb.transfer(msg.sender, pendingWithdrawals[address(this)]);
        pendingWithdrawals[address(this)] = 0;
    }

}