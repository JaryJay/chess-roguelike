import json
from typing import Dict, List, Set
from ..vector import Vector2i
from ..team import Team
from ..board import BoardTileMap
from ..config import Config

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
    
    @classmethod
    def generate_raw_positions(cls) -> List[Vector2i]:
        """Generates initial tile positions using noise"""
        import random
        import math
        
        raw_positions: List[Vector2i] = []
        
        # Simple random noise implementation
        for y in range(Config.max_board_size):
            for x in range(Config.max_board_size):
                # Generate noise value between 0 and 1
                val = random.random()
                
                # Adjust based on distance from center
                center = Config.max_board_size / 2
                dist = math.sqrt((x - center)**2 + (y - center)**2)
                normalized_dist = dist / (Config.max_board_size * math.sqrt(2) / 2)
                val = val * (1 - normalized_dist)
                
                # Scale noise
                val = val * Config.tile_generation_noise_scale
                
                if abs(val) > Config.tile_generation_threshold:
                    raw_positions.append(Vector2i(x, y))
        
        return raw_positions 