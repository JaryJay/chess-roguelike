from board import Board, BoardPieceMap, BoardTileMap
from team import Team
from generator.tiles_generator import TilesGenerator
from generator.pieces_generator import PiecesGenerator

class Game:
    """Main game class that handles initialization and state"""
    
    STARTING_CREDITS = 1000
    
    @classmethod
    def create_new_game(cls) -> Board:
        """Creates a new game with initial board state"""
        # Create initial board
        tile_map = BoardTileMap()
        tile_map.set_tiles(TilesGenerator.generate_tiles())
        board = Board(
            tile_map=tile_map,
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