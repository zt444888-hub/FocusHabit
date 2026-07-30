#!/bin/bash
set -e
xcodegen generate
mkdir -p "FocusHabit.xcodeproj/xcshareddata/xcschemes"
cp _xcschemes/*.xcscheme "FocusHabit.xcodeproj/xcshareddata/xcschemes/" 2>/dev/null || true
echo "Project regenerated with schemes."
open FocusHabit.xcodeproj
