swift build --target TUIkit -Xswiftc -warnings-as-errors
swift-symbolgraph-extract \
    -experimental-allowed-reexported-modules=TUIkitCore,TUIkitStyling,TUIkitImage,TUIkitView
docc convert Sources/TUIkit/TUIkit.docc --warnings-as-errors
