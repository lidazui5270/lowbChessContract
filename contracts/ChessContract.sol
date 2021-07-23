// contracts/LowbMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./OneChess.sol";
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
        bool isPlaying = false;
        uint gameId;
        address redPlayer;
        address blckPlayer;
        uint value;
        OneChess oneChess;
    }

    struct PenddingGame {
        bool exist = false;
        address redPlayer;
        address blckPlayer;
    }

    /** 1w,3w,5w 棋局 */
    PenddingGame public penddingChess10K;
    PenddingGame public penddingChess30K;
    PenddingGame public penddingChess50K;

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
    function startPlayGame(uint value_) public onlyOwner returns(uint) {
        require(!GamePlayers[msg.sender].isPlaying, "player in another room");
        require(value_ <= pendingWithdrawals[msg.sender], "player value_ larger than that pending to withdraw");  
        pendingWithdrawals[msg.sender] -= value_;
        if (value_ == 10000) {
            if (penddingChess10K.exist) {
                penddingChess10K.blckPlayer = msg.sender;
                curGameId++;
                OneChess memory oneChess = OneChess(penddingChess30K.redPlayer, penddingChess30K.blackPlayer);
                ChessGame memory game = ChessGame(true, curGameId, penddingChess10K.redPlayer, penddingChess10K.blackPlayer, value_ * 2, oneChess);
                GamePlayers[penddingChess10K.redPlayer] = game;
                GamePlayers[penddingChess10K.blackPlayer] = game;
                penddingChess10K.exist = false;
                playingChessGame[curGameId] = game;
            } else {
                penddingChess10K = PenddingGame(true, msg.sender, 0);
            }
        } else if (value_ == 30000) {
            if (penddingChess30K.exist) {
                penddingChess30K.blckPlayer = msg.sender;
                curGameId++;
                OneChess memory oneChess = OneChess(penddingChess30K.redPlayer, penddingChess30K.blackPlayer);
                ChessGame memory game = ChessGame(true, curGameId, penddingChess30K.redPlayer, penddingChess30K.blackPlayer, value_ * 2, oneChess);
                GamePlayers[penddingChess30K.redPlayer] = game;
                GamePlayers[penddingChess30K.blackPlayer] = game;
                penddingChess30K.exist = false;
                playingChessGame[curGameId] = game;
            } else {
                penddingChess30K = PenddingGame(true, msg.sender, 0);
            }

        } else if (value_ == 50000) {
            if (penddingChess50K.exist) {
                penddingChess50K.blckPlayer = msg.sender;
                curGameId++;
                OneChess memory oneChess = OneChess(penddingChess30K.redPlayer, penddingChess30K.blackPlayer);
                ChessGame memory game = ChessGame(true, curGameId, penddingChess50K.redPlayer, penddingChess50K.blackPlayer, value_ * 2, oneChess);
                GamePlayers[penddingChess10K.redPlayer] = game;
                GamePlayers[penddingChess10K.blackPlayer] = game;
                penddingChess10K.exist = false;
                playingChessGame[curGameId] = game;
            } else {
                penddingChess10K = PenddingGame(true, msg.sender, 0);
            }

        } else {
            throw;
        }
        emit GameStart(curGameId, value_, redPlayer, blackPlayer);
        return curGameId;
    }

    function chageGame(uint pieceId,uint x, uint y) {
        require(GamePlayers[msg.sender].isPlaying, "player is not in gaming");
        bool chageSuccess;
        bool gameOver;
        string errMsg;
        address winner;
        (chageSuccess, gameOver, errMsg, winner) = GamePlayers[msg.sender].oneChess.chagePiece(pieceId, x, y);
        require(chageSuccess, errMsg);
        if (gameOver) {
            gameOver(gameId,winner);
        }
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
        pendingWithdrawals[owner] += deal;
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