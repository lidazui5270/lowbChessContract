// contracts/LowbMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChessContract {

    address public lowbTokenAddress;

    address public owner;

    /* Inverse basis point. */
    uint private constant INVERSE_BASIS_POINT = 10000;
    uint private fee;
    /* 自增GameId */
    uint private curGameId = 100;

    struct ChessGame {
        bool isPlaying;
        address redPlayer;
        address blckPlayer;
        uint value;
    }

    mapping (address => uint) public pendingWithdrawals;

    mapping (uint => ChessGame) public playingChessGame;
    mapping (address => ChessGame) public GamePlayers;

    event GameStart(uint indexed gameId, uint value, address redAddress, address blackAddress);
    event GameOver(uint indexed gameId, uint value, address redAddress, address blackAddress, uint gameResult);


    constructor(address lowbToken_) {
        lowbTokenAddress = lowbToken_;
        owner = msg.sender;
        fee = 250;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner");
        _;
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

    /* 开始游戏 */
    function startPlayGame(address redPlayer, address blackPlayer, uint value_) public onlyOwner returns(uint) {
        require(!GamePlayers[redPlayer].isPlaying, "redPlayer in another room");
        require(!GamePlayers[blackPlayer].isPlaying, "blackPlayer in another room");
        require(value_ <= pendingWithdrawals[redPlayer], "redPlayer value_ larger than that pending to withdraw");  
        require(value_ <= pendingWithdrawals[blackPlayer], "redPlayer value_ larger than that pending to withdraw");  
        pendingWithdrawals[redPlayer] -= value_;
        pendingWithdrawals[blackPlayer] -= value_;
        ChessGame memory game = ChessGame(true, redPlayer, blackPlayer, value_ * 2);
        GamePlayers[redPlayer] = game;
        GamePlayers[blackPlayer] = game;
        curGameId++;
        playingChessGame[curGameId] = game;
        emit GameStart(curGameId, value_, redPlayer, blackPlayer);
        return curGameId;
    }


    /* 结束游戏 */
    function gameOver(uint gameId, uint gameResult) public onlyOwner {
        ChessGame memory game = playingChessGame[gameId];
        uint value = game.value;
        uint deal = _makeDeal(value);
        uint realValue = value - deal;
        if (gameResult == 12) {
            pendingWithdrawals[game.redPlayer] += realValue;
        } else if (gameResult == 22) {
            pendingWithdrawals[game.blckPlayer] += realValue;
        }
        emit GameOver(gameId, value, game.redPlayer, game.blckPlayer, gameResult);
        game.isPlaying = false;
        game.value = 0;
    }



    function pullFunds() public onlyOwner {
        IERC20 lowb = IERC20(lowbTokenAddress);
        lowb.transfer(msg.sender, pendingWithdrawals[address(this)]);
        pendingWithdrawals[address(this)] = 0;
    }

}