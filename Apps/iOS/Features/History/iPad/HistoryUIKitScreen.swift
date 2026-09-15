#if os(iOS)
import SwiftUI

struct HistoryUIKitScreen: UIViewControllerRepresentable {
    @StateObject private var viewModel: HistoryViewModel
    @ObservedObject private var coordinator: AppCoordinator

    init(coordinator: AppCoordinator, viewModel: @autoclosure @escaping () -> HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
        _coordinator = ObservedObject(wrappedValue: coordinator)
    }

    func makeUIViewController(context: Context) -> HistoryCollectionViewController {
        HistoryCollectionViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: HistoryCollectionViewController, context: Context) {
        viewModel.apply(selected: coordinator.selectedDay)
    }
}
#endif
