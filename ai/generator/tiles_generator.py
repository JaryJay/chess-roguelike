import json
from typing import Dict, Set
from ..vector import Vector2i
from ..team import Team
from ..board import BoardTileMap

class TilesGenerator:
    """Generates the board tile layout from configuration"""
    
    PATH_TO_TILES = "tiles.json"
    
    @classmethod
    def generate(cls) -> BoardTileMap:
        """Generates a BoardTileMap from the tiles configuration"""
        try:
            with open(cls.PATH_TO_TILES, 'r') as f:
                tiles_data = json.load(f)
        except Exception as e:
            raise RuntimeError(f"Failed to load tiles.json: {e}")
        
        # Parse regular tiles
        tiles: Set[Vector2i] = set()
        for tile_pos in tiles_data["tiles"]:
            tiles.add(Vector2i(tile_pos[0], tile_pos[1]))
        
        # Parse promotion tiles
        promotion_tiles: Dict[Team, Set[Vector2i]] = {
            Team.PLAYER: set(),
            Team.ENEMY_AI: set()
        }
        
        if "promotion_tiles" in tiles_data:
            promo_data = tiles_data["promotion_tiles"]
            if "player" in promo_data:
                for pos in promo_data["player"]:
                    promotion_tiles[Team.PLAYER].add(Vector2i(pos[0], pos[1]))
            if "enemy" in promo_data:
                for pos in promo_data["enemy"]:
                    promotion_tiles[Team.ENEMY_AI].add(Vector2i(pos[0], pos[1]))
        
        return BoardTileMap(tiles, promotion_tiles) 