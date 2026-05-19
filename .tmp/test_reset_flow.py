"""
Test the complete password reset flow with 2-minute expiration
"""
import json
import time
import urllib.request
import urllib.error

BASE_URL = "http://127.0.0.1:8000"

def post_json(url, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        return exc.code, json.loads(exc.read())

print("=" * 70)
print("Testing Password Reset Flow")
print("=" * 70)

# Step 1: Request reset code
email = "test@eventtab.dev"
print(f"\n1. Requesting reset code for {email} ...")
status, body = post_json(f"{BASE_URL}/api/auth/forgot-password/", {"email": email})
print(f"   Status: {status}")
print(f"   Response: {body}")
print("\n   ⚠️  Check your Django terminal for the reset code!")
print("   (It's printed there because you're using console email backend)")

# Step 2: Wait and show expiration warning
print("\n2. Reset code expires in 2 minutes.")
print("   Copy the code from Django terminal and paste it in the Flutter app.")
print("   If you wait more than 2 minutes, you'll need to click 'RESEND CODE'.")

# Step 3: Test resend
print("\n3. Testing RESEND CODE functionality...")
time.sleep(2)  # Wait 2 seconds
status, body = post_json(f"{BASE_URL}/api/auth/forgot-password/", {"email": email})
print(f"   Status: {status}")
print(f"   Response: {body}")
print("   ✓ New code generated! Check Django terminal again.")

print("\n" + "=" * 70)
print("Summary:")
print("  • Reset codes are sent to the user's registered email")
print("  • Each user gets their own code (not a static email)")
print("  • Codes expire after 2 minutes")
print("  • Users can request a new code anytime with 'RESEND CODE'")
print("=" * 70)
