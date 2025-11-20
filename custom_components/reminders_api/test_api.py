#!/usr/bin/env python3
"""Test script to debug reminders-api connection."""

import asyncio
import aiohttp
import json
import sys
from urllib.parse import quote

async def test_api(url, token=None):
    """Test the reminders API endpoints."""
    print(f"\n🔍 Testing API at: {url}")
    print("=" * 60)

    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
        print(f"✓ Using authentication token")

    async with aiohttp.ClientSession() as session:
        # Test 1: Basic connection
        print("\n1. Testing basic connection to /lists...")
        try:
            async with session.get(f"{url}/lists", headers=headers) as response:
                print(f"   Status: {response.status}")
                content_type = response.headers.get("Content-Type", "")
                print(f"   Content-Type: {content_type}")

                text = await response.text()
                print(f"   Raw response: {text[:500]}")

                if response.status == 200:
                    if "application/json" in content_type.lower():
                        data = json.loads(text)
                        print(f"\n   ✓ JSON parsed successfully!")
                        print(f"   Response type: {type(data)}")

                        if isinstance(data, list):
                            print(f"   Found {len(data)} lists")
                            for i, item in enumerate(data[:3]):
                                print(f"     List {i}: {item}")
                        elif isinstance(data, dict):
                            print(f"   Response is a dict with keys: {list(data.keys())}")
                            for key, value in list(data.items())[:3]:
                                print(f"     {key}: {value}")
                        else:
                            print(f"   Unexpected data type: {type(data)}")
                    else:
                        print(f"   Non-JSON response: {text[:200]}")
                else:
                    print(f"   ❌ Error response: {text}")

        except Exception as e:
            print(f"   ❌ Error: {e}")

        # Test 2: Try fetching a specific list if we found any
        print("\n2. Testing fetching specific list (if available)...")
        try:
            async with session.get(f"{url}/lists", headers=headers) as response:
                if response.status == 200:
                    text = await response.text()
                    data = json.loads(text) if text else None

                    list_name = None
                    if isinstance(data, list) and data:
                        # If it's a list, try the first item
                        if isinstance(data[0], str):
                            list_name = data[0]
                        elif isinstance(data[0], dict):
                            list_name = data[0].get("name") or data[0].get("title") or data[0].get("id")

                    if list_name:
                        print(f"   Testing with list: {list_name}")
                        list_url = f"{url}/lists/{quote(list_name, safe='')}"
                        async with session.get(list_url, headers=headers) as list_response:
                            print(f"   Status: {list_response.status}")
                            list_text = await list_response.text()
                            print(f"   Response: {list_text[:200]}")
                    else:
                        print("   No list name found to test")
        except Exception as e:
            print(f"   ❌ Error: {e}")

        # Test 3: Check if there's a different endpoint structure
        print("\n3. Testing alternative endpoints...")
        for endpoint in ["/api/lists", "/api/v1/lists", "/reminders", "/api/reminders"]:
            try:
                async with session.get(f"{url}{endpoint}", headers=headers) as response:
                    print(f"   {endpoint}: Status {response.status}")
            except:
                print(f"   {endpoint}: Failed to connect")

        print("\n" + "=" * 60)
        print("Test complete!")

async def main():
    """Main function."""
    if len(sys.argv) < 2:
        print("Usage: python test_api.py <API_URL> [TOKEN]")
        print("Example: python test_api.py http://localhost:8080")
        print("Example: python test_api.py http://192.168.1.100:8080 mytoken")
        sys.exit(1)

    url = sys.argv[1].rstrip("/")
    token = sys.argv[2] if len(sys.argv) > 2 else None

    await test_api(url, token)

if __name__ == "__main__":
    asyncio.run(main())