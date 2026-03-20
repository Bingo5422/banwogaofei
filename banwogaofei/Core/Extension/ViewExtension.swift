import SwiftUI

extension View {
    func fullScreenBackground<V: View>(_ backgroundView: V) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                backgroundView
                    .ignoresSafeArea()
            )
    }
}
