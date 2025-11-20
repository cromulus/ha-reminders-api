#!/bin/bash
# Simple test script for reminders-api that works in Home Assistant terminal

echo "========================================"
echo "Reminders API Connection Test"
echo "========================================"

if [ -z "$1" ]; then
    echo "Usage: bash test_api.sh <API_URL> [TOKEN]"
    echo "Example: bash test_api.sh http://192.168.1.100:8080"
    echo "Example: bash test_api.sh http://192.168.1.100:8080 mytoken"
    exit 1
fi

URL="$1"
TOKEN="$2"

echo ""
echo "Testing API at: $URL"
echo ""

# Build curl command
CURL_CMD="curl -v"
if [ -n "$TOKEN" ]; then
    CURL_CMD="$CURL_CMD -H 'Authorization: Bearer $TOKEN'"
    echo "Using authentication token"
fi

echo "----------------------------------------"
echo "Test 1: Fetching lists"
echo "----------------------------------------"
echo "Command: $CURL_CMD $URL/lists"
echo ""
if [ -n "$TOKEN" ]; then
    curl -v -H "Authorization: Bearer $TOKEN" "$URL/lists" 2>&1
else
    curl -v "$URL/lists" 2>&1
fi

echo ""
echo ""
echo "----------------------------------------"
echo "Test 2: Testing alternative endpoints"
echo "----------------------------------------"

for endpoint in "/api/lists" "/api/v1/lists" "/reminders"; do
    echo ""
    echo "Testing: $endpoint"
    if [ -n "$TOKEN" ]; then
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$URL$endpoint")
    else
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL$endpoint")
    fi
    echo "  HTTP Status: $STATUS"
done

echo ""
echo "========================================"
echo "Test Complete!"
echo "========================================"
echo ""
echo "If you got a successful response above, check what format it's in."
echo "Then check the Home Assistant logs:"
echo "  grep reminders_api /config/home-assistant.log | tail -20"
echo ""
