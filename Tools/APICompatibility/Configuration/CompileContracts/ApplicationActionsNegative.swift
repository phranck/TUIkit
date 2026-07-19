import Foundation
import TUIkit

@MainActor
func documentationLink() -> some View {
    Link("Documentation", destination: URL(string: "https://example.com")!)
}
