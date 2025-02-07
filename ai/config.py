import json
from dataclasses import dataclass

@dataclass
class AIConfig:
    max_moves_to_consider: int

class Config:
    # Static configuration values
    max_board_size: int = 0
    tile_generation_threshold: float = 0.0
    tile_generation_noise_scale: float = 0.0
    ai: AIConfig = AIConfig(max_moves_to_consider=0)
    
    loaded: bool = False
    
    @staticmethod
    def load_config() -> None:
        assert not Config.loaded, "Config already loaded!"
        
        try:
            with open("config.json", 'r') as f:
                config = json.load(f)
        except Exception as e:
            raise RuntimeError(f"Failed to load config.json: {e}")
        
        Config.max_board_size = config["max_board_size"]
        assert Config.max_board_size > 0
        Config.tile_generation_threshold = config["tile_generation_threshold"]
        Config.tile_generation_noise_scale = config["tile_generation_noise_scale"]
        Config.ai.max_moves_to_consider = config["ai"]["max_moves_to_consider"]
        Config.loaded = True 