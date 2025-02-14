from dataclasses import dataclass
from typing import Optional
from vector import Vector2i
from game_types import MoveFlags, PieceType

@dataclass
class Move:
    from_pos: Vector2i
    to_pos: Vector2i
    flags: MoveFlags = MoveFlags.NONE
    promotion_type: Optional[PieceType] = None
    
    def is_check(self) -> bool:
        return bool(self.flags & MoveFlags.CHECK)
    
    def is_capture(self) -> bool:
        return bool(self.flags & MoveFlags.CAPTURE)
    
    def is_castle(self) -> bool:
        castle_flags = MoveFlags.CASTLE_LEFT | MoveFlags.CASTLE_RIGHT
        assert not (bool(self.flags & MoveFlags.CASTLE_LEFT) and bool(self.flags & MoveFlags.CASTLE_RIGHT)), \
            "Cannot castle in two directions at once"
        return bool(self.flags & castle_flags)
    
    def is_promotion(self) -> bool:
        return self.promotion_type is not None
    
    def get_promotion_type(self) -> PieceType:
        assert self.is_promotion(), "Must be a promotion move"
        return self.promotion_type