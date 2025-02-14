import random
import math
from typing import List
from pyfastnoiselite.pyfastnoiselite import FastNoiseLite
from vector import Vector2i
from config import Config

class TilesGenerator:
    """Generates the board tile layout procedurally"""
    
    PRUNE_TILES = True
    CARDINAL_DIRECTIONS = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
    
    @classmethod
    def generate_tiles(cls) -> List[Vector2i]:
        """Main entry point for tile generation"""
        raw_positions = cls.generate_raw_positions()
        pruned_positions = cls.prune_positions(raw_positions)
        return cls.normalize_positions(pruned_positions)
    
    @classmethod
    def generate_raw_positions(cls) -> List[Vector2i]:
        """Generates initial tile positions using noise"""
        raw_positions: List[Vector2i] = []
        
        noise = FastNoiseLite()
        noise.seed = random.randint(0, 2**31-1)  # matches Godot's randi()
        # Note: FastNoiseLite in Python doesn't have offset property, so we add it in get_noise_2d
        
        for y in range(Config.max_board_size):
            for x in range(Config.max_board_size):
                # Get noise value in range [-1, 1]
                val = noise.get_noise(x * Config.tile_generation_noise_scale + 0.5, y * Config.tile_generation_noise_scale + 0.5)  # Adding offset to match Godot
                # Convert to range [0, 1]
                val = (val + 1) / 2
                
                # Adjust based on distance from center using float math first
                center = float(Config.max_board_size) / 2
                dist = math.sqrt((x - center)**2 + (y - center)**2)
                normalized_dist = dist / (Config.max_board_size * math.sqrt(2) / 2)
                val = val * (1 - normalized_dist)
                
                if abs(val) > Config.tile_generation_threshold:
                    raw_positions.append(Vector2i(x, y))
        
        return raw_positions
    
    @classmethod
    def prune_positions(cls, positions: List[Vector2i]) -> List[Vector2i]:
        """Prunes positions that are not cardinally adjacent to another tile"""
        if not cls.PRUNE_TILES:
            return positions
            
        # Convert to set for O(1) lookup
        positions_set = set(positions)
        pruned_positions: List[Vector2i] = []
        
        for tile_pos in positions:
            good_tile = False
            for cardinal_dir in cls.CARDINAL_DIRECTIONS:
                if tile_pos + cardinal_dir in positions_set:
                    good_tile = True
                    break
            if good_tile:
                pruned_positions.append(tile_pos)
            else:
                print(f"pruned position {tile_pos}")
        
        return pruned_positions
    
    @classmethod
    def normalize_positions(cls, positions: List[Vector2i]) -> List[Vector2i]:
        """Centers and bounds-checks the tile positions"""
        if not positions:
            return positions
            
        # Calculate average position using float math first
        avg_pos_x = sum(pos.x for pos in positions) / len(positions)
        avg_pos_y = sum(pos.y for pos in positions) / len(positions)
        
        # Round to match GDScript's behavior
        avg_pos = Vector2i(round(avg_pos_x), round(avg_pos_y))
        
        # Calculate initial offset using integer division
        target_center = Vector2i(Config.max_board_size // 2, Config.max_board_size // 2)
        offset = target_center - avg_pos
        
        # Find bounds after offset
        min_pos = Vector2i(float('inf'), float('inf'))
        max_pos = Vector2i(float('-inf'), float('-inf'))
        for pos in positions:
            new_pos = pos + offset
            min_pos = Vector2i(min(min_pos.x, new_pos.x), min(min_pos.y, new_pos.y))
            max_pos = Vector2i(max(max_pos.x, new_pos.x), max(max_pos.y, new_pos.y))
        
        # Adjust offset if positions would be out of bounds
        offset = Vector2i(
            offset.x + min(0, -min_pos.x) - max(0, max_pos.x - (Config.max_board_size - 1)),
            offset.y + min(0, -min_pos.y) - max(0, max_pos.y - (Config.max_board_size - 1))
        )
        
        # Apply adjusted offset
        normalized_positions: List[Vector2i] = []
        for pos in positions:
            normalized_positions.append(pos + offset)
        
        return normalized_positions 