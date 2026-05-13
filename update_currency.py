import os
import re

def replace_currency(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replacements
    # \$${ -> EGP ${
    content = content.replace(r'\$${', r'EGP ${')
    # \$$ -> EGP $
    content = content.replace(r'\$$', r'EGP $')
    # \$ -> EGP  (only if followed by a number or ${)
    content = re.sub(r'\\\$(\d+)', r'EGP \1', content)
    
    # Replace any literal 'USD' with 'EGP' (be careful with variables, maybe just in strings)
    # Actually, we did 'USD' default in helpers.dart already, let's just do it directly.
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    lib_dir = os.path.join('mobile', 'lib')
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                replace_currency(os.path.join(root, file))

if __name__ == '__main__':
    main()
