"""Rasterize Scetch's code-defined pencil mark; no external image or font assets."""
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def png(size):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
    rows = bytearray()
    for y in range(size):
        rows.append(0)
        for x in range(size):
            px, py = x * 108 / size, y * 108 / size
            pencil = 97 <= px + py <= 117 and 30 <= px <= 77 and 28 <= py <= 80
            tip = 27 <= px <= 40 and 68 <= py <= 82 and px + py >= 102
            rows.extend((245, 244, 238) if pencil or tip else (117, 134, 107))
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size,size,8,2,0,0,0)) + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')

assets = ROOT / 'ios/Runner/Assets.xcassets'
icons = assets / 'AppIcon.appiconset'
icons.mkdir(parents=True, exist_ok=True)
images = []
for idiom, points, scales in [('iphone',20,[2,3]),('iphone',29,[2,3]),('iphone',40,[2,3]),('iphone',60,[2,3]),
                               ('ipad',20,[1,2]),('ipad',29,[1,2]),('ipad',40,[1,2]),('ipad',76,[1,2]),('ipad',83.5,[2]),('ios-marketing',1024,[1])]:
    for scale in scales:
        size = int(points * scale)
        name = f'Icon-{size}.png'
        (icons / name).write_bytes(png(size))
        images.append({'idiom':idiom, 'size':f'{points}x{points}', 'scale':f'{scale}x', 'filename':name})
(icons / 'Contents.json').write_text(json.dumps({'images':images,'info':{'version':1,'author':'xcode'}},indent=2))
(assets / 'Contents.json').write_text(json.dumps({'info':{'version':1,'author':'xcode'}}))
print(f'Generated {len(images)} iOS icon entries.')
