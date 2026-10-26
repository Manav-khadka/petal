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
    printf '#!/bin/bash\nDIR="$$(cd "$$(dirname "$$0")" && pwd)"\necho "🌸 Preparing Petal for first launch..."\nif [ -d "/Applications/Petal.app" ]; then\n    xattr -cr "/Applications/Petal.app"\n    echo "✓ Security quarantine cleared for /Applications/Petal.app"\n    open "/Applications/Petal.app"\nelse\n    xattr -cr "$$DIR/Petal.app" 2>/dev/null || true\n    echo "✓ Security quarantine cleared"\n    open "$$DIR/Petal.app"\nfi\necho "🌸 Petal launched successfully!"\n' > /tmp/petal_dmg/"Open Petal (First Time).command"
    chmod +x /tmp/petal_dmg/"Open Petal (First Time).command"
    printf "🌸 Welcome to Petal!\n\n=========================================\nINSTALLATION:\n=========================================\n1. Drag 'Petal.app' to your 'Applications' folder.\n2. Open Petal from Applications.\n\n=========================================\nIF MACOS SHOWS GATEKEEPER WARNING:\n\"Apple could not verify Petal is free of malware...\"\n=========================================\nBecause Petal is an independent open-source app, macOS Gatekeeper flags it on first download.\n\nEASIEST FIX (No Terminal needed):\n1. In Finder / Applications, Right-Click (or Control-Click) 'Petal.app'\n2. Click 'Open' from the menu\n3. Click 'Open' on the confirmation pop-up\n(macOS will remember your choice; subsequent launches open normally!)\n\nOPTION 2:\n1. Open System Settings > Privacy & Security\n2. Scroll down to Security and click 'Open Anyway'\n\nOPTION 3:\nDouble-click 'Open Petal (First Time).command' included in this DMG.\n" > /tmp/petal_dmg/"README.txt"
    rm -f Petal.dmg Petal-v1.0.0-macOS-Universal.dmg Petal-v1.0.0-macOS-Universal.zip
    hdiutil create -volname "Petal" -srcfolder /tmp/petal_dmg -ov -format UDZO Petal.dmg
    cp Petal.dmg Petal-v1.0.0-macOS-Universal.dmg
    ditto -c -k --keepParent /tmp/petal_dmg/Petal.app Petal-v1.0.0-macOS-Universal.zip
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
