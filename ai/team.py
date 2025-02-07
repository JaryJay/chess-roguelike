from enum import Enum, auto

class Team(Enum):
    PLAYER = auto()
    ENEMY_AI = auto()
    
    def is_hostile_to(self, other: 'Team') -> bool:
        return self != other
    
    def is_friendly_to(self, other: 'Team') -> bool:
        return self == other
    
    def is_player(self) -> bool:
        return self == Team.PLAYER