set shell := ["bash", "-o", "pipefail", "-c"]
app := "Petal"
bundle := "com.example.petal"

default:
    just --list

gen:
    xcodegen generate

build: gen
    xcodebuild -scheme {{app}} -destination 'platform=macOS' -derivedDataPath build build

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
