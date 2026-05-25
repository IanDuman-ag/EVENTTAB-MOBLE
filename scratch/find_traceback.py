import os

def main():
    log_file = r"C:\Users\Admin\.gemini\antigravity\brain\a9f65231-2a3e-4a05-8ac2-353e86bdacc4\.system_generated\logs\transcript.jsonl"
    if not os.path.exists(log_file):
        print("Log file does not exist:", log_file)
        return
        
    print("Searching log file...")
    found_traceback = False
    traceback_lines = []
    
    with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
        for idx, line in enumerate(f, 1):
            if "Traceback" in line or "Internal Server Error" in line or "bad request" in line.lower():
                print(f"\n--- Match found on line {idx} ---")
                # Print a chunk of the line
                snippet = line[:1000]
                print(snippet)
                if len(line) > 1000:
                    print("... [truncated]")

if __name__ == "__main__":
    main()
