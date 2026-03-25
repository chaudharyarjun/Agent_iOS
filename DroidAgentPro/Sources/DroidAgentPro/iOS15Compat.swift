import SwiftUI

// MARK: - iOS 15 Compatibility Helpers

extension View {
    /// Replaces .toolbarBackground which is iOS 16+
    func navBarBackground(_ color: Color) -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(color)
            appearance.shadowColor = UIColor(Color(hex: "0e1620"))
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .semibold)
            ]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        }
    }

    /// Replaces .scrollContentBackground(.hidden) which is iOS 16+
    func listBackground(_ color: Color) -> some View {
        self.onAppear {
            UITableView.appearance().backgroundColor = .clear
            UITableViewCell.appearance().backgroundColor = .clear
        }
    }
}
