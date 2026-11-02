#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p .build/checks
swiftc -O Sources/LongShotCore/*.swift Tests/LongShotCoreTests/*.swift -o .build/checks/CoreChecks
.build/checks/CoreChecks
