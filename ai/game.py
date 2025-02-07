from .board import Board
from .team import Team
from .piece_rules import PieceRules
from .generator.tiles_generator import TilesGenerator
from .generator.pieces_generator import PiecesGenerator

class Game:
    """Main game class that handles initialization and state"""
    
    @classmethod
    def create_new_game(cls) -> Board:
        """Creates a new game with initial board state"""
        # Load piece rules
        PieceRules.load_pieces()
        
        # Generate board layout and pieces
        tile_map = TilesGenerator.generate()
        piece_map = PiecesGenerator.generate()
        
        # Create initial board state
        return Board(tile_map, piece_map, Team.PLAYER) 