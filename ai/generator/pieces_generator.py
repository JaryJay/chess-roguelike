import json
from typing import Dict
from ..vector import Vector2i
from ..team import Team
from ..piece import Piece, PieceType
from ..board import BoardPieceMap
from ..piece_rules import PieceRules

class PiecesGenerator:
    """Generates the initial piece positions from configuration"""
    
    PATH_TO_INITIAL_PIECES = "initial_pieces.json"
    
    @classmethod
    def generate(cls) -> BoardPieceMap:
        """Generates a BoardPieceMap with the initial piece positions"""
        try:
            with open(cls.PATH_TO_INITIAL_PIECES, 'r') as f:
                pieces_data = json.load(f)
        except Exception as e:
            raise RuntimeError(f"Failed to load initial_pieces.json: {e}")
        
        pieces: Dict[Vector2i, Piece] = {}
        
        # Parse player pieces
        if "player" in pieces_data:
            for piece_data in pieces_data["player"]:
                pos = Vector2i(piece_data["pos"][0], piece_data["pos"][1])
                piece_type = PieceRules.STRING_TO_TYPE[piece_data["type"]]
                pieces[pos] = Piece(piece_type, Team.PLAYER, pos)
        
        # Parse enemy pieces
        if "enemy" in pieces_data:
            for piece_data in pieces_data["enemy"]:
                pos = Vector2i(piece_data["pos"][0], piece_data["pos"][1])
                piece_type = PieceRules.STRING_TO_TYPE[piece_data["type"]]
                pieces[pos] = Piece(piece_type, Team.ENEMY_AI, pos)
        
        return BoardPieceMap(pieces) 