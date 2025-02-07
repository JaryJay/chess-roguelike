import json
import random
from typing import Dict, List
from ..vector import Vector2i
from ..team import Team
from ..piece import Piece, PieceType
from ..board import Board, BoardPieceMap
from ..piece_rules import PieceRules

class PiecesGenerator:
    """Generates armies of pieces based on a credit system"""
    
    # Only the types that can be generated (king is not included)
    PIECE_TYPES = [
        PieceType.QUEEN,
        PieceType.ROOK,
        PieceType.BISHOP,
        PieceType.KNIGHT,
        PieceType.PAWN,
    ]
    
    @classmethod
    def generate_army(cls, credits: int, board: Board, team: Team) -> List[Piece]:
        """Generates an army of pieces for the given team with the given credits"""
        army: List[Piece] = []
        
        # Always start with a king at placeholder position
        army.append(Piece(PieceType.KING, team, Vector2i(0, 0)))
        
        # Generate pieces while we have credits
        while credits > 0:
            piece_type = cls.generate_piece_type(credits)
            if piece_type == PieceType.UNSET:
                break
            
            credits -= PieceRules.get_rule(piece_type).credit_cost
            army.append(Piece(piece_type, team, Vector2i(0, 0)))
        
        # Arrange pieces on the board
        army_size = len(army)
        tiles = board.tile_map.get_all_tiles()
        assert len(tiles) >= army_size, "Board does not have enough tiles"
        
        # Shuffle and sort tiles by y-coordinate
        random.shuffle(tiles)
        tiles.sort(key=lambda pos: pos.y)
        
        # Get first/last x tiles based on team
        if team == Team.ENEMY_AI:
            selected_tiles = tiles[:army_size]  # First x tiles for enemy
        else:
            selected_tiles = tiles[-army_size:]  # Last x tiles for player
        
        # Assign positions to pieces
        for i in range(army_size):
            army[i].pos = selected_tiles[i]
        
        return army
    
    @classmethod
    def generate_piece_type(cls, credits: int) -> PieceType:
        """Generates a random piece type that can be afforded with the given credits"""
        if credits < PieceRules.get_rule(PieceType.PAWN).credit_cost:
            return PieceType.UNSET
        
        affordable_types: List[PieceType] = []
        for piece_type in cls.PIECE_TYPES:
            rule = PieceRules.get_rule(piece_type)
            assert rule is not None
            assert rule.credit_cost > 0
            if rule.credit_cost <= credits:
                affordable_types.append(piece_type)
        
        assert len(affordable_types) >= 1
        return random.choice(affordable_types) 