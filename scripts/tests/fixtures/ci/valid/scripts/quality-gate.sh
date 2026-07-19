swiftlint lint --strict --no-cache
swift build -Xswiftc -warnings-as-errors
./scripts/generate-documentation.sh
