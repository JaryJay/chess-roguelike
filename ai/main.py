import argparse
import time
import random
from board import Board
from game import Game
from piece import PieceType
from team import Team
from vector import Vector2i
from config import Config
from piece_rules import PieceRules

def print_board(board: Board) -> None:
    """Prints a simple ASCII representation of the board"""
    for y in range(Config.max_board_size):
        for x in range(Config.max_board_size):
            pos = Vector2i(x, y)
            if not board.tile_map.has_tile(pos):
                print(" ", end=" ")
            elif board.piece_map.has_piece(pos):
                piece = board.piece_map.get_piece(pos)
                # Simple ASCII representation of pieces
                symbols = {
                    PieceType.KING: "K",
                    PieceType.QUEEN: "Q",
                    PieceType.ROOK: "R",
                    PieceType.BISHOP: "B",
                    PieceType.KNIGHT: "N",
                    PieceType.PAWN: "P"
                }
                symbol = symbols[piece.type]
                # Lowercase for enemy pieces
                if piece.team == Team.ENEMY_AI:
                    symbol = symbol.lower()
                print(symbol, end=" ")
            else:
                print(".", end=" ")
        print()  # New line after each row
    print()  # Empty line after board

def parse_args():
    parser = argparse.ArgumentParser(description='Chess Roguelike AI')
    parser.add_argument('--config-path', help='Path to the config.json file', default="../config.json")
    parser.add_argument('--pieces-path', help='Path to the pieces.json file', default="../pieces.json") 
    return parser.parse_args()

def main():
    args = parse_args()
    
    # Initialize game with config paths
    print("Creating new game...")
    Config.load_config(args.config_path)
    PieceRules.load_pieces(args.pieces_path)
    board = Game.create_new_game()
    
    # Print initial board state
    print("\nInitial board state:")
    print_board(board)
    
    # Game loop
    move_count = 1
    while not board.is_match_over():
        time.sleep(1)

        print(f"\nMove {move_count}:")
        # Get and display available moves for current player
        moves = board.get_available_moves()
        print(f"\nAvailable moves for {board.team_to_move}:")
        for move in moves:
            piece = board.piece_map.get_piece(move.from_pos)
            move_type = "captures" if move.is_capture() else "moves to"
            check = " (check)" if move.is_check() else ""
            promotion = f" promoting to {move.promotion_type.name}" if move.is_promotion() else ""
            print(f"{piece.type.name} at {move.from_pos} {move_type} {move.to_pos}{check}{promotion}")
        
        if not moves:
            print("No moves available!")
            break
            
        # Perform a random move
        move = random.choice(moves)
        print(f"\nPerforming move: {move.from_pos} -> {move.to_pos}")
        board = board.perform_move(move)
        print("\nBoard after move:")
        print_board(board)
        
        move_count += 1
    
    # Game over
    print("\nGame is over!")
    print(f"Total moves played: {move_count - 1}")
    if board.is_team_in_check(board.team_to_move):
        winner = "Player" if board.team_to_move == Team.ENEMY_AI else "AI"
        print(f"{winner} wins by checkmate!")
    else:
        print("Game ends in stalemate!")

if __name__ == "__main__":
    main() 