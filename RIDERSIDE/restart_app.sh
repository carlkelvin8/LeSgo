#!/bin/bash

# Script to properly restart the Flutter app with all changes

echo "🔄 Restarting RIDERSIDE app with new status changes..."
echo ""

# Step 1: Clean build
echo "1️⃣ Cleaning build cache..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ Clean failed!"
    exit 1
fi
echo "✅ Clean complete"
echo ""

# Step 2: Get dependencies
echo "2️⃣ Getting dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Pub get failed!"
    exit 1
fi
echo "✅ Dependencies updated"
echo ""

# Step 3: Run the app
echo "3️⃣ Starting app..."
echo ""
echo "📱 The app will now start with the new statuses enabled:"
echo "   ✅ Driver Has Arrived"
echo "   ✅ In Progress"
echo ""
echo "Press Ctrl+C to stop the app"
echo ""

flutter run
