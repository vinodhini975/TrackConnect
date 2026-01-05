#!/bin/bash

# Navigate to the project directory
cd /home/danger/AndroidStudioProjects/TrackConnect

echo "Cleaning Flutter build cache..."
flutter clean

echo "Getting updated dependencies..."
flutter pub get

echo "Attempting to run the app..."
flutter run