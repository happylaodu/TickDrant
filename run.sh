#!/bin/bash
#
# Run Tickdrant
#

# Build and run the app
xcodebuild -project Tickdrant.xcodeproj -scheme Tickdrant -configuration Debug build && \
open ~/Library/Developer/Xcode/DerivedData/Tickdrant-*/Build/Products/Debug/Tickdrant.app
