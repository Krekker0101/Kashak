"""Parse Dart syntax using tree-sitter; not type analysis or Flutter analyze."""
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.tooling/python'))
import tree_sitter
import tree_sitter_dart

parser = tree_sitter.Parser(tree_sitter.Language(tree_sitter_dart.language()))
errors = []
count = 0
for directory in ('lib','test','integration_test'):
    for file in (root/directory).rglob('*.dart'):
        data=file.read_bytes()
        tree=parser.parse(data)
        def visit(node):
            if node.type=='ERROR' or node.is_missing:
                snippet=data[node.start_byte:node.end_byte].decode(errors='replace')[:160]
                errors.append(f'{file.relative_to(root)}:{node.start_point.row+1}: {node.type}: {snippet}')
            else:
                for child in node.children: visit(child)
        visit(tree.root_node)
        count+=1
if errors:
    print('\n'.join(errors))
    raise SystemExit(1)
print(f'PASS: tree-sitter parsed {count} Dart files without syntax errors (not type analysis).')
