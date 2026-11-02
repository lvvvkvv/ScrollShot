#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p .build/checks
swiftc -O -parse-as-library "$PWD/Sources/LongShot/UIHelpers.swift" "$PWD/Sources/LongShot/RegionSelector.swift" "$PWD/Tests/SelectionChecks/SelectionChecks.swift" -o .build/checks/SelectionChecks
.build/checks/SelectionChecks "$PWD/.build/checks/selection-result.txt"
cat .build/checks/selection-result.txt
