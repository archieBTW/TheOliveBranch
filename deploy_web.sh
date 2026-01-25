#!/bin/bash
set -e

echo "Cleaning build..."
flutter clean

echo "Building Flutter Web..."
flutter build web --release --dart-define=FLUTTER_WEB_RENDERER=html

echo "Deploying to server..."
scp -r build/web/* arch@45.33.26.8:/var/www/archBTW.sh

echo "Deployment complete!"
