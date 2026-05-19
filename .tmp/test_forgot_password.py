"""Quick test of the forgot-password endpoint"""
import json
import urllib.request

email = "test@eventtab.dev"
url = "http://127.0.0.1:8000/api/auth/forgot-password/"

data = json.dumps({"email": email}).encode("utf-8")
req = urllib.request.Request(
    url,
    data=data,
    headers={"Content-Type": "application/json"},
    method="POST",
)

print(f"Requesting password reset for {email} ...")
with urllib.request.urlopen(req) as resp:
    body = json.loads(resp.read())
    print(f"Response: {body}")
    print("\nCheck the Django server terminal for the reset code.")
