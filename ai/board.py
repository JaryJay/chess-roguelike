from dataclasses import dataclass
from typing import Dict, List, Optional, Set, Tuple
from .piece import Piece, PieceType, PieceFlags
from .move import Move, MoveFlags
from .team import Team
from .vector import Vector2i

@dataclass
class BoardTileMap:
    """Represents the tile layout of the board"""
    tiles: Set[Vector2i]
    promotion_tiles: Dict[Team, Set[Vector2i]]
    
    def has_tile(self, pos: Vector2i) -> bool:
        return pos in self.tiles
    
    def is_promotion_tile(self, pos: Vector2i, team: Team) -> bool:
        return pos in self.promotion_tiles.get(team, set())

@dataclass
class BoardPieceMap:
    """Manages piece positions on the board"""
    pieces: Dict[Vector2i, Piece]
    
    def has_piece(self, pos: Vector2i) -> bool:
        return pos in self.pieces
    
    def get_piece(self, pos: Vector2i) -> Piece:
        assert self.has_piece(pos), f"No piece at {pos}"
        return self.pieces[pos]
    
    def get_king(self, team: Team) -> Piece:
        for piece in self.pieces.values():
            if piece.team == team and piece.type == PieceType.KING:
                return piece
        raise ValueError(f"No king found for team {team}")
    
    def get_all_pieces(self) -> List[Piece]:
        return list(self.pieces.values())
    
    def put_piece(self, pos: Vector2i, piece: Piece) -> None:
        self.pieces[pos] = piece
    
    def remove_piece(self, pos: Vector2i) -> None:
        if pos in self.pieces:
            del self.pieces[pos]
    
    def duplicate(self) -> 'BoardPieceMap':
        return BoardPieceMap({pos: piece.duplicate() for pos, piece in self.pieces.items()})

@dataclass
class Board:
    """Main board class that handles game logic"""
    tile_map: BoardTileMap
    piece_map: BoardPieceMap
    team_to_move: Team
    
    def get_available_moves(self) -> List[Move]:
        """Returns all legal moves for the current player"""
        all_moves: List[Move] = []
        for piece in self.piece_map.get_all_pieces():
            if piece.team != self.team_to_move:
                continue
            all_moves.extend(self.get_available_moves_from(piece.pos))
        return all_moves
    
    def get_available_moves_from(self, from_pos: Vector2i) -> List[Move]:
        """Returns all legal moves for a piece at the given position"""
        assert self.piece_map.has_piece(from_pos), "Must be a piece there"
        piece = self.piece_map.get_piece(from_pos)
        moves = piece.get_available_moves(self)
        moves = self.filter_out_illegal_moves_and_tag_check_moves(moves)
        return moves
    
    def filter_out_illegal_moves_and_tag_check_moves(self, moves: List[Move]) -> List[Move]:
        """Filters out illegal moves and tags check moves"""
        legal_moves: List[Move] = []
        for move in moves:
            next_board = self.perform_move(move, allow_illegal=True)
            if next_board.is_team_in_check(self.team_to_move):
                continue
                
            if next_board.is_team_in_check(next_board.team_to_move):
                move.flags |= MoveFlags.CHECK
                
            legal_moves.append(move)
        return legal_moves
    
    def perform_move(self, move: Move, allow_illegal: bool = False) -> 'Board':
        """Performs a move and returns the resulting board state"""
        current_team_to_move = self.team_to_move
        
        assert self.piece_map.has_piece(move.from_pos), f"No piece at {move.from_pos}"
        piece_to_move = self.piece_map.get_piece(move.from_pos)
        assert piece_to_move.team == current_team_to_move, "Cannot move opponent's piece"
        
        if move.is_capture():
            assert self.piece_map.has_piece(move.to_pos), "Must be a piece to capture"
            captured_piece = self.piece_map.get_piece(move.to_pos)
            assert captured_piece.team.is_hostile_to(current_team_to_move), "Cannot capture friendly pieces"
        else:
            assert not self.piece_map.has_piece(move.to_pos), "Destination must be empty for non-capture moves"
        
        next_board = self.duplicate()
        next_board.team_to_move = Team.PLAYER if current_team_to_move == Team.ENEMY_AI else Team.ENEMY_AI
        
        next_board.piece_map.remove_piece(piece_to_move.pos)
        if move.is_capture():
            next_board.piece_map.remove_piece(move.to_pos)
            
        if move.is_promotion():
            promotion_type = move.get_promotion_type()
            new_piece = Piece(promotion_type, current_team_to_move, move.to_pos)
            next_board.piece_map.put_piece(move.to_pos, new_piece)
        else:
            new_piece = piece_to_move.duplicate()
            new_piece.pos = move.to_pos
            if piece_to_move.type == PieceType.PAWN:
                new_piece.flags |= PieceFlags.MOVED
            next_board.piece_map.put_piece(move.to_pos, new_piece)
        
        if not allow_illegal:
            assert not next_board.is_team_in_check(current_team_to_move), "Move cannot put own team in check"
        
        return next_board
    
    def is_team_in_check(self, team: Team) -> bool:
        """Returns whether the given team's king is in check"""
        team_king = self.piece_map.get_king(team)
        
        for piece in self.piece_map.get_all_pieces():
            if piece.team.is_friendly_to(team_king.team):
                continue
            if piece.is_attacking_square(team_king.pos, self):
                return True
        return False
    
    def is_match_over(self) -> bool:
        """Returns whether the game is over (checkmate or stalemate)"""
        available_moves = self.get_available_moves()
        if not available_moves:
            if self.is_team_in_check(self.team_to_move):
                print("checkmate")
            else:
                print("stalemate")
            return True
        return False
    
    def duplicate(self) -> 'Board':
        """Creates a deep copy of the board"""
        return Board(
            tile_map=self.tile_map,  # TileMap is immutable, so we can share it
            piece_map=self.piece_map.duplicate(),
            team_to_move=self.team_to_move
        )