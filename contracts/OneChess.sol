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
    uint8[9][10] private board;


    constructor(address redAddress, address blackAddress) {
        redPlayer = redAddress;
        blackPlayer = blackAddress;
        //设置默认棋子位置
        //黑将
        chessBoard[1] = Point(4，0);
        board[4][0] = 1;
        //黑车
        chessBoard[2] = Point(0，0);
        chessBoard[3] = Point(8，0);
        board[0][0] = 2;
        board[8][0] = 3;
        //黑马
        chessBoard[4] = Point(1，0);
        chessBoard[5] = Point(7，0);
        board[1][0] = 4;
        board[7][0] = 5;
        //黑炮
        chessBoard[6] = Point(1，2);
        chessBoard[7] = Point(7，2);
        board[1][2] = 6;
        board[7][2] = 7;
        //黑士
        chessBoard[8] = Point(3，0);
        chessBoard[9] = Point(5，0);
        board[3][0] = 8;
        board[5][0] = 9;
        //黑象
        chessBoard[10] = Point(2，0);
        chessBoard[11] = Point(6，0);
        board[2][0] = 10;
        board[6][0] = 11;
        //黑卒
        chessBoard[12] = Point(0，3);
        chessBoard[13] = Point(2，3);
        chessBoard[14] = Point(4，3);
        chessBoard[15] = Point(6，3);
        chessBoard[16] = Point(8，3);
        board[0][3] = 12;
        board[2][3] = 13;
        board[4][3] = 14;
        board[6][3] = 15;
        board[8][3] = 16;

        //红兵
        chessBoard[17] = Point(0，6);
        chessBoard[18] = Point(2，6);
        chessBoard[19] = Point(4，6);
        chessBoard[20] = Point(6，6);
        chessBoard[21] = Point(8，6);

        board[0][6] = 17;
        board[2][6] = 18;
        board[4][6] = 19;
        board[6][6] = 20;
        board[8][6] = 21;
        //红车
        chessBoard[22] = Point(0，9);
        chessBoard[23] = Point(8，9);
        board[0][9] = 22;
        board[8][9] = 23;
        //红马
        chessBoard[24] = Point(1，9);
        chessBoard[25] = Point(7，9);
        board[1][9] = 24;
        board[7][9] = 25;
        //红炮
        chessBoard[26] = Point(1，7);
        chessBoard[27] = Point(7，7);
        board[1][7] = 26;
        board[7][7] = 27;
        //红士
        chessBoard[28] = Point(3，9);
        chessBoard[29] = Point(5，9);
        board[3][9] = 28;
        board[5][9] = 29;
        //红相
        chessBoard[30] = Point(2，9);
        chessBoard[31] = Point(6，9);
        board[2][9] = 30;
        board[6][9] = 31;
        //红帅
        chessBoard[32] = Point(4，9);
        board[4][9] = 32;
    }

    /** 改变棋子位置 */
    function chagePiece(uint pieceId, uint x, uint y) returns(bool, bool, string,address) {
        if (pieceId <= 0 || pieceId > 32) {
            return (false, false, "invalid pieceId", address(0));
        }
        if (x < 0 || x > 8 || y < 0 || y > 9) {
            return (false, false, "invalid x or y", address(0));
        }
        Point srcPoint = chessBoard[pieceId];
        if (srcPoint.x == DEAD_PIECE || srcPoint.y == DEAD_PIECE) {
            return (false, false, "piece is dead", address(0));
        }
        if ((srcPoint.x == x && srcPoint.y == y)) {
            return (false, false, "you donot move", address(0));
        }
        return isChangeValid(pieceId, x, y);
    }

    /** 判断这步棋是否合规 */
    function isChangeValid(uint pieceId, uint x, uint y) returns(bool, bool, string,address) {
        if (isRedTurn && pieceId < 17 && tx.origin == redPlayer) {
            return (false, false, "is not red turn", address(0));
        }
        if (!isRedTurn && pieceId > 16 && tx.origin == blackPlayer) {
            return (false, false, "is not black turn", address(0));
        }

        bool chageSuccess;
        bool gameOver;
        string errMsg;
        address winner;

        if (isRedTurn) {
             (chageSuccess, gameOver, errMsg, winner) = handleRedMove(pieceId, x, y);
        } else {
            (chageSuccess, gameOver, errMsg, winner) = handleBlackMove(pieceId, x, y);
        }
        isRedTurn = !isRedTurn;
        return (chageSuccess, gameOver, errMsg, winner);
    }

    function distanceX(uint x1, uint x2) {
        if (x1 > x2) {
            return x1 - x2;
        } else {
            return x2 - x1;
        }
    }

    function distanceY(uint y1, uint y2) {
        if (y1 > y2) {
            return y1 - y2;
        } else {
            return y2 - y1;
        }
    }

    function handleRedMove(uint pieceId, uint x, uint y) returns(bool) {
        Point srcPoint = chessBoard[pieceId];
        uint srcX = srcPoint.x;
        uint srcY = srcPoint.y;
        //红帅
        if (pieceId == 32) {
            if (x >= 3 && x <= 5 && y >= 7 && y <= 9) {
                if ((distanceX(x, scrX) == 0 && distanceY(y, scrY) == 1) || (distanceX(x, scrX) == 1 && distanceY(y, scrY) == 0)) {
                    if（board[x][y] > 16）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
                } else {
                    return false;
                }
                
            } else {
                return false;
            }
        } else if (pieceId == 28 || pieceId == 29) {//红士
            if (x >= 3 && x <= 5 && y >= 7 && y <= 9) {
                if (distanceX(x, scrX) == 1 && distanceY(y, scrY) == 1) {
                    if（board[x][y] > 16）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else if (pieceId == 30 || pieceId == 31) {//红相
            if (y >= 5) {
                if (distanceX(x, scrX) == 2 && distanceY(y, scrY) == 2) {
                    uint midX = (x + scrX) / 2;
                    uint midY = (y + scrY) / 2;
                    if (board[midX][midY] != 0) {
                        //相撇脚，不能这么走
                        return false;
                    }
                    if（board[x][y] > 16）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else if（pieceId == 24 || pieceId == 25）{//红马
            if （(distanceX(x, scrX)==1 && distanceY(y, scrY)==2)）{
                uint mX = scrX;
                uint mY = (y + scrY) / 2;
                if (board[mX][mY] != 0) {//撇马脚
                    return false;
                }
                if（board[x][y] > 16）{
                        //不能吃自己的子
                        return false;
                }
                if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return true;
            } else if ((distanceX(x, scrX)==2 && distanceY(y, scrY)==1)) {
                uint mX = (x + scrX) / 2;
                uint mY = scrY;
                if (board[mX][mY] != 0) {//撇马脚
                    return false;
                }
                if（board[x][y] > 16）{
                    //不能吃自己的子
                    return false;
                }
                if (board[x][y] > 0) {
                    
                    //坐标设置为100，100表示这个子被吃了
                    chessBoard[board[x][y]].x = 100;
                    chessBoard[board[x][y]].y = 100;
                    //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return true;
            } else {
                return false;
            }
        } else if (pieceId == 22 || pieceId == 23) { //红车
            if(x == scrX) {
                if (scrY > y) {
                    for(uint curY = y + 1; curY < scrY; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                } else {
                    for(uint curY = scrY + 1; curY < y; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                }
            } else if (y == scrY) {
                if (scrX > x) {
                    for(uint curX = x + 1; curX < scrX; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                } else {
                    for(uint curX = scrX + 1; curX < x; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                }

            } else {
                return false;
            }

            if（board[x][y] > 16）{
                    //不能吃自己的子
                    return false;
            }
            if (board[x][y] > 0) {
                //坐标设置为100，100表示这个子被吃了
                chessBoard[board[x][y]].x = 100;
                chessBoard[board[x][y]].y = 100;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return true;
        } else if (pieceId == 26 || pieceId == 27) { //红炮
            if（board[x][y] < 17 && board[x][y] > 0）{ //炮的终点有黑子，可以打过去
                uint count = 0;
                if(x == scrX) {
                    if (scrY > y) {
                        for(uint curY = y + 1; curY < scrY; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curY = scrY + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }
                } else if (y == scrY) {
                    if (scrX > x) {
                        for(uint curX = x + 1; curX < scrX; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curX = scrX + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }

                } else {
                    return false;
                }
                if (count != 1) {
                    return false;
                }
            } else if(board[x][y] == 0) { //炮的终点没有子
                if(x == scrX) {
                    if (scrY > y) {
                        for(uint curY = y + 1; curY < scrY; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    } else {
                        for(uint curY = scrY + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    }
                } else if (y == scrY) {
                    if (scrX > x) {
                        for(uint curX = x + 1; curX < scrX; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    } else {
                        for(uint curX = scrX + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    }

                } else {
                    return false;
                }
            }

            if（board[x][y] > 16）{
                    //不能吃自己的子
                    return false;
            }
            if (board[x][y] > 0) {
                //坐标设置为100，100表示这个子被吃了
                chessBoard[board[x][y]].x = 100;
                chessBoard[board[x][y]].y = 100;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return true;
        } else if (pieceId == 17 || pieceId == 18 || pieceId == 19 || pieceId == 20 || pieceId == 21) {//红兵
            if (scrY <= 4) { //过河了
               if ((y == scrY - 1 && x = scrX) || (y == scrY  && distanceX(x, scrX) == 1)) {
                   if（board[x][y] > 16）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
               } else {
                   return false;
               }

            } else { //没过河
               if (y == scrY - 1 && x = scrX) {
                   if（board[x][y] > 16）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
               } else {
                   return false;
               }

            }
        }
    }




    function isBlack(uint pieceId) {
        if（pieceId < 17 && pieceId != 0）{
            return true;
        }
        return false;
    }
    /** 黑子移动规则 */
    function handleBlackMove(uint pieceId, uint x, uint y) returns(bool) {
        Point srcPoint = chessBoard[pieceId];
        uint srcX = srcPoint.x;
        uint srcY = srcPoint.y;
        //黑将
        if (pieceId == 1) {
            if (x >= 3 && x <= 5 && y >= 0 && y <= 2) {
                if ((distanceX(x, scrX) == 0 && distanceY(y, scrY) == 1) || (distanceX(x, scrX) == 1 && distanceY(y, scrY) == 0)) {
                    if（isBlack(board[x][y])）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
                } else {
                    return false;
                }
                
            } else {
                return false;
            }
        } else if (pieceId == 8 || pieceId == 9) {//黑士
            if (x >= 3 && x <= 5 && y >= 0 && y <= 2) {
                if (distanceX(x, scrX) == 1 && distanceY(y, scrY) == 1) {
                    if（isBlack(board[x][y])）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else if (pieceId == 10 || pieceId == 11) {//黑象
            if (y <= 4) {
                if (distanceX(x, scrX) == 2 && distanceY(y, scrY) == 2) {
                    uint midX = (x + scrX) / 2;
                    uint midY = (y + scrY) / 2;
                    if (board[midX][midY] != 0) {
                        //象撇脚，不能这么走
                        return false;
                    }
                    if（isBlack(board[x][y])）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else if（pieceId == 4 || pieceId == 5）{//黑马
            if （(distanceX(x, scrX)==1 && distanceY(y, scrY)==2)）{
                uint mX = scrX;
                uint mY = (y + scrY) / 2;
                if (board[mX][mY] != 0) {//撇马脚
                    return false;
                }
                if（isBlack(board[x][y])）{
                        //不能吃自己的子
                        return false;
                }
                if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return true;
            } else if ((distanceX(x, scrX)==2 && distanceY(y, scrY)==1)) {
                uint mX = (x + scrX) / 2;
                uint mY = scrY;
                if (board[mX][mY] != 0) {//撇马脚
                    return false;
                }
                if（isBlack(board[x][y])）{
                    //不能吃自己的子
                    return false;
                }
                if (board[x][y] > 0) {
                    
                    //坐标设置为100，100表示这个子被吃了
                    chessBoard[board[x][y]].x = 100;
                    chessBoard[board[x][y]].y = 100;
                    //todo emit 吃子
                }
                chessBoard[pieceId].x = x;
                chessBoard[pieceId].y = y;
                board[x][y] = pieceId;
                return true;
            } else {
                return false;
            }
        } else if (pieceId == 2 || pieceId == 3) { //黑车
            if(x == scrX) {
                if (scrY > y) {
                    for(uint curY = y + 1; curY < scrY; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                } else {
                    for(uint curY = scrY + 1; curY < y; curY++) {
                        if (board[x][curY] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                }
            } else if (y == scrY) {
                if (scrX > x) {
                    for(uint curX = x + 1; curX < scrX; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                } else {
                    for(uint curX = scrX + 1; curX < x; curX++) {
                        if (board[curX][y] != 0) {//车走的中途有子挡路
                            return false;
                        }
                    }
                }

            } else {
                return false;
            }

            if（isBlack(board[x][y])）{
                    //不能吃自己的子
                    return false;
            }
            if (board[x][y] > 0) {
                //坐标设置为100，100表示这个子被吃了
                chessBoard[board[x][y]].x = 100;
                chessBoard[board[x][y]].y = 100;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return true;
        } else if (pieceId == 6 || pieceId == 7) { //黑炮
            if（board[x][y] < 17 && board[x][y] > 0）{ //炮的终点有黑子，可以打过去
                uint count = 0;
                if(x == scrX) {
                    if (scrY > y) {
                        for(uint curY = y + 1; curY < scrY; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curY = scrY + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }
                } else if (y == scrY) {
                    if (scrX > x) {
                        for(uint curX = x + 1; curX < scrX; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    } else {
                        for(uint curX = scrX + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                count++;
                            }
                        }
                    }

                } else {
                    return false;
                }
                if (count != 1) {
                    return false;
                }
            } else if(board[x][y] == 0) { //炮的终点没有子
                if(x == scrX) {
                    if (scrY > y) {
                        for(uint curY = y + 1; curY < scrY; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    } else {
                        for(uint curY = scrY + 1; curY < y; curY++) {
                            if (board[x][curY] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    }
                } else if (y == scrY) {
                    if (scrX > x) {
                        for(uint curX = x + 1; curX < scrX; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    } else {
                        for(uint curX = scrX + 1; curX < x; curX++) {
                            if (board[curX][y] != 0) {//炮走的中途有子挡路
                                return false;
                            }
                        }
                    }

                } else {
                    return false;
                }
            }

            if（isBlack(board[x][y])）{
                //不能吃自己的子
                return false;
            }
            if (board[x][y] > 0) {
                //坐标设置为100，100表示这个子被吃了
                chessBoard[board[x][y]].x = 100;
                chessBoard[board[x][y]].y = 100;
                //todo emit 吃子
            }
            chessBoard[pieceId].x = x;
            chessBoard[pieceId].y = y;
            board[x][y] = pieceId;
            return true;
        } else if (pieceId == 12 || pieceId == 13 || pieceId == 14 || pieceId == 15 || pieceId == 16) {//黑兵
            if (scrY >= 5) { //过河了
               if ((y == scrY - 1 && x = scrX) || (y == scrY  && distanceX(x, scrX) == 1)) {
                   if（isBlack(board[x][y])）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
               } else {
                   return false;
               }

            } else { //没过河
               if (y == scrY - 1 && x = scrX) {
                   if（isBlack(board[x][y])）{
                        //不能吃自己的子
                        return false;
                    }
                    if (board[x][y] > 0) {
                        //坐标设置为100，100表示这个子被吃了
                        chessBoard[board[x][y]].x = 100;
                        chessBoard[board[x][y]].y = 100;
                        //todo emit 吃子
                    }
                    chessBoard[pieceId].x = x;
                    chessBoard[pieceId].y = y;
                    board[x][y] = pieceId;
                    return true;
               } else {
                   return false;
               }

            }
        }
    }


}