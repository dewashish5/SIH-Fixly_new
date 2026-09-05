import os
import re

base_dir = '/Users/dewashishhatekar/Developer/Projects/SIH-Fixly/frontend/lib'
toast_utils_path = os.path.join(base_dir, 'core/utils/toast_utils.dart')

def get_relative_path(from_path, to_path):
    from_dir = os.path.dirname(from_path)
    return os.path.relpath(to_path, from_dir).replace('\\', '/')

for root, _, files in os.walk(base_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            changed = False
            
            # Fix syntax error: e.toString();,
            new_content = re.sub(r'message:\s*(.*?);\s*,', r'message: \1,', content)
            if new_content != content:
                changed = True
                content = new_content
            
            # Fix syntax error: e.toString(););
            new_content = re.sub(r'message:\s*(.*?);\s*\)', r'message: \1)', content)
            if new_content != content:
                changed = True
                content = new_content

            if 'ToastUtils' in content and 'toast_utils.dart' not in content:
                rel_import = get_relative_path(filepath, toast_utils_path)
                import_stmt = f"import '{rel_import}';"
                
                # find the last import and insert after it
                imports = list(re.finditer(r'^import\s+.*?;', content, re.MULTILINE))
                if imports:
                    last_import = imports[-1]
                    end_pos = last_import.end()
                    content = content[:end_pos] + f"\n{import_stmt}" + content[end_pos:]
                else:
                    content = f"{import_stmt}\n\n{content}"
                changed = True

            if changed:
                with open(filepath, 'w') as f:
                    f.write(content)
                print(f"Fixed {filepath}")

