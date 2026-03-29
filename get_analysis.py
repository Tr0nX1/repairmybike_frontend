import subprocess
import os

def run_analyze():
    try:
        # Run flutter analyze and capture output
        result = subprocess.run(['flutter', 'analyze'], capture_output=True, text=False, cwd=os.getcwd())
        output = result.stdout.decode('utf-8', errors='ignore')
        error_output = result.stderr.decode('utf-8', errors='ignore')
        
        with open('analysis_clean.txt', 'w', encoding='utf-8') as f:
            f.write(output)
            f.write(error_output)
        print("Analysis saved to analysis_clean.txt")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run_analyze()
