import os
import json

def main():
    log_file = r"C:\Users\Admin\.gemini\antigravity\brain\a9f65231-2a3e-4a05-8ac2-353e86bdacc4\.system_generated\logs\transcript.jsonl"
    if not os.path.exists(log_file):
        print("Log file does not exist:", log_file)
        return
        
    with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
        for idx, line in enumerate(f, 1):
            if idx == 131 or "Internal Server Error" in line or "Traceback" in line:
                try:
                    obj = json.loads(line)
                    content = obj.get("content", "")
                    if "Internal Server Error" in content or "Traceback" in content:
                        print(f"\n================ STEP {obj.get('step_index')} CONTENT ================")
                        print(content)
                except Exception as e:
                    # Not JSON or other error
                    if "Internal Server Error" in line:
                        print(f"\n================ LINE {idx} ================")
                        print(line[:2000])

if __name__ == "__main__":
    main()
