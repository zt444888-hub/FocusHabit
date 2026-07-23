#!/bin/bash
set -e
xcodegen generate
mkdir -p "FocusHabit.xcodeproj/xcshareddata/xcschemes"
cp _xcschemes/*.xcscheme "FocusHabit.xcodeproj/xcshareddata/xcschemes/"
echo "Project regenerated with schemes."
open FocusHabit.xcodeproj
