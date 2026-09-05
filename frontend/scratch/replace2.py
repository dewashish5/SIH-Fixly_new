import os
import re

base_dir = '/Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib'
toast_utils_path = os.path.join(base_dir, 'core/utils/toast_utils.dart')

def get_relative_path(from_path, to_path):
    from_dir = os.path.dirname(from_path)
    return os.path.relpath(to_path, from_dir)

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # match generic ScaffoldMessenger... showSnackBar
    # we'll find all occurrences of ScaffoldMessenger
    
    pattern = re.compile(
        r'ScaffoldMessenger\.of\(\s*context,?\s*\)\s*'
        r'(?:\.\.hideCurrentSnackBar\(\)\s*)?'
        r'\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\)(?:,\s*backgroundColor:\s*(.*?))?,?\s*\),?\s*\);?', re.DOTALL)

    def repl(m):
        msg = m.group(1).strip()
        bg = m.group(2)
        if bg and ('error' in bg.lower() or 'red' in bg.lower()):
            return f"ToastUtils.showError(context: context, message: {msg});"
        else:
            return f"ToastUtils.showToast(context: context, message: {msg});"

    new_content, count = pattern.subn(repl, content)

    if count > 0:
        if 'ToastUtils' not in new_content:
            rel_import = get_relative_path(filepath, toast_utils_path)
            import_stmt = f"import '{rel_import}';"
            imports = re.findall(r'^import\s+.*?;', new_content, re.MULTILINE)
            if imports:
                last_import = imports[-1]
                new_content = new_content.replace(last_import, f"{last_import}\n{import_stmt}")
            else:
                new_content = f"{import_stmt}\n\n{new_content}"
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath} ({count} replacements)")

for root, _, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
