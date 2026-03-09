import os, re

def find_container_issues(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    issues = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Look for Container( or AnimatedContainer( with direct color: param
        if re.search(r'\bContainer\s*\(', line):
            container_indent = len(line) - len(line.lstrip())
            # Direct params would be indented by container_indent + 2/4
            direct_param_indent = container_indent + 2
            has_direct_color = False
            has_direct_decoration = False
            j = i + 1
            paren_depth = 1
            while j < len(lines) and paren_depth > 0 and j < i + 100:
                l = lines[j]
                paren_depth += l.count('(') - l.count(')')
                line_indent = len(l) - len(l.lstrip())
                # Direct parameter: indent is container_indent+2 to container_indent+6
                if container_indent + 1 <= line_indent <= container_indent + 8:
                    stripped = l.strip()
                    if stripped.startswith('color:') and 'BoxDecoration' not in ''.join(lines[max(0,j-3):j]):
                        has_direct_color = True
                    if stripped.startswith('decoration:'):
                        has_direct_decoration = True
                j += 1
            if has_direct_color and has_direct_decoration:
                issues.append((filepath, i+1, line.rstrip()))
        i += 1
    return issues

all_issues = []
for root, dirs, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            all_issues.extend(find_container_issues(path))

for path, line, content in all_issues:
    print(f'{path}:{line}: {content.strip()}')

# Also find BoxDecoration with both color and gradient
print('\n--- BoxDecoration with color+gradient ---')
for root, dirs, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as fh:
                lines = fh.readlines()
            i = 0
            while i < len(lines):
                if 'BoxDecoration(' in lines[i]:
                    block = lines[i:i+20]
                    block_text = ''.join(block)
                    has_color = bool(re.search(r'^\s+color:', block_text, re.MULTILINE))
                    has_gradient = bool(re.search(r'^\s+gradient:', block_text, re.MULTILINE))
                    if has_color and has_gradient:
                        print(f'{path}:{i+1}: {lines[i].rstrip().strip()}')
                i += 1
