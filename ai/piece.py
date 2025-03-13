from dataclasses import dataclass
from typing import List, Optional
from team import Team
from move import Move
from vector import Vector2i
from piece_rules import PieceRules
from game_types import PieceType, PieceFlags, MoveFlags

@dataclass
class Piece:
    type: PieceType
    team: Team
    pos: Vector2i
    flags: PieceFlags = PieceFlags.NONE
    
    BOARD_LENGTH_UPPER_BOUND: int = 20
    PAWN_SIDES = [Vector2i.LEFT, Vector2i.RIGHT]
    
    def get_available_moves(self, board) -> List[Move]:
        """Returns all available moves for this piece"""
        assert self.type != PieceType.UNSET, "Type must be set"
        assert board.tile_map.has_tile(self.pos), "Must be a tile at current position"
        
        rule = PieceRules.get_rule(self.type)
        moves: List[Move] = []
        
        # Get moves from move abilities
        for move_ability in rule.moves:
            moves.extend(self._get_moves_along_rays([move_ability.direction], board, move_ability.max_distance, True))
        
        # Special moves for kings and pawns
        if "king" in rule.tags:
            moves.extend(self._king_get_additional_moves(board))
        elif "pawn" in rule.tags:
            moves.extend(self._pawn_get_additional_moves(board))
        
        return moves
    
    def is_attacking_square(self, target_pos: Vector2i, board) -> bool:
        """Returns whether this piece is attacking the given square"""
        assert self.type != PieceType.UNSET, "Type must be set"
        assert board.piece_map.has_piece(target_pos), f"Must be a piece at {target_pos}"
        assert board.tile_map.has_tile(target_pos), f"Must be a tile at {target_pos}"
        assert board.tile_map.has_tile(self.pos), f"Must be a tile at {self.pos}"
        assert target_pos != self.pos, f"Cannot attack own square {self.pos}"
        
        rule = PieceRules.get_rule(self.type)
        
        # Special case for pawns
        if "pawn" in rule.tags:
            if self._pawn_is_attacking_square(target_pos, board):
                return True
        
        # Check moves from move abilities
        for move_ability in rule.moves:
            if self._is_attacking_from_ray(target_pos, move_ability.direction, board, move_ability.max_distance):
                return True
        
        return False
    
    def _get_moves_along_rays(self, ray_dirs: List[Vector2i], board, ray_length: int = BOARD_LENGTH_UPPER_BOUND, enable_capture: bool = True) -> List['Move']:
        """Returns all moves along the given ray directions"""
        moves: List[Move] = []
        for direction in ray_dirs:
            next_pos = self.pos
            for _ in range(ray_length):
                next_pos = next_pos + direction
                if not board.tile_map.has_tile(next_pos):
                    break
                
                if board.piece_map.has_piece(next_pos):
                    piece = board.piece_map.get_piece(next_pos)
                    if enable_capture and piece.team.is_hostile_to(self.team):
                        moves.append(Move(self.pos, next_pos, MoveFlags.CAPTURE))
                    break
                
                moves.append(Move(self.pos, next_pos))
        return moves
    
    def _king_get_additional_moves(self, board) -> List['Move']:
        """Returns additional moves specific to kings (e.g. castling)"""
        # TODO: Implement castling
        return []
    
    def _pawn_get_additional_moves(self, board) -> List['Move']:
        """Returns additional moves specific to pawns"""
        moves: List[Move] = []
        facing_dir = self._get_pawn_facing_direction()
        
        # Forward moves
        forward = self.pos + facing_dir
        if board.tile_map.has_tile(forward) and not board.piece_map.has_piece(forward):
            moves.append(Move(self.pos, forward))
            
            # Double move from starting position
            if not bool(self.flags & PieceFlags.MOVED):
                double_forward = forward + facing_dir
                if board.tile_map.has_tile(double_forward) and not board.piece_map.has_piece(double_forward):
                    moves.append(Move(self.pos, double_forward))
        
        # Capture moves
        for side in self.PAWN_SIDES:
            capture_pos = self.pos + side + facing_dir
            if (board.tile_map.has_tile(capture_pos) and 
                board.piece_map.has_piece(capture_pos) and 
                board.piece_map.get_piece(capture_pos).team.is_hostile_to(self.team)):
                moves.append(Move(self.pos, capture_pos, MoveFlags.CAPTURE))
        
        # Handle promotions
        moves_with_promotion: List[Move] = []
        for move in moves:
            if board.tile_map.is_promotion_tile(move.to_pos, self.team):
                for promo_type in [PieceType.QUEEN, PieceType.ROOK, PieceType.BISHOP, PieceType.KNIGHT]:
                    promotion_move = Move(move.from_pos, move.to_pos, move.flags, promo_type)
                    moves_with_promotion.append(promotion_move)
            else:
                moves_with_promotion.append(move)
        
        return moves_with_promotion
    
    def _pawn_is_attacking_square(self, target_pos: Vector2i, board) -> bool:
        """Returns whether this pawn is attacking the given square"""
        facing_dir = self._get_pawn_facing_direction()
        return any(self.pos + facing_dir + side == target_pos for side in self.PAWN_SIDES)
    
    def _is_in_direction(self, target: Vector2i, direction: Vector2i) -> bool:
        delta = target - self.pos
        
        # Handle straight moves
        if direction.x == 0:
            return delta.x == 0 and delta.y * direction.y > 0
        if direction.y == 0:
            return delta.y == 0 and delta.x * direction.x > 0
        
        # Check if points lie on same ray using cross product
        # This is equivalent to delta.x / direction.x == delta.y / direction.y > 0
        # but avoids division which could truncate
        return delta.x * direction.y == delta.y * direction.x

    def _is_attacking_from_ray(self, target_pos: Vector2i, direction: Vector2i, board, ray_length: int = BOARD_LENGTH_UPPER_BOUND) -> bool:
        # Quick check if target is even in this direction
        if not self._is_in_direction(target_pos, direction):
            return False
        
        next_pos = self.pos
        for _ in range(ray_length):
            next_pos = next_pos + direction
            if next_pos == target_pos:
                return True
            if not board.tile_map.has_tile(next_pos) or board.piece_map.has_piece(next_pos):
                return False
        return False
    
    def _get_pawn_facing_direction(self) -> Vector2i:
        """Returns the direction the pawn moves in based on its team"""
        y_modifier = -1 if self.team.is_player() else 1
        return Vector2i(0, y_modifier)
    
    def get_worth(self) -> float:
        """Returns the piece's value for evaluation"""
        assert self.type != PieceType.UNSET, "Type must be set"
        worth_map = {
            PieceType.KING: 1_000_000,
            PieceType.QUEEN: 9,
            PieceType.ROOK: 5,
            PieceType.BISHOP: 3.2,
            PieceType.KNIGHT: 3,
            PieceType.PAWN: 1
        }
        return worth_map[self.type]
    
    def duplicate(self) -> 'Piece':
        """Creates a deep copy of this piece"""
        return Piece(self.type, self.team, self.pos, self.flags)