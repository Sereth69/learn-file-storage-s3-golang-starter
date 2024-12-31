#!/bin/bash

# Step 1: Login and get the JWT token
login_response=$(curl -s -X POST http://localhost:8091/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@tubely.com",
    "password": "password"
  }')
jwtToken=$(echo $login_response | jq -r '.token')

if [[ -z "$jwtToken" || "$jwtToken" == "null" ]]; then
  echo "Login failed."
  exit 1
fi

echo "JWT Token: $jwtToken"

# Step 2: Get the list of videos and extract URLs and titles
videos_response=$(curl -s -X GET http://localhost:8091/api/videos \
  -H "Authorization: Bearer $jwtToken")

# Print the entire response to debug
echo "Videos Response: $videos_response"

# Check if the response is a valid JSON array
if ! echo "$videos_response" | jq -e .[0] > /dev/null 2>&1; then
  echo "Fetching videos failed or no videos found."
  exit 1
fi

# Check if the first video's URL contains "cloudfront.net"
video_url=$(echo "$videos_response" | jq -r '.[0].video_url')
echo "Video URL: $video_url"
if [[ "$video_url" != *"cloudfront.net"* ]]; then
  echo "Video URL does not contain 'cloudfront.net'"
  exit 1
fi

# Step 3: GET ${videoURL}
video_response=$(curl -s -I "$video_url")

# Check if the status code is 200
video_status=$(echo "$video_response" | grep HTTP | awk '{print $2}')
if [ "$video_status" != "200" ]; then
  echo "Fetching video failed with status code $video_status"
  exit 1
fi

# Check if the "Content-Type" header contains "video/mp4"
content_type=$(echo "$video_response" | grep "Content-Type" | awk '{print $2}')
if [[ "$content_type" != *"video/mp4"* ]]; then
  echo "Content-Type is not 'video/mp4'"
  exit 1
fi

echo "All tests passed successfully!"