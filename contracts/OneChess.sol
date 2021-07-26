// contracts/LowbMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**  棋局中id对应的棋子
	 * 1：黑将
	 * 2：黑车左
     * 3：黑车右
	 * 4：黑马左
     * 5：黑马右
	 * 6：黑炮左
     * 7：黑炮右
	 * 8：黑士左
     * 9：黑士右
	 * 10：黑相左
     * 11：黑相右
	 * 12：黑卒1
     * 13：黑卒2
     * 14：黑卒3
     * 15：黑卒4
     * 16：黑卒5
	 * 17：红兵1
     * 18：红兵2
     * 19：红兵3
     * 20：红兵4
     * 21：红兵5
	 * 22：红车左
     * 23：红车右
	 * 24：红马左
     * 25：红马右
	 * 26：红炮左
     * 27：红炮右
	 * 28：红士左
     * 29：红士右
	 * 30：红象左
     * 31：红象右
     * 32：红帅
	 */

/** 一局棋 */
contract OneChess {

    uint private constant DEAD_PIECE = 100;

    /** 棋局位置 */
    struct Point{
        uint x;
        uint y;
    }

    bool private isRedTurn = true;

    address private redPlayer;
    address private blackPlayer;

    /** 棋盘当前布局 */
    mapping(uint => Point) public chessBoard;
    uint[9][10] private board;


    constructor(address redAddress, address blackAddress) {
        redPlayer = redAddress;
        blackPlayer = blackAddress;
        //设置默认棋子位置
        //黑将
        chessBoard[1] = Point(4,0);
        board[0][4] = 1;
        //黑车
        chessBoard[2] = Point(0,0);
        chessBoard[3] = Point(8,0);
        board[0][0] = 2;
        board[0][8] = 3;
        //黑马
        chessBoard[4] = Point(1,0);
        chessBoard[5] = Point(7,0);
        board[0][1] = 4;
        board[0][7] = 5;
        //黑炮
        chessBoard[6] = Point(1,2);
        chessBoard[7] = Point(7,2);
        board[2][1] = 6;
        board[2][7] = 7;
        //黑士
        chessBoard[8] = Point(3,0);
        chessBoard[9] = Point(5,0);
        board[0][3] = 8;
        board[0][5] = 9;
        //黑象
        chessBoard[10] = Point(2,0);
        chessBoard[11] = Point(6,0);
        board[0][2] = 10;
        board[0][6] = 11;
        //黑卒
        chessBoard[12] = Point(0,3);
        chessBoard[13] = Point(2,3);
        chessBoard[14] = Point(4,3);
        chessBoard[15] = Point(6,3);
        chessBoard[16] = Point(8,3);
        board[3][0] = 12;
        board[3][2] = 13;
        board[3][4] = 14;
        board[3][6] = 15;
        board[3][8] = 16;

        //红兵
        chessBoard[17] = Point(0,6);
        chessBoard[18] = Point(2,6);
        chessBoard[19] = Point(4,6);
        chessBoard[20] = Point(6,6);
        chessBoard[21] = Point(8,6);

        board[6][0] = 17;
        board[6][2] = 18;
        board[6][4] = 19;
        board[6][6] = 20;
        board[6][8] = 21;

        //红车
        chessBoard[22] = Point(0,9);
        chessBoard[23] = Point(8,9);
        board[9][0] = 22;
        board[9][8] = 23;

        //红马
        chessBoard[24] = Point(1,9);
        chessBoard[25] = Point(7,9);
        board[9][1] = 24;
        board[9][7] = 25;
        //红炮
        chessBoard[26] = Point(1,7);
        chessBoard[27] = Point(7,7);
        board[7][1] = 26;
        board[7][7] = 27;
        //红士
        chessBoard[28] = Point(3,9);
        chessBoard[29] = Point(5,9);
        board[9][3] = 28;
        board[9][5] = 29;
        //红相
        chessBoard[30] = Point(2,9);
        chessBoard[31] = Point(6,9);
        board[9][2] = 30;
        board[9][6] = 31;
        //红帅
        chessBoard[32] = Point(4,9);
        board[9][4] = 32;
    }

    /** 改变棋子位置 */
    function chagePiece(uint pieceId, uint x, uint y) public returns(bool, bool, string memory,address, uint) {
        if (pieceId <= 0 || pieceId > 32) {
            return (false, false, "invalid pieceId", address(0), 0);
        }
        if (x < 0 || x > 8 || y < 0 || y > 9) {
            return (false, false, "invalid x or y", address(0), 0);
        }
        Point memory srcPoint = chessBoard[pieceId];
        if (srcPoint.x == DEAD_PIECE || srcPoint.y == DEAD_PIECE) {
            return (false, false, "piece is dead", address(0), 0);
        }
        if ((srcPoint.x == x && srcPoint.y == y)) {
            return (false, false, "you donot move", address(0), 0);
        }
        return isChangeValid(pieceId, x, y);
    }

    /** 判断这步棋是否合规 */
    function isChangeValid(uint pieceId, uint x, uint y) public returns(bool, bool, string memory, address, uint) {
        if (isRedTurn && pieceId < 17 && tx.origin == redPlayer) {
            return (false, false, "is not red turn", address(0), 0);
        }
        if (!isRedTurn && pieceId > 16 && tx.origin == blackPlayer) {
            return (false, false, "is not black turn", address(0), 0);
        }

        bool chageSuccess;
        bool gameOver;
        string memory errMsg;
        address winner;
        uint eatPieceId;

        if(isRedTurn) {
             (chageSuccess, gameOver, errMsg, winner, eatPieceId) = handleRedMove(pieceId, x, y);
        } else {
            (chageSuccess, gameOver, errMsg, winner, eatPieceId) = handleBlackMove(pieceId, x, y);
        }
        isRedTurn = !isRedTurn;
        return (chageSuccess, gameOver, errMsg, winner, eatPieceId);
    }

    function distanceX(uint x1, uint x2) public returns(uint) {
        if (x1 > x2) {
            return x1 - x2;
        } else {
            return x2 - x1;
        }
    }

    function distanceY(uint y1, uint y2) public returns(uint) {
        if (y1 > y2) {
            return y1 - y2;
        } else {
            return y2 - y1;
        }
    }

    function reportFailResultReson(string memory errMsgStr) public returns(bool, bool, string memory, address, uint) {

        bool chageSuccess = false;
        bool gameOver = false;
        string memory errMsg = errMsgStr;
        address winner = address(0);

        return (chageSuccess, gameOver, errMsg, winner, 0);

    }

    function reportConfirmResultRed(uint pieceId) public returns(bool, bool, string memory, address, uint) {
        bool chageSuccess = true;
        bool gameOver = false;
        string memory errMsg = "";
        address winner = address(0);
        uint eatPiece = pieceId;
        if (eatPiece == 1) {
            gameOver = true;
            winner = redPlayer;
            return (chageSuccess, gameOver, errMsg, winner, eatPiece);
        } else {
            return (chageSuccess, gameOver, errMsg, winner, eatPiece);
        }

    }

    function reportConfirmResultBlack(uint pieceId) public returns(bool, bool, string memory, address, uint) {
        bool chageSuccess = true;
        bool gameOver = false;
        string memory errMsg = "";
        address winner = address(0);
        uint eatPiece = pieceId;
        if (eatPiece == 32) {
            gameOver = true;
            winner = blackPlayer;
            return (chageSuccess, gameOver, errMsg, winner, eatPiece);
        } else {
            return (chageSuccess, gameOver, errMsg, winner, eatPiece);
        }

    }

    function handleRedMove(uint pieceId, uint x, uint y) public returns(bool, bool, string memory, address, uint) {
        Point storage srcPoint = chessBoard[pieceId];

        uint eatPiece = 0;
        //红帅
        if (pieceId == 32) {
            if (x >= 3 && x <= 5 && y >= 7 && y <= 9) {
                if ((distanceX(x, srcPoint.x) == 0 && distanceY(y, srcPoint.y) == 1) || (distanceX(x, srcPoint.x) == 1 && distanceY(y, srcPoint.y) == 0)) {
                    if(board[x][y] > 16){
                        //不能吃自己的子
                        return reportFailResultReson("you can eat your own piece");
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为DEAD_PIECE表示这个子被吃了
                        eatPiece = board[x][y];
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultRed(eatPiece);
                } else {
                    return reportFailResultReson("your King not in right move");
                }
                
            } else {
                return reportFailResultReson("your King not in right area");
            }
        } else if (pieceId == 28 || pieceId == 29) {//红士
            if (x >= 3 && x <= 5 && y >= 7 && y <= 9) {
                if (distanceX(x, srcPoint.x) == 1 && distanceY(y, srcPoint.y) == 1) {
                    if(board[x][y] > 16){
                        //不能吃自己的子
                        return reportFailResultReson("you can eat your own piece");
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        eatPiece = board[x][y];
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultRed(eatPiece);
                } else {
                    return reportFailResultReson("your Guard not in right move");
                }
            } else {
                return reportFailResultReson("your Guard not in right area");
            }
        } else if (pieceId == 30 || pieceId == 31) {//红相
            if (y >= 5) {
                if (distanceX(x, srcPoint.x) == 2 && distanceY(y, srcPoint.y) == 2) {
                    uint midX = (x + srcPoint.x) / 2;
                    uint midY = (y + srcPoint.y) / 2;
                    if (board[midX][midY] != 0) {
                        //相撇脚，不能这么走
                        return reportFailResultReson("your Elephant can not move like this");
                    }
                    if(board[x][y] > 16){
                        //不能吃自己的子
                        return reportFailResultReson("you can eat your own piece");
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultRed(eatPiece);
                } else {
                    return reportFailResultReson("your Elephant not in right move");
                }
            } else {
                return reportFailResultReson("your Guard not in right area");
            }
        } else if(pieceId == 24 || pieceId == 25){//红马
            if ((distanceX(x, srcPoint.x)==1 && distanceY(y, srcPoint.y)==2)){
                uint mX = srcPoint.x;
                uint mY = (y + srcPoint.y) / 2;
                if (board[mX][mY] != 0) {//撇马脚
                    return reportFailResultReson("your Horse can not move like this");
                }
                if(board[x][y] > 16){
                        //不能吃自己的子
                    return reportFailResultReson("you can eat your own piece");
                }
                if (board[x][y] > 0) {
                    eatPiece = board[x][y];
                    //坐标设置为DEAD_PIECE 表示这个子被吃了
                    chessBoard[board[x][y]].x = DEAD_PIECE;
                    chessBoard[board[x][y]].y = DEAD_PIECE;
                    //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return reportConfirmResultRed(eatPiece);
            } else if ((distanceX(x, srcPoint.x)==2 && distanceY(y, srcPoint.y)==1)) {
                uint mX = (x + srcPoint.x) / 2;
                uint mY = srcPoint.y;
                if (board[mX][mY] != 0) {//撇马脚
                    return reportFailResultReson("your Horse can not move like this");
                }
                if(board[x][y] > 16){
                    //不能吃自己的子
                    return reportFailResultReson("you can eat your own piece");
                }
                if (board[x][y] > 0) {
                    eatPiece = board[x][y];
                    //坐标设置为DEAD_PIECE 表示这个子被吃了
                    chessBoard[board[x][y]].x = DEAD_PIECE;
                    chessBoard[board[x][y]].y = DEAD_PIECE;
                    //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return reportConfirmResultRed(eatPiece);
            } else {
                return reportFailResultReson("your Horse not in right move");
            }
        } else if (pieceId == 22 || pieceId == 23) { //红车
            if(x == srcPoint.x) {
                if (srcPoint.y > y) {
                    for(uint curY = y + 1; curY < srcPoint.y; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            return reportFailResultReson("your Rook can not move like this");
                        }
                    }
                } else {
                    for(uint curY = srcPoint.y + 1; curY < y; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            return reportFailResultReson("your Rook can not move like this");
                        }
                    }
                }
            } else if (y == srcPoint.y) {
                if (srcPoint.x > x) {
                    for(uint curX = x + 1; curX < srcPoint.x; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            return reportFailResultReson("your Rook can not move like this");
                        }
                    }
                } else {
                    for(uint curX = srcPoint.x + 1; curX < x; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            return reportFailResultReson("your Rook can not move like this");
                        }
                    }
                }

            } else {
                return reportFailResultReson("your Rook not in right move");
            }

            if(board[x][y] > 16){
                    //不能吃自己的子
                return reportFailResultReson("you can eat your own piece");
            }
            if (board[x][y] > 0) {
                eatPiece = board[x][y];
                //坐标设置为DEAD_PIECE 表示这个子被吃了
                chessBoard[board[x][y]].x = DEAD_PIECE;
                chessBoard[board[x][y]].y = DEAD_PIECE;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return reportConfirmResultRed(eatPiece);
        } else if (pieceId == 26 || pieceId == 27) { //红炮
            if(board[x][y] < 17 && board[x][y] > 0){ //炮的终点有黑子，可以打过去
                uint count = 0;
                if(x == srcPoint.x) {
                    if (srcPoint.y > y) {
                        for(uint curY = y + 1; curY < srcPoint.y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curY = srcPoint.y + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }
                } else if (y == srcPoint.y) {
                    if (srcPoint.x > x) {
                        for(uint curX = x + 1; curX < srcPoint.x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curX = srcPoint.x + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }

                } else {
                    return reportFailResultReson("your Canon not in right move");
                }
                if (count != 1) {
                    return reportFailResultReson("your Canon not in right move two piece in middle");
                }
            } else if(board[x][y] == 0) { //炮的终点没有子
                if(x == srcPoint.x) {
                    if (srcPoint.y > y) {
                        for(uint curY = y + 1; curY < srcPoint.y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                return reportFailResultReson("your Canon not in right move one piece in middle");
                            }
                        }
                    } else {
                        for(uint curY = srcPoint.y + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                return reportFailResultReson("your Canon not in right move one piece in middle");
                            }
                        }
                    }
                } else if (y == srcPoint.y) {
                    if (srcPoint.x > x) {
                        for(uint curX = x + 1; curX < srcPoint.x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                return reportFailResultReson("your Canon not in right move one piece in middle");
                            }
                        }
                    } else {
                        for(uint curX = srcPoint.x + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                return reportFailResultReson("your Canon not in right move one piece in middle");
                            }
                        }
                    }

                } else {
                    return reportFailResultReson("your Canon not in right move");
                }
            }

            if(board[x][y] > 16){
                    //不能吃自己的子
                return reportFailResultReson("you can eat your own piece");
            }
            if (board[x][y] > 0) {
                eatPiece = board[x][y];
                //坐标设置为DEAD_PIECE 表示这个子被吃了
                chessBoard[board[x][y]].x = DEAD_PIECE;
                chessBoard[board[x][y]].y = DEAD_PIECE;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return reportConfirmResultRed(eatPiece);
        } else if (pieceId == 17 || pieceId == 18 || pieceId == 19 || pieceId == 20 || pieceId == 21) {//红兵
            if (srcPoint.y <= 4) { //过河了
               if ((y == srcPoint.y - 1 && x == srcPoint.x) || (y == srcPoint.y  && distanceX(x, srcPoint.x) == 1)) {
                   if(board[x][y] > 16){
                        //不能吃自己的子
                        return reportFailResultReson("you can eat your own piece");
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultRed(eatPiece);
               } else {
                   return reportFailResultReson("your Pawn not in right move");
               }

            } else { //没过河
               if (y == srcPoint.y - 1 && x == srcPoint.x) {
                   if(board[x][y] > 16){
                        //不能吃自己的子
                        return reportFailResultReson("you can eat your own piece");
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultRed(eatPiece);
               } else {
                   return reportFailResultReson("your Pawn not in right move");
               }

            }
        }
    }




    function isBlack(uint pieceId) public returns(bool) {
        if(pieceId < 17 && pieceId != 0){
            return true;
        }
        return false;
    }
    /** 黑子移动规则 */
    function handleBlackMove(uint pieceId, uint x, uint y) public returns(bool, bool, string memory, address, uint) {
        Point storage srcPoint = chessBoard[pieceId];

        string memory errMsg;
        uint eatPiece = 0;
        //黑将
        if (pieceId == 1) {
            if (x >= 3 && x <= 5 && y >= 0 && y <= 2) {
                if ((distanceX(x, srcPoint.x) == 0 && distanceY(y, srcPoint.y) == 1) || (distanceX(x, srcPoint.x) == 1 && distanceY(y, srcPoint.y) == 0)) {
                    if(isBlack(board[x][y])){
                        //不能吃自己的子
                        return reportFailResultReson("you can eat your own piece");
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultBlack(eatPiece);
                } else {
                    errMsg = "b your King not in right move";
                    return reportFailResultReson(errMsg);
                }
                
            } else {
                errMsg = "b your King not in right area";
                return reportFailResultReson(errMsg);
            }
        } else if (pieceId == 8 || pieceId == 9) {//黑士
            if (x >= 3 && x <= 5 && y >= 0 && y <= 2) {
                if (distanceX(x, srcPoint.x) == 1 && distanceY(y, srcPoint.y) == 1) {
                    if(isBlack(board[x][y])){
                        //不能吃自己的子
                        errMsg = "b you can eat your own piece";
                        return reportFailResultReson(errMsg);
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultBlack(eatPiece);
                } else {
                    errMsg = "b your Guard not in right move";
                    return reportFailResultReson(errMsg);
                }
            } else {
                errMsg = "b your Guard not in right area";
                return reportFailResultReson(errMsg);
            }
        } else if (pieceId == 10 || pieceId == 11) {//黑象
            if (y <= 4) {
                if (distanceX(x, srcPoint.x) == 2 && distanceY(y, srcPoint.y) == 2) {
                    uint midX = (x + srcPoint.x) / 2;
                    uint midY = (y + srcPoint.y) / 2;
                    if (board[midX][midY] != 0) {
                        //象撇脚，不能这么走
                        errMsg = "b your Elephant can not move like this";
                        return reportFailResultReson(errMsg);
                    }
                    if(isBlack(board[x][y])){
                        //不能吃自己的子
                        errMsg = "b you can eat your own piece";
                        return reportFailResultReson(errMsg);
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultBlack(eatPiece);
                } else {
                    errMsg = "b your Elephant not in right move";
                    return reportFailResultReson(errMsg);
                }
            } else {
                errMsg = "b your Guard not in right area";
                return reportFailResultReson(errMsg);
            }
        } else if(pieceId == 4 || pieceId == 5){//黑马
            if ((distanceX(x, srcPoint.x)==1 && distanceY(y, srcPoint.y)==2)){
                uint mX = srcPoint.x;
                uint mY = (y + srcPoint.y) / 2;
                if (board[mX][mY] != 0) {//撇马脚
                    errMsg = "b your Horse can not move like this";
                    return reportFailResultReson(errMsg);
                }
                if(isBlack(board[x][y])){
                        //不能吃自己的子
                    errMsg = "b you can eat your own piece";
                    return reportFailResultReson(errMsg);
                }
                if (board[x][y] > 0) {
                    eatPiece = board[x][y];
                    //坐标设置为DEAD_PIECE 表示这个子被吃了
                    chessBoard[board[x][y]].x = DEAD_PIECE;
                    chessBoard[board[x][y]].y = DEAD_PIECE;
                    //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return reportConfirmResultBlack(eatPiece);
            } else if ((distanceX(x, srcPoint.x)==2 && distanceY(y, srcPoint.y)==1)) {
                uint mX = (x + srcPoint.x) / 2;
                uint mY = srcPoint.y;
                if (board[mX][mY] != 0) {//撇马脚
                    errMsg = "b your Horse can not move like this";
                    return reportFailResultReson(errMsg);
                }
                if(isBlack(board[x][y])){
                    //不能吃自己的子
                    errMsg = "b you can eat your own piece";
                    return reportFailResultReson(errMsg);
                }
                if (board[x][y] > 0) {
                    eatPiece = board[x][y];
                    //坐标设置为DEAD_PIECE 表示这个子被吃了
                    chessBoard[board[x][y]].x = DEAD_PIECE;
                    chessBoard[board[x][y]].y = DEAD_PIECE;
                    //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return reportConfirmResultBlack(eatPiece);
            } else {
                errMsg = "b your Horse not in right move";
                return reportFailResultReson(errMsg);
            }
        } else if (pieceId == 2 || pieceId == 3) { //黑车
            if(x == srcPoint.x) {
                if (srcPoint.y > y) {
                    for(uint curY = y + 1; curY < srcPoint.y; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            errMsg = "b your Rook can not move like this";
                            return reportFailResultReson(errMsg);
                        }
                    }
                } else {
                    for(uint curY = srcPoint.y + 1; curY < y; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            errMsg = "b your Rook can not move like this";
                            return reportFailResultReson(errMsg);
                        }
                    }
                }
            } else if (y == srcPoint.y) {
                if (srcPoint.x > x) {
                    for(uint curX = x + 1; curX < srcPoint.x; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            errMsg = "b your Rook can not move like this";
                            return reportFailResultReson(errMsg);
                        }
                    }
                } else {
                    for(uint curX = srcPoint.x + 1; curX < x; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            errMsg = "b your Rook can not move like this";
                            return reportFailResultReson(errMsg);
                        }
                    }
                }

            } else {
                errMsg = "b your Rook not in right move";
                return reportFailResultReson(errMsg);
            }

            if(isBlack(board[x][y])){
                    //不能吃自己的子
                errMsg = "byou can eat your own piece";
                return reportFailResultReson(errMsg);
            }
            if (board[x][y] > 0) {
                eatPiece = board[x][y];
                //坐标设置为DEAD_PIECE 表示这个子被吃了
                chessBoard[board[x][y]].x = DEAD_PIECE;
                chessBoard[board[x][y]].y = DEAD_PIECE;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return reportConfirmResultBlack(eatPiece);
        } else if (pieceId == 6 || pieceId == 7) { //黑炮
            if(board[x][y] < 17 && board[x][y] > 0){ //炮的终点有黑子，可以打过去
                uint count = 0;
                if(x == srcPoint.x) {
                    if (srcPoint.y > y) {
                        for(uint curY = y + 1; curY < srcPoint.y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curY = srcPoint.y + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }
                } else if (y == srcPoint.y) {
                    if (srcPoint.x > x) {
                        for(uint curX = x + 1; curX < srcPoint.x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curX = srcPoint.x + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }

                } else {
                    errMsg = "b your Canon not in right move";
                    return reportFailResultReson(errMsg);
                }
                if (count != 1) {
                    errMsg = "b your Canon not in right move two piece in middle";
                    return reportFailResultReson(errMsg);
                }
            } else if(board[x][y] == 0) { //炮的终点没有子
                if(x == srcPoint.x) {
                    if (srcPoint.y > y) {
                        for(uint curY = y + 1; curY < srcPoint.y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                errMsg = "b your Canon not in right move one piece in middle";
                                return reportFailResultReson(errMsg);
                            }
                        }
                    } else {
                        for(uint curY = srcPoint.y + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                errMsg = "b your Canon not in right move one piece in middle";
                                return reportFailResultReson(errMsg);
                            }
                        }
                    }
                } else if (y == srcPoint.y) {
                    if (srcPoint.x > x) {
                        for(uint curX = x + 1; curX < srcPoint.x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                errMsg = "b your Canon not in right move one piece in middle";
                                return reportFailResultReson(errMsg);
                            }
                        }
                    } else {
                        for(uint curX = srcPoint.x + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                errMsg = "b your Canon not in right move one piece in middle";
                                return reportFailResultReson(errMsg);
                            }
                        }
                    }

                } else {
                    errMsg = "b your Canon not in right move";
                    return reportFailResultReson(errMsg);
                }
            }

            if(isBlack(board[x][y])){
                //不能吃自己的子
                errMsg = "b you can eat your own piece";
                return reportFailResultReson(errMsg);
            }
            if (board[x][y] > 0) {
                eatPiece = board[x][y];
                //坐标设置为DEAD_PIECE 表示这个子被吃了
                chessBoard[board[x][y]].x = DEAD_PIECE;
                chessBoard[board[x][y]].y = DEAD_PIECE;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return reportConfirmResultBlack(eatPiece);
        } else if (pieceId == 12 || pieceId == 13 || pieceId == 14 || pieceId == 15 || pieceId == 16) {//黑兵
            if (srcPoint.y >= 5) { //过河了
               if ((y == srcPoint.y - 1 && x == srcPoint.x) || (y == srcPoint.y  && distanceX(x, srcPoint.x) == 1)) {
                   if(isBlack(board[x][y])){
                        //不能吃自己的子
                        errMsg = "b you can eat your own piece";
                        return reportFailResultReson(errMsg);
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultBlack(eatPiece);
               } else {
                   errMsg = "b your Pawn not in right move";
                   return reportFailResultReson(errMsg);
               }

            } else { //没过河
               if (y == srcPoint.y - 1 && x == srcPoint.x) {
                   if(isBlack(board[x][y])){
                        //不能吃自己的子
                        errMsg = "b you can eat your own piece";
                        return reportFailResultReson(errMsg);
                    }
                    if (board[x][y] > 0) {
                        eatPiece = board[x][y];
                        //坐标设置为DEAD_PIECE 表示这个子被吃了
                        chessBoard[board[x][y]].x = DEAD_PIECE;
                        chessBoard[board[x][y]].y = DEAD_PIECE;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return reportConfirmResultBlack(eatPiece);
               } else {
                   errMsg = "b your Pawn not in right move";
                   return reportFailResultReson(errMsg);
               }

            }
        }
    }


}