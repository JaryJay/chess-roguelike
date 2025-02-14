from dataclasses import dataclass
from vector import Vector2i

@dataclass
class PieceMoveAbility:
    """Represents a single movement ability for a piece type"""
    direction: Vector2i
    max_distance: int 