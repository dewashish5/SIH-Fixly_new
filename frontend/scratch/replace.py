import os
import re

base_dir = '/Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib'

def get_relative_path(from_path, to_path):
    from_dir = os.path.dirname(from_path)
    rel = os.path.relpath(to_path, from_dir)
    return rel

toast_utils_path = os.path.join(base_dir, 'core/utils/toast_utils.dart')

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if 'ScaffoldMessenger.of(context).showSnackBar' not in content:
        return

    # Add import if not present
    rel_import = get_relative_path(filepath, toast_utils_path)
    import_stmt = f"import '{rel_import}';"
    if 'ToastUtils' not in content:
        # insert after last import
        imports = re.findall(r'^import\s+.*?;', content, re.MULTILINE)
        if imports:
            last_import = imports[-1]
            content = content.replace(last_import, f"{last_import}\n{import_stmt}")
        else:
            content = f"{import_stmt}\n\n{content}"

    # Replace ScaffoldMessenger...
    # We will use regex to find ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), ...))
    # It might span multiple lines.
    
    # A generic regex to match the ScaffoldMessenger block:
    # ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\)(?:,\s*backgroundColor:\s*(.*?))?\s*\),?\s*\);?
    
    pattern = re.compile(
        r'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*'
        r'SnackBar\(\s*'
        r'content:\s*Text\((.*?)\)(?:,\s*backgroundColor:\s*(.*?))?,?\s*'
        r'(?:behavior:\s*SnackBarBehavior\.floating,\s*)?' # optional behavior
        r'(?:duration:\s*.*?,\s*)?' # optional duration
        r'(?:margin:\s*.*?,\s*)?' # optional margin
        r'\),?\s*\);?', re.DOTALL)
        
    def repl(m):
        msg = m.group(1).strip()
        bg = m.group(2)
        if bg and ('error' in bg.lower() or 'red' in bg.lower()):
            return f"ToastUtils.showError(context: context, message: {msg});"
        else:
            return f"ToastUtils.showToast(context: context, message: {msg});"

    new_content, count1 = pattern.subn(repl, content)
    
    # Pattern 2 for cases like: ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(...)
    pattern2 = re.compile(
        r'ScaffoldMessenger\.of\(context\)\s*(?:\.\.hideCurrentSnackBar\(\)\s*)?'
        r'\.showSnackBar\(\s*'
        r'SnackBar\(\s*'
        r'content:\s*Text\((.*?)\)(?:,\s*backgroundColor:\s*(.*?))?,?\s*'
        r'\),?\s*\);?', re.DOTALL)
        
    new_content, count2 = pattern2.subn(repl, new_content)

    if count1 > 0 or count2 > 0:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

