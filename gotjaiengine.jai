// GotJaiEngine. Gothic chess engine in Jai
// Copyright (C) 2025 Toni Helminen
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#import "Basic";
#import "Math";
#import "Random";
#import "String";

Piece_Type :: enum u8 {
    EMPTY = 0,
    PAWN,
    KNIGHT,
    BISHOP,
    ROOK,
    QUEEN,
    MARSHALL,  // Rook + Knight
    CARDINAL,  // Bishop + Knight
    KING,
}

Piece_Color :: enum u8 {
    NONE = 0,
    WHITE,
    BLACK,
}

Piece :: struct {
    type: Piece_Type;
    color: Piece_Color;
}

Board :: [10][8] Piece;  // Gothic chess uses 10x8 board

Move :: struct {
    from_x, from_y: int;
    to_x, to_y: int;
}

init_board :: (board: *Board) {
    // Initialize empty board
    for y: 0..7 for x: 0..9 {
        board[y][x] = Piece.{.EMPTY, .NONE};
    }

    // Set up pawns
    for x: 0..9 {
        board[1][x] = Piece.{.PAWN, .WHITE};
        board[6][x] = Piece.{.PAWN, .BLACK};
    }

    // Set up white pieces
    board[0][0] = Piece.{.ROOK, .WHITE};
    board[0][1] = Piece.{.KNIGHT, .WHITE};
    board[0][2] = Piece.{.BISHOP, .WHITE};
    board[0][3] = Piece.{.QUEEN, .WHITE};
    board[0][4] = Piece.{.KING, .WHITE};
    board[0][5] = Piece.{.CARDINAL, .WHITE};
    board[0][6] = Piece.{.BISHOP, .WHITE};
    board[0][7] = Piece.{.KNIGHT, .WHITE};
    board[0][8] = Piece.{.ROOK, .WHITE};
    board[0][9] = Piece.{.MARSHALL, .WHITE};

    // Set up black pieces
    board[7][0] = Piece.{.ROOK, .BLACK};
    board[7][1] = Piece.{.KNIGHT, .BLACK};
    board[7][2] = Piece.{.BISHOP, .BLACK};
    board[7][3] = Piece.{.QUEEN, .BLACK};
    board[7][4] = Piece.{.KING, .BLACK};
    board[7][5] = Piece.{.CARDINAL, .BLACK};
    board[7][6] = Piece.{.BISHOP, .BLACK};
    board[7][7] = Piece.{.KNIGHT, .BLACK};
    board[7][8] = Piece.{.ROOK, .BLACK};
    board[7][9] = Piece.{.MARSHALL, .BLACK};
}

print_board :: (board: *Board) {
    print("\n   a b c d e f g h i j");
    for y: 7..0 {
        print("\n{} ", y+1);
        for x: 0..9 {
            p := board[y][x];
            c := ".";
            if p.color == .WHITE {
                c = switch p.type {
                    case .PAWN;     "P";
                    case .KNIGHT;   "N";
                    case .BISHOP;   "B";
                    case .ROOK;     "R";
                    case .QUEEN;    "Q";
                    case .MARSHALL; "M";
                    case .CARDINAL; "C";
                    case .KING;     "K";
                    case;           "?";
                }
            } else if p.color == .BLACK {
                c = switch p.type {
                    case .PAWN;     "p";
                    case .KNIGHT;   "n";
                    case .BISHOP;   "b";
                    case .ROOK;     "r";
                    case .QUEEN;    "q";
                    case .MARSHALL; "m";
                    case .CARDINAL; "c";
                    case .KING;     "k";
                    case;           "?";
                }
            }
            print("{} ", c);
        }
    }
    print("\n");
}

is_valid_position :: (x, y: int) -> bool {
    return x >= 0 && x < 10 && y >= 0 && y < 8;
}

