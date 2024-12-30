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

landscapeURL=$(echo $videos_response | jq -r '.[0].video_url')
landscapeTitle=$(echo $videos_response | jq -r '.[0].title')
portraitURL=$(echo $videos_response | jq -r '.[1].video_url')
portraitTitle=$(echo $videos_response | jq -r '.[1].title')

# Remove query parameters for testing
landscapeURL=${landscapeURL%%\?*}
portraitURL=${portraitURL%%\?*}

if [[ -z "$landscapeURL" || "$landscapeURL" == "null" ]]; then
  echo "Could not get landscape URL."
  exit 1
fi

if [[ -z "$portraitURL" || "$portraitURL" == "null" ]]; then
  echo "Could not get portrait URL."
  exit 1
fi

echo "Landscape URL: $landscapeURL"
echo "Landscape Title: $landscapeTitle"
echo "Portrait URL: $portraitURL"
echo "Portrait Title: $portraitTitle"

# Step 3: Verify the titles and ordering of the videos
if [[ "$landscapeTitle" != "Boots Horizontal" ]]; then
  echo "Expected first video title to be 'Boots Horizontal', but got '$landscapeTitle'."
  exit 1
fi

if [[ "$portraitTitle" != "Boots Vertical" ]]; then
  echo "Expected second video title to be 'Boots Vertical', but got '$portraitTitle'."
  exit 1
fi

# Step 4: Check the Content-Type for the landscape URL
landscape_content_type=$(curl -s -I $landscapeURL | grep -i "Content-Type")

if [[ "$landscape_content_type" == *"video/mp4"* ]]; then
  echo "Landscape video has correct Content-Type: video/mp4"
else
  echo "Landscape video does not have correct Content-Type."
  echo "Content-Type: $landscape_content_type"
  exit 1
fi

# Step 5: Check the Content-Type for the portrait URL
portrait_content_type=$(curl -s -I $portraitURL | grep -i "Content-Type")

if [[ "$portrait_content_type" == *"video/mp4"* ]]; then
  echo "Portrait video has correct Content-Type: video/mp4"
else
  echo "Portrait video does not have correct Content-Type."
  echo "Content-Type: $portrait_content_type"
  exit 1
fi

echo "All tests passed successfully."
