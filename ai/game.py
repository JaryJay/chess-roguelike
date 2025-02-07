from .board import Board, BoardPieceMap
from .team import Team
from .piece_rules import PieceRules
from .generator.tiles_generator import TilesGenerator
from .generator.pieces_generator import PiecesGenerator
from .config import Config

class Game:
    """Main game class that handles initialization and state"""
    
    STARTING_CREDITS = 20  # This could be moved to config.json if needed
    
    @classmethod
    def create_new_game(cls) -> Board:
        """Creates a new game with initial board state"""
        # Load configuration and rules
        Config.load_config()
        PieceRules.load_pieces()
        
        # Create initial board
        board = Board(
            tile_map=TilesGenerator.generate(),
            piece_map=BoardPieceMap(),
            team_to_move=Team.PLAYER
        )
        
        # Generate armies for both teams
        player_army = PiecesGenerator.generate_army(cls.STARTING_CREDITS, board, Team.PLAYER)
        enemy_army = PiecesGenerator.generate_army(cls.STARTING_CREDITS, board, Team.ENEMY_AI)
        
        # Place pieces on the board
        for piece in player_army + enemy_army:
            board.piece_map.put_piece(piece.pos, piece)
        
        return board 