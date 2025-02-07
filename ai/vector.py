from dataclasses import dataclass
from typing import Self

@dataclass(frozen=True)
class Vector2i:
    x: int
    y: int
    
    def __add__(self, other: Self) -> Self:
        return Vector2i(self.x + other.x, self.y + other.y)
    
    def __sub__(self, other: Self) -> Self:
        return Vector2i(self.x - other.x, self.y - other.y)
    
    def __mul__(self, scalar: int) -> Self:
        return Vector2i(self.x * scalar, self.y * scalar)
    
    def __truediv__(self, scalar: int) -> Self:
        return Vector2i(self.x // scalar, self.y // scalar)
    
    def abs(self) -> Self:
        return Vector2i(abs(self.x), abs(self.y))

# Common vectors
Vector2i.LEFT = Vector2i(-1, 0)
Vector2i.RIGHT = Vector2i(1, 0)
Vector2i.UP = Vector2i(0, -1)
Vector2i.DOWN = Vector2i(0, 1)
Vector2i.ZERO = Vector2i(0, 0)