import sys
import subprocess
import os

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def run():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    print('==================================================')
    print('[TEST RUNNER] Running Gig Support Chatbot Master Test Suite')
    print(f'[INFO] Base Directory: {base_dir}')
    print('==================================================\n')

    cmd = [sys.executable, '-m', 'pytest', 'tests', '-v', '--cov=gig_support_chatbot', '--cov-report=term-missing']
    result = subprocess.run(cmd, cwd=base_dir)
    sys.exit(result.returncode)

if __name__ == '__main__':
    run()
