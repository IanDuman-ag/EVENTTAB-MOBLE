import urllib.request
import json

def main():
    base_url = "http://127.0.0.1:8000"
    
    # Login
    login_data = json.dumps({
        "identifier": "testuser",
        "password": "TestPass123!"
    }).encode("utf-8")
    
    req = urllib.request.Request(
        f"{base_url}/api/auth/login/",
        data=login_data,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        res = urllib.request.urlopen(req)
        token = json.loads(res.read())["token"]
        print("Login Token:", token)
    except Exception as e:
        print("Login failed:", e)
        return

    # Fetch Categories
    req2 = urllib.request.Request(
        f"{base_url}/api/events/categories/",
        headers={"Authorization": f"Token {token}"}
    )
    
    try:
        res2 = urllib.request.urlopen(req2)
        categories = json.loads(res2.read())
        print(f"\nFound {len(categories)} categories:")
        for cat in categories:
            print(f"  - {cat['name']} (ID: {cat['id']}, Type: {cat['category_type']}, Icon: {cat['icon']})")
            
            # Fetch events for this category
            req3 = urllib.request.Request(
                f"{base_url}/api/events/categories/{cat['id']}/events/",
                headers={"Authorization": f"Token {token}"}
            )
            res3 = urllib.request.urlopen(req3)
            events = json.loads(res3.read())
            print(f"    -> Events ({len(events)}):")
            for ev in events:
                print(f"       * {ev['title']} (ID: {ev['id']}, Venue: {ev['venue']}, Status: {ev['status']})")
                
                # Fetch standings/leaderboard for this event
                req4 = urllib.request.Request(
                    f"{base_url}/api/events/judging-events/{ev['id']}/standings/",
                    headers={"Authorization": f"Token {token}"}
                )
                res4 = urllib.request.urlopen(req4)
                standings = json.loads(res4.read())
                print(f"         Standings:")
                for stand in standings[:3]:
                    print(f"           #{stand['rank']} {stand['name']} - {stand['total_score']} PTS (Live: {stand['is_live']})")
    except Exception as e:
        print("API request failed:", e)

if __name__ == "__main__":
    main()
