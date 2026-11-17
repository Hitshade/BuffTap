"""Generate BuffTap's original square glow texture (MPL-2.0)."""
from pathlib import Path
import math
import struct

size = 128
pixels = bytearray()
def smooth(value):
    value = max(0, min(1, value))
    return value * value * (3 - 2 * value)

for y in range(size):
    for x in range(size):
        ax, ay = abs(x + .5 - size / 2), abs(y + .5 - size / 2)
        # Rounded inner opening blends around the artwork like the game glow.
        # The outside remains square, with no hard texture-boundary cutoff.
        qx, qy = ax - 38, ay - 38
        inner_distance = math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - 12
        inner = smooth((inner_distance + 2) / 8)
        outside = max(0, max(ax, ay) - 56)
        outer = math.exp(-.5 * (outside / 4) ** 2) * (1 - smooth(outside / 8))
        alpha = round(255 * inner * outer)
        pixels.extend((255, 255, 255, alpha))
header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 0x28)
target = Path(__file__).resolve().parents[1] / 'addon/BuffTap/Media/ModernRoundedInnerGlow.tga'
target.write_bytes(header + pixels)
print(target)
