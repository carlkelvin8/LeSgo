#!/bin/bash

# Create Test Rider Account Script
# This script creates a test rider account for development/testing

API_BASE_URL="https://lesgo-api-feature-auth-secmes.free.laravel.cloud/api/v1"

echo "========================================="
echo "Creating Test Rider Account"
echo "========================================="
echo ""

# Test Rider Credentials
RIDER_NAME="Test Rider"
RIDER_EMAIL="testrider@lesgo.com"
RIDER_PASSWORD="TestRider123!"
RIDER_PHONE="+639171234567"
RIDER_LICENSE="N01-23-456789"

echo "Rider Details:"
echo "  Name: $RIDER_NAME"
echo "  Email: $RIDER_EMAIL"
echo "  Password: $RIDER_PASSWORD"
echo "  Phone: $RIDER_PHONE"
echo "  License: $RIDER_LICENSE"
echo ""
echo "Registering rider..."
echo ""

# Register the rider
RESPONSE=$(curl -s -X POST "$API_BASE_URL/drivers/register" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"$RIDER_NAME\",
    \"email\": \"$RIDER_EMAIL\",
    \"password\": \"$RIDER_PASSWORD\",
    \"password_confirmation\": \"$RIDER_PASSWORD\",
    \"phone_number\": \"$RIDER_PHONE\",
    \"license_number\": \"$RIDER_LICENSE\"
  }")

echo "Response:"
echo "$RESPONSE" | jq '.'
echo ""

# Check if registration was successful
if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
  if [ "$SUCCESS" = "true" ]; then
    echo "========================================="
    echo "✅ Rider account created successfully!"
    echo "========================================="
    echo ""
    echo "Login Credentials:"
    echo "  Email: $RIDER_EMAIL"
    echo "  Password: $RIDER_PASSWORD"
    echo ""
    echo "Note: The rider status is 'pending' and needs admin approval before accepting orders."
  else
    echo "❌ Registration failed!"
    echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
  fi
else
  echo "❌ Registration failed!"
  echo "Response: $RESPONSE"
fi
