"""Lightweight delimiter check for environments without Dart. Not a Dart analyzer."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
count = 0
failures = []
for directory in ('lib','test','integration_test'):
    for path in (root/directory).rglob('*.dart'):
        source = path.read_text()
        stack = []
        i = 0
        while i < len(source):
            c = source[i]
            if source.startswith('//',i):
                end = source.find('\n',i)
                i = len(source) if end<0 else end+1
                continue
            if source.startswith('/*',i):
                level = 1
                i += 2
                while i<len(source) and level:
                    if source.startswith('/*',i): level+=1; i+=2
                    elif source.startswith('*/',i): level-=1; i+=2
                    else: i+=1
                continue
            if c in ('"',"'"):
                quote = c*3 if source.startswith(c*3,i) else c
                raw = i>0 and source[i-1]=='r'
                i += len(quote)
                while i<len(source):
                    if not raw and source[i]=='\\': i+=2; continue
                    if source.startswith(quote,i): i+=len(quote); break
                    i+=1
                continue
            if c in '([{': stack.append((c,i))
            if c in ')]}':
                if not stack or stack[-1][0] != {')':'(',']':'[','}':'{'}[c]:
                    failures.append(f'{path.relative_to(root)}:{source.count(chr(10),0,i)+1}: unexpected {c}')
                    break
                stack.pop()
            i+=1
        else:
            if stack:
                c,pos=stack[-1]
                failures.append(f'{path.relative_to(root)}:{source.count(chr(10),0,pos)+1}: unclosed {c}')
        count+=1
if failures:
    print('\n'.join(failures))
    raise SystemExit(1)
print(f'PASS: balanced delimiters in {count} Dart files (not type analysis).')
