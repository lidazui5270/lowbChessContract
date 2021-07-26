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
        bool isPlaying;
        uint gameId;
        address redPlayer;
        address blackPlayer;
        uint value;
        OneChess oneChess;
    }

    struct PenddingGame {
        bool exist;
        address redPlayer;
        address blackPlayer;
    }

    /** 1w,3w,5w 棋局 */
    PenddingGame public penddingChess10K;
    PenddingGame public penddingChess30K;
    PenddingGame public penddingChess50K;

    mapping (address => uint) public pendingWithdrawals;

    mapping (uint => ChessGame) public playingChessGame;
    mapping (address => ChessGame) public GamePlayers;

    ChessGame private curChessGame;
    OneChess private curOneChess;

    event GameStart(uint indexed gameId, address redAddress, address blackAddress, uint value);
    event GameChange(uint indexed gameId, address indexed redAddress, address indexed blackAddress, bool changeSuccess, uint eatPieceId);
    event GameOver(uint indexed gameId, address indexed redAddress, address indexed blackAddress, address winner, bool gameOver, bool changeSuccess, uint eatPieceId);


    constructor(address lowbToken_) {
        lowbTokenAddress = lowbToken_;
        owner = msg.sender;
        fee = 250;
    }

    modifier onlyOwner{
        require(tx.origin == owner, "You are not the owner");
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
    function startPlayGame(uint value_) public returns(uint) {
        require(!GamePlayers[msg.sender].isPlaying, "player in another room");
        require(value_ <= pendingWithdrawals[msg.sender], "player value_ larger than that pending to withdraw");  
        require((value_ == 10000) || (value_ == 30000) || (value_ == 50000), "invalid value_");
        pendingWithdrawals[msg.sender] -= value_;
        if (value_ == 10000) {
            if (penddingChess10K.exist) {
                penddingChess10K.blackPlayer = msg.sender;
                curGameId++;
                curOneChess = new OneChess(penddingChess30K.redPlayer, penddingChess30K.blackPlayer);
                curChessGame = ChessGame(true, curGameId, penddingChess10K.redPlayer, penddingChess10K.blackPlayer, value_ * 2, curOneChess);
                GamePlayers[penddingChess10K.redPlayer] = curChessGame;
                GamePlayers[penddingChess10K.blackPlayer] = curChessGame;
                penddingChess10K.exist = false;
                playingChessGame[curGameId] = curChessGame;
                emit GameStart(curGameId, penddingChess10K.redPlayer, penddingChess10K.blackPlayer, value_ * 2);
            } else {
                penddingChess10K = PenddingGame(true, msg.sender, address(0));
            }
        } else if (value_ == 30000) {
            if (penddingChess30K.exist) {
                penddingChess30K.blackPlayer = msg.sender;
                curGameId++;
                curOneChess = new OneChess(penddingChess30K.redPlayer, penddingChess30K.blackPlayer);
                curChessGame = ChessGame(true, curGameId, penddingChess30K.redPlayer, penddingChess30K.blackPlayer, value_ * 2, curOneChess);
                GamePlayers[penddingChess30K.redPlayer] = curChessGame;
                GamePlayers[penddingChess30K.blackPlayer] = curChessGame;
                penddingChess30K.exist = false;
                playingChessGame[curGameId] = curChessGame;
                emit GameStart(curGameId, penddingChess30K.redPlayer, penddingChess30K.blackPlayer, value_ * 2);
            } else {
                penddingChess30K = PenddingGame(true, msg.sender, address(0));
            }

        } else if (value_ == 50000) {
            if (penddingChess50K.exist) {
                penddingChess50K.blackPlayer = msg.sender;
                curGameId++;
                curOneChess = new OneChess(penddingChess30K.redPlayer, penddingChess30K.blackPlayer);
                curChessGame = ChessGame(true, curGameId, penddingChess50K.redPlayer, penddingChess50K.blackPlayer, value_ * 2, curOneChess);
                GamePlayers[penddingChess10K.redPlayer] = curChessGame;
                GamePlayers[penddingChess10K.blackPlayer] = curChessGame;
                penddingChess10K.exist = false;
                playingChessGame[curGameId] = curChessGame;
                emit GameStart(curGameId, penddingChess50K.redPlayer, penddingChess50K.blackPlayer, value_ * 2);
            } else {
                penddingChess10K = PenddingGame(true, msg.sender, address(0));
            }

        } 
        return curGameId;
    }

    function chageGame(uint pieceId,uint x, uint y) public {
        require(GamePlayers[tx.origin].isPlaying, "player is not in gaming");
        bool chageSuccess;
        bool gameOver;
        string memory errMsg;
        address winner;
        uint eatPieceId;
        (chageSuccess, gameOver, errMsg, winner, eatPieceId) = GamePlayers[tx.origin].oneChess.chagePiece(pieceId, x, y);
        uint gameId = GamePlayers[tx.origin].gameId;
        address redPlayer = GamePlayers[tx.origin].redPlayer;
        address blackPlayer = GamePlayers[tx.origin].blackPlayer;
        require(chageSuccess, errMsg);
        if (gameOver) {
            gameOverConfirm(gameId, winner);
            emit GameOver(gameId, redPlayer, blackPlayer,winner, gameOver, chageSuccess, eatPieceId);
        } else {
            emit GameChange(gameId, redPlayer, blackPlayer, chageSuccess, eatPieceId);
        }
    }


    /* 结束游戏 */
    function gameOverConfirm(uint gameId, address winner) public {
        ChessGame memory game = playingChessGame[gameId];
        require((tx.origin == owner) || (tx.origin == game.redPlayer) || (tx.origin == game.blackPlayer), "You can not over the game");
        uint value = game.value;
        uint deal = _makeDeal(value);
        uint realValue = value - deal;
        pendingWithdrawals[winner] += realValue;
        pendingWithdrawals[owner] += deal;
        playingChessGame[gameId].isPlaying = false;
        GamePlayers[game.redPlayer].isPlaying = false;
        GamePlayers[game.blackPlayer].isPlaying = false;
        playingChessGame[gameId].value = 0;
    }



    function pullFunds() public onlyOwner {
        IERC20 lowb = IERC20(lowbTokenAddress);
        lowb.transfer(msg.sender, pendingWithdrawals[address(this)]);
        pendingWithdrawals[address(this)] = 0;
    }

}