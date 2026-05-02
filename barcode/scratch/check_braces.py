
import os

def check_braces(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    open_braces = content.count('{')
                    close_braces = content.count('}')
                    if open_braces != close_braces:
                        print(f"Brace mismatch in {path}: {{: {open_braces}, }}: {close_braces}")
                    
                    open_parens = content.count('(')
                    close_parens = content.count(')')
                    if open_parens != close_parens:
                        print(f"Paren mismatch in {path}: (: {open_parens}, ): {close_parens}")

if __name__ == "__main__":
    check_braces('lib')
