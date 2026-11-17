"""Generate BuffTap's original square glow texture (MPL-2.0)."""
from pathlib import Path
import math
import struct

size = 128
pixels = bytearray()
for y in range(size):
    for x in range(size):
        edge_distance = abs(max(abs(x + .5 - size / 2), abs(y + .5 - size / 2)) - 56)
        alpha = round(230 * math.exp(-.5 * (edge_distance / 2) ** 2))
        pixels.extend((255, 255, 255, alpha))
header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 0x28)
target = Path(__file__).resolve().parents[1] / 'addon/BuffTap/Media/ModernSquareGlow.tga'
target.write_bytes(header + pixels)
print(target)
