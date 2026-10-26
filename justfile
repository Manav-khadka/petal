set shell := ["bash", "-o", "pipefail", "-c"]
app := "Petal"
bundle := "com.example.petal"

default:
    just --list

gen:
    xcodegen generate

build: gen
    xcodebuild -scheme {{app}} -destination 'platform=macOS' -derivedDataPath build build

release: gen
    xcodebuild -scheme {{app}} -configuration Release -destination 'platform=macOS' ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO -derivedDataPath build_release build

dmg: release
    rm -rf /tmp/petal_dmg && mkdir -p /tmp/petal_dmg
    cp -R build_release/Build/Products/Release/Petal.app /tmp/petal_dmg/Petal.app
    xattr -cr /tmp/petal_dmg/Petal.app
    ln -s /Applications /tmp/petal_dmg/Applications
    printf '#!/bin/bash\nDIR="$$(cd "$$(dirname "$$0")" && pwd)"\necho "🌸 Preparing Petal for first launch..."\nif [ -d "/Applications/Petal.app" ]; then\n    xattr -cr "/Applications/Petal.app"\n    open "/Applications/Petal.app"\nelse\n    xattr -cr "$$DIR/Petal.app"\n    open "$$DIR/Petal.app"\nfi\n' > /tmp/petal_dmg/"Open Petal (First Time).command"
    chmod +x /tmp/petal_dmg/"Open Petal (First Time).command"
    printf "🌸 Welcome to Petal!\n\nINSTALLATION:\n1. Drag 'Petal.app' to the 'Applications' folder.\n2. Open Petal from Applications.\n\nIF MACOS SHOWS GATEKEEPER WARNING:\nDouble-click 'Open Petal (First Time).command', or go to System Settings > Privacy & Security > click 'Open Anyway'.\n" > /tmp/petal_dmg/"README.txt"
    rm -f Petal.dmg Petal-v1.0.0-macOS-Universal.dmg
    hdiutil create -volname "Petal" -srcfolder /tmp/petal_dmg -ov -format UDZO Petal.dmg
    cp Petal.dmg Petal-v1.0.0-macOS-Universal.dmg
    rm -rf /tmp/petal_dmg

test:
    swift test --package-path PetalKit

uitest: gen
    xcodebuild test -scheme {{app}} -destination 'platform=macOS' -derivedDataPath build

run: build
    pkill -x {{app}} || true
    open build/Build/Products/Debug/{{app}}.app

lint:
    swiftformat . && swiftlint --fix

logs:
    log stream --level debug --predicate 'process == "{{app}}"'

shot:
    screencapture -x build/shot.png

reset:
    defaults delete {{bundle}} || true
    tccutil reset All {{bundle}} || true
