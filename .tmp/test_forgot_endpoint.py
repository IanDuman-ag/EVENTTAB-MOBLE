import json
import urllib.request
import urllib.error

url = "http://127.0.0.1:8000/api/auth/forgot-password/"
email = "kirbydumz@gmail.com"

data = json.dumps({"email": email}).encode("utf-8")
req = urllib.request.Request(
    url,
    data=data,
    headers={"Content-Type": "application/json"},
    method="POST",
)

print(f"Testing forgot-password endpoint with email: {email}")
print(f"URL: {url}\n")

try:
    with urllib.request.urlopen(req) as resp:
        print(f"Status: {resp.status}")
        print(f"Response: {resp.read().decode('utf-8')}")
except urllib.error.HTTPError as e:
    print(f"HTTP Error {e.code}")
    print(f"Response body:")
    print(e.read().decode('utf-8'))
except Exception as e:
    print(f"Error: {e}")
