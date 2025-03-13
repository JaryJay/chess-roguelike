from dataclasses import dataclass
from typing import List
from piece_move_ability import PieceMoveAbility

@dataclass
class PieceRule:
    """Defines the movement rules and properties for a piece type"""
    tags: List[str]
    moves: List[PieceMoveAbility]
    credit_cost: int