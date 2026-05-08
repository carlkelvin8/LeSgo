#!/bin/bash

echo "🔨 Generating JSON serialization code for DTOs..."

cd "$(dirname "$0")"

flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Done! JSON serialization code generated."
