"""Host-independent checks. These do NOT replace Flutter analyze or native builds."""
import json
import plistlib
import re
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[1]
count = 0
for directory in ('android', 'ios'):
    for path in (root / directory).rglob('*'):
        if path.suffix in ('.xml','.storyboard','.xcscheme','.xcworkspacedata'):
            ET.parse(path)
            count += 1
        if path.suffix in ('.plist','.xcprivacy'):
            with path.open('rb') as file:
                plistlib.load(file)
            count += 1
        if path.name == 'Contents.json':
            value = json.loads(path.read_text())
            for item in value.get('images',[]):
                assert (path.parent/item['filename']).is_file(), item
            count += 1
project = (root/'ios/Runner.xcodeproj/project.pbxproj').read_text()
defined = set(re.findall(r'^\s*(A[0-9A-F]{23}) =',project,re.M))
referenced = set(re.findall(r'\bA[0-9A-F]{23}\b',project))
assert defined == referenced, referenced-defined
manifest = (root/'android/app/src/main/AndroidManifest.xml').read_text()
assert 'android.permission.INTERNET' not in manifest
assert 'android:allowBackup="false"' in manifest
for path in (root/'lib').rglob('*.dart'):
    text = path.read_text()
    for imported in re.findall(r"import '([^']+)'", text):
        if not imported.startswith(('dart:','package:')):
            assert (path.parent/imported).is_file(), (path,imported)
    assert 'TODO' not in text, path
print(f'PASS: {count} native XML/plist/asset files, Xcode references, Dart relative imports, release network/backup policy.')
