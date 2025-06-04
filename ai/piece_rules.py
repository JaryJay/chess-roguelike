import json
from typing import Dict, List
from game_types import PieceType
from piece_move_ability import PieceMoveAbility
from piece_rule import PieceRule
from vector import Vector2i

class PieceRules:
    """Manages piece movement rules loaded from JSON configuration"""
    
    # Mapping between string names and PieceType enum
    STRING_TO_TYPE: Dict[str, PieceType] = {
        "king": PieceType.KING,
        "queen": PieceType.QUEEN,
        "rook": PieceType.ROOK,
        "bishop": PieceType.BISHOP,
        "knight": PieceType.KNIGHT,
        "pawn": PieceType.PAWN,
    }
    
    TYPE_TO_STRING: Dict[PieceType, str] = {v: k for k, v in STRING_TO_TYPE.items()}
    
    # Dictionary mapping piece types to their rules
    piece_type_to_rules: Dict[PieceType, PieceRule] = {}
    
    @classmethod
    def load_pieces(cls, pieces_path: str) -> None:
        """Loads and parses piece rules from the JSON file"""
        try:
            with open(pieces_path, 'r') as f:
                pieces_data = json.load(f)
        except Exception as e:
            raise RuntimeError(f"Failed to load pieces from {pieces_path}: {e}")
        
        for piece_type_str, piece_data in pieces_data.items():
            piece_type = cls.STRING_TO_TYPE[piece_type_str]
            
            # Parse credit cost
            credit_cost = piece_data["credit_cost"]
            
            # Parse tags
            tags: List[str] = piece_data.get("tags", [])
            
            # Parse moves
            moves: List[PieceMoveAbility] = []
            if "moves" in piece_data:
                for move_data in piece_data["moves"]:
                    dir_array = move_data["dir"]
                    dist = move_data["dist"] if "dist" in move_data else 0xFFFFFFFF
                    direction = Vector2i(dir_array[0], dir_array[1])
                    moves.append(PieceMoveAbility(direction, dist))
            
            # Create and store rule
            cls.piece_type_to_rules[piece_type] = PieceRule(tags, moves, credit_cost)
    
    @classmethod
    def get_rule(cls, piece_type: PieceType) -> PieceRule:
        """Returns the movement rules for a given piece type"""
        return cls.piece_type_to_rules[piece_type]
