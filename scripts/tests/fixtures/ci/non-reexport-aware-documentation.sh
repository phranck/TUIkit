swift build --target TUIkit -Xswiftc -warnings-as-errors
swift-symbolgraph-extract -module-name TUIkit
docc convert Sources/TUIkit/TUIkit.docc --warnings-as-errors
