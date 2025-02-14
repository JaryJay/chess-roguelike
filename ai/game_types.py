from enum import Flag, auto

class PieceType(Flag):
    UNSET = 0
    KING = auto()
    QUEEN = auto()
    ROOK = auto()
    BISHOP = auto()
    KNIGHT = auto()
    PAWN = auto()

class MoveFlags(Flag):
    NONE = 0
    CHECK = auto()
    CAPTURE = auto()
    CASTLE_LEFT = auto()
    CASTLE_RIGHT = auto()

class PieceFlags(Flag):
    NONE = 0
    MOVED = auto() 