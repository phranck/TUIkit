# Vendored Image Decoder Sources

TUIkit vendors the decoder sources required by `TUIkitImage` so versioned SwiftPM consumers do not inherit branch- or
commit-based package requirements. Only the production Swift targets are included.

| Source | Revision | Included targets | License |
| --- | --- | --- | --- |
| `tayloraswift/swift-png` | `2f68db3d6b3005035dc213275e8f35b6a4d0581f` | `PNG`, `LZ77` | Apache-2.0 and MPL-2.0 |
| `tayloraswift/swift-jpeg` | `c393ac5a683d09c6b1d6410402e25a606d36836f` | `JPEG` | MPL-2.0 |
| `tayloraswift/swift-hash` | `7fd5fb1753fe69bd6c04ecda36aab546cdcaae99` | `BaseDigits`, `Base16`, `CRC` | Apache-2.0 |

The original licenses and notices are stored beside each source tree. Imports use TUIkit-prefixed module names to avoid
consumer collisions. Decoder changes that enforce TUIkit's malformed-input and allocation-safety contract carry an explicit notice.
