"""Standalone sanity tests for castling. Run from the ai/ directory:

    python test_castling.py
"""
from board import Board, BoardPieceMap, BoardTileMap
from piece import Piece, PieceFlags
from game_types import PieceType, MoveFlags
from team import Team
from vector import Vector2i
from config import Config
from piece_rules import PieceRules


def _make_board(pieces, team_to_move=Team.PLAYER, tiles=None):
    tile_map = BoardTileMap()
    if tiles is None:
        tiles = [Vector2i(x, y) for x in range(8) for y in range(8)]
    tile_map.set_tiles(tiles)
    piece_map = BoardPieceMap()
    for p in pieces:
        piece_map.put_piece(p.pos, p)
    return Board(tile_map=tile_map, piece_map=piece_map, team_to_move=team_to_move)


def _castle_moves(board, king_pos):
    return [m for m in board.get_available_moves_from(king_pos) if m.is_castle()]


def test_basic_kingside_and_queenside():
    # Player king at (4,7) with rooks at (7,7) and (0,7), enemy king far away
    king = Piece(PieceType.KING, Team.PLAYER, Vector2i(4, 7))
    rook_r = Piece(PieceType.ROOK, Team.PLAYER, Vector2i(7, 7))
    rook_l = Piece(PieceType.ROOK, Team.PLAYER, Vector2i(0, 7))
    enemy_king = Piece(PieceType.KING, Team.ENEMY_AI, Vector2i(4, 0))
    board = _make_board([king, rook_r, rook_l, enemy_king])

    castles = _castle_moves(board, king.pos)
    tos = {(m.to_pos.x, m.to_pos.y): m for m in castles}
    assert (6, 7) in tos, f"expected kingside castle to (6,7), got {list(tos)}"
    assert (2, 7) in tos, f"expected queenside castle to (2,7), got {list(tos)}"

    # Perform kingside castle and check both pieces moved correctly
    move = tos[(6, 7)]
    nb = board.perform_move(move)
    assert nb.piece_map.has_piece(Vector2i(6, 7)) and nb.piece_map.get_piece(Vector2i(6, 7)).type == PieceType.KING
    assert nb.piece_map.has_piece(Vector2i(5, 7)) and nb.piece_map.get_piece(Vector2i(5, 7)).type == PieceType.ROOK
    assert not nb.piece_map.has_piece(Vector2i(4, 7))
    assert not nb.piece_map.has_piece(Vector2i(7, 7))
    # Rights revoked
    assert bool(nb.piece_map.get_piece(Vector2i(6, 7)).flags & PieceFlags.MOVED)
    print("test_basic_kingside_and_queenside passed")


def test_no_castle_if_king_moved():
    king = Piece(PieceType.KING, Team.PLAYER, Vector2i(4, 7), PieceFlags.MOVED)
    rook = Piece(PieceType.ROOK, Team.PLAYER, Vector2i(7, 7))
    enemy_king = Piece(PieceType.KING, Team.ENEMY_AI, Vector2i(4, 0))
    board = _make_board([king, rook, enemy_king])
    assert not _castle_moves(board, king.pos), "king that moved should not castle"
    print("test_no_castle_if_king_moved passed")


def test_no_castle_if_rook_moved():
    king = Piece(PieceType.KING, Team.PLAYER, Vector2i(4, 7))
    rook = Piece(PieceType.ROOK, Team.PLAYER, Vector2i(7, 7), PieceFlags.MOVED)
    enemy_king = Piece(PieceType.KING, Team.ENEMY_AI, Vector2i(4, 0))
    board = _make_board([king, rook, enemy_king])
    assert not _castle_moves(board, king.pos), "moved rook should not allow castle"
    print("test_no_castle_if_rook_moved passed")


def test_no_castle_through_blocked_squares():
    king = Piece(PieceType.KING, Team.PLAYER, Vector2i(4, 7))
    rook = Piece(PieceType.ROOK, Team.PLAYER, Vector2i(7, 7))
    blocker = Piece(PieceType.BISHOP, Team.PLAYER, Vector2i(5, 7))
    enemy_king = Piece(PieceType.KING, Team.ENEMY_AI, Vector2i(4, 0))
    board = _make_board([king, rook, blocker, enemy_king])
    assert not _castle_moves(board, king.pos), "blocked path should not allow castle"
    print("test_no_castle_through_blocked_squares passed")


def test_no_castle_through_attacked_square():
    # Enemy rook attacks (5,7), the square the king passes through
    king = Piece(PieceType.KING, Team.PLAYER, Vector2i(4, 7))
    rook = Piece(PieceType.ROOK, Team.PLAYER, Vector2i(7, 7))
    enemy_rook = Piece(PieceType.ROOK, Team.ENEMY_AI, Vector2i(5, 0))
    enemy_king = Piece(PieceType.KING, Team.ENEMY_AI, Vector2i(0, 0))
    board = _make_board([king, rook, enemy_rook, enemy_king])
    castles = _castle_moves(board, king.pos)
    assert all(m.to_pos != Vector2i(6, 7) for m in castles), "cannot castle through attacked square"
    print("test_no_castle_through_attacked_square passed")


def test_no_castle_while_in_check():
    king = Piece(PieceType.KING, Team.PLAYER, Vector2i(4, 7))
    rook = Piece(PieceType.ROOK, Team.PLAYER, Vector2i(7, 7))
    enemy_rook = Piece(PieceType.ROOK, Team.ENEMY_AI, Vector2i(4, 0))  # checks king on file 4
    enemy_king = Piece(PieceType.KING, Team.ENEMY_AI, Vector2i(0, 0))
    board = _make_board([king, rook, enemy_rook, enemy_king])
    assert not _castle_moves(board, king.pos), "cannot castle out of check"
    print("test_no_castle_while_in_check passed")


if __name__ == "__main__":
    Config.load_config("../config.json")
    PieceRules.load_pieces("../pieces.json")
    test_basic_kingside_and_queenside()
    test_no_castle_if_king_moved()
    test_no_castle_if_rook_moved()
    test_no_castle_through_blocked_squares()
    test_no_castle_through_attacked_square()
    test_no_castle_while_in_check()
    print("\nAll castling tests passed!")
