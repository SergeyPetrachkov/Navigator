import SwiftUI

public extension View {
    @ViewBuilder
    func navigatorInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