generate_piece_moves :: (board: *Board, x, y: int, moves: *[..]Move) {
    piece := board[y][x];
    if piece.color == .NONE return;

    // Directions for different pieces
    rook_dirs := [?][2]int {{1,0}, {-1,0}, {0,1}, {0,-1}};
    bishop_dirs := [?][2]int {{1,1}, {1,-1}, {-1,1}, {-1,-1}};
    knight_moves := [?][2]int {
        {2,1}, {2,-1}, {-2,1}, {-2,-1}, {1,2}, {1,-2}, {-1,2}, {-1,-2}
    };

    switch piece.type {
        case .PAWN: {
            // Pawn moves (simplified - no en passant or double move)
            forward := piece.color == .WHITE ? 1 : -1;
            if is_valid_position(x, y+forward) {
                target := board[y+forward][x];
                if target.type == .EMPTY {
                    array_add(moves, Move.{x, y, x, y+forward});
                }
            }
            // Captures
            for dx: -1..1 step 2 {
                if is_valid_position(x+dx, y+forward) {
                    target := board[y+forward][x+dx];
                    if target.color != .NONE && target.color != piece.color {
                        array_add(moves, Move.{x, y, x+dx, y+forward});
                    }
                }
            }
        }

        case .KNIGHT: {
            for move in knight_moves {
                nx := x + move[0];
                ny := y + move[1];
                if !is_valid_position(nx, ny) continue;
                target := board[ny][nx];
                if target.color != piece.color {
                    array_add(moves, Move.{x, y, nx, ny});
                }
            }
        }

        case .BISHOP: {
            for dir in bishop_dirs {
                nx, ny := x, y;
                while true {
                    nx += dir[0];
                    ny += dir[1];
                    if !is_valid_position(nx, ny) break;
                    target := board[ny][nx];
                    if target.color == piece.color break;
                    array_add(moves, Move.{x, y, nx, ny});
                    if target.color != .NONE break;
                }
            }
        }

        case .ROOK: {
            for dir in rook_dirs {
                nx, ny := x, y;
                while true {
                    nx += dir[0];
                    ny += dir[1];
                    if !is_valid_position(nx, ny) break;
                    target := board[ny][nx];
                    if target.color == piece.color break;
                    array_add(moves, Move.{x, y, nx, ny});
                    if target.color != .NONE break;
                }
            }
        }

        case .QUEEN: {
            // Queen = Rook + Bishop
            for dir in rook_dirs {
                nx, ny := x, y;
                while true {
                    nx += dir[0];
                    ny += dir[1];
                    if !is_valid_position(nx, ny) break;
                    target := board[ny][nx];
                    if target.color == piece.color break;
                    array_add(moves, Move.{x, y, nx, ny});
                    if target.color != .NONE break;
                }
            }
            for dir in bishop_dirs {
                nx, ny := x, y;
                while true {
                    nx += dir[0];
                    ny += dir[1];
                    if !is_valid_position(nx, ny) break;
                    target := board[ny][nx];
                    if target.color == piece.color break;
                    array_add(moves, Move.{x, y, nx, ny});
                    if target.color != .NONE break;
                }
            }
        }

        case .MARSHALL: {
            // Marshall = Rook + Knight
            for dir in rook_dirs {
                nx, ny := x, y;
                while true {
                    nx += dir[0];
                    ny += dir[1];
                    if !is_valid_position(nx, ny) break;
                    target := board[ny][nx];
                    if target.color == piece.color break;
                    array_add(moves, Move.{x, y, nx, ny});
                    if target.color != .NONE break;
                }
            }
            for move in knight_moves {
                nx := x + move[0];
                ny := y + move[1];
                if !is_valid_position(nx, ny) continue;
                target := board[ny][nx];
                if target.color != piece.color {
                    array_add(moves, Move.{x, y, nx, ny});
                }
            }
        }

        case .CARDINAL: {
            // Cardinal = Bishop + Knight
            for dir in bishop_dirs {
                nx, ny := x, y;
                while true {
                    nx += dir[0];
                    ny += dir[1];
                    if !is_valid_position(nx, ny) break;
                    target := board[ny][nx];
                    if target.color == piece.color break;
                    array_add(moves, Move.{x, y, nx, ny});
                    if target.color != .NONE break;
                }
            }
            for move in knight_moves {
                nx := x + move[0];
                ny := y + move[1];
                if !is_valid_position(nx, ny) continue;
                target := board[ny][nx];
                if target.color != piece.color {
                    array_add(moves, Move.{x, y, nx, ny});
                }
            }
        }

        case .KING: {
            // King moves (1 square in any direction)
            for dy: -1..1 for dx: -1..1 {
                if dx == 0 && dy == 0 continue;
                nx := x + dx;
                ny := y + dy;
                if !is_valid_position(nx, ny) continue;
                target := board[ny][nx];
                if target.color != piece.color {
                    array_add(moves, Move.{x, y, nx, ny});
                }
            }
        }
    }
}

generate_all_moves :: (board: *Board, color: Piece_Color, moves: *[..]Move) {
    for y: 0..7 for x: 0..9 {
        if board[y][x].color == color {
            generate_piece_moves(board, x, y, moves);
        }
    }
}

make_move :: (board: *Board, move: Move) -> bool {
    piece := board[move.from_y][move.from_x];
    target := board[move.to_y][move.to_x];

    // Check if move is valid (simplified - in real engine would need proper validation)
    if piece.color == .NONE || target.color == piece.color {
        return false;
    }

    // Move the piece
    board[move.to_y][move.to_x] = piece;
    board[move.from_y][move.from_x] = Piece.{.EMPTY, .NONE};

    return true;
}

is_game_over :: (board: *Board) -> bool {
    // Check if kings still exist
    white_king := false;
    black_king := false;
    for y: 0..7 for x: 0..9 {
        if board[y][x].type == .KING {
            if board[y][x].color == .WHITE white_king = true;
            if board[y][x].color == .BLACK black_king = true;
        }
    }
    return !white_king || !black_king;
}

main :: () {
    board: Board;
    init_board(*board);
    rng := create_random(/*seed*/ 42);

    current_color := Piece_Color.WHITE;
    print("Gothic Chess Engine - Random Mover\n");

    while !is_game_over(*board) {
        print_board(*board);

        moves: [..]Move;
        generate_all_moves(*board, current_color, *moves);

        if moves.count == 0 {
            print("No moves available for %\n", current_color == .WHITE ? "White" : "Black");
            break;
        }

        // Select random move
        move := moves[random_next(&rng) % moves.count];
        print("% moves %c%d to %c%d\n",
              current_color == .WHITE ? "White" : "Black",
              'a' + move.from_x, move.from_y + 1,
              'a' + move.to_x, move.to_y + 1);

        if !make_move(*board, move) {
            print("Illegal move\n");
            continue;
        }

        current_color = current_color == .WHITE ? .BLACK : .WHITE;
    }

    print("Game over!\n");
    print_board(*board);
}
