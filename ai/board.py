from dataclasses import dataclass
from typing import Dict, List, Optional
from piece import Piece, PieceType, PieceFlags
from move import Move, MoveFlags
from team import Team
from vector import Vector2i
from config import Config

@dataclass
class BoardTileMap:
    """Represents the tile layout of the board"""
    _tiles: List[List[bool]] = None
    _cached_tile_count: int = 0
    
    def __post_init__(self):
        if self._tiles is None:
            self._tiles = [[False for _ in range(Config.max_board_size)] 
                         for _ in range(Config.max_board_size)]
    
    def get_all_tiles(self) -> List[Vector2i]:
        all_tiles: List[Vector2i] = []
        for y in range(len(self._tiles)):
            for x in range(len(self._tiles[y])):
                pos = Vector2i(x, y)
                if self.has_tile(pos):
                    all_tiles.append(pos)
        return all_tiles
    
    def set_tiles(self, tile_positions: List[Vector2i]) -> None:
        self._tiles = [[False for _ in range(Config.max_board_size)] 
                      for _ in range(Config.max_board_size)]
        self._cached_tile_count = 0
        
        for pos in tile_positions:
            self._tiles[pos.y][pos.x] = True
            self._cached_tile_count += 1
        assert self.num_tiles() == len(tile_positions)
    
    def is_promotion_tile(self, pos: Vector2i, team: Team) -> bool:
        y_modifier = -1 if team.is_player() else 1
        pawn_facing_dir = Vector2i(0, y_modifier)
        return not self.has_tile(pos + pawn_facing_dir)
    
    def has_tile(self, pos: Vector2i) -> bool:
        if (pos.x < 0 or pos.x >= Config.max_board_size or 
            pos.y < 0 or pos.y >= Config.max_board_size):
            return False
        return self._tiles[pos.y][pos.x]
    
    def num_tiles(self) -> int:
        return self._cached_tile_count

@dataclass
class BoardPieceMap:
    """Manages piece positions on the board"""
    _pieces: List[List[Optional[Piece]]] = None
    _cached_king_positions: Dict[Team, Piece] = None
    
    def __post_init__(self):
        if self._pieces is None:
            self._pieces = []
            self._pieces = [[None for _ in range(Config.max_board_size)] 
                          for _ in range(Config.max_board_size)]
        if self._cached_king_positions is None:
            self._cached_king_positions = {}
    
    def has_piece(self, pos: Vector2i) -> bool:
        return self._pieces[pos.y][pos.x] is not None
    
    def get_piece(self, pos: Vector2i) -> Piece:
        assert self.has_piece(pos), f"No piece at {pos}"
        return self._pieces[pos.y][pos.x]
    
    def get_king(self, team: Team) -> Piece:
        # TODO: Implement caching like in GDScript
        for y in range(len(self._pieces)):
            for x in range(len(self._pieces[y])):
                pos = Vector2i(x, y)
                if not self.has_piece(pos):
                    continue
                piece = self.get_piece(pos)
                if piece.type == PieceType.KING and piece.team == team:
                    self._cached_king_positions[team] = piece
                    return piece
        raise ValueError(f"No king found for team {team}")
    
    def get_all_pieces(self) -> List[Piece]:
        all_pieces: List[Piece] = []
        for y in range(len(self._pieces)):
            for x in range(len(self._pieces[y])):
                pos = Vector2i(x, y)
                if self.has_piece(pos):
                    all_pieces.append(self.get_piece(pos))
        return all_pieces
    
    def put_piece(self, pos: Vector2i, piece: Piece) -> None:
        assert not self.has_piece(pos), f"Piece already at {pos}"
        self._pieces[pos.y][pos.x] = piece
    
    def remove_piece(self, pos: Vector2i) -> None:
        assert self.has_piece(pos), f"No piece at {pos}"
        self._pieces[pos.y][pos.x] = None
    
    def duplicate(self) -> 'BoardPieceMap':
        new_piece_map = BoardPieceMap()
        for y in range(len(self._pieces)):
            for x in range(len(self._pieces[y])):
                new_piece_map._pieces[y][x] = self._pieces[y][x]
        for key in self._cached_king_positions:
            new_piece_map._cached_king_positions[key] = self._cached_king_positions[key]
        return new_piece_map

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