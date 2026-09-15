#if os(iOS)
import HydrationDesignSystem
import UIKit

final class HistoryCollectionViewController: UIViewController {

    // MARK: - Section
    private enum Section: Hashable {
        case main
    }

    private let viewModel: HistoryViewModel
    private var watching: Task<Void, Never>?
    private(set) var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, HistoryViewState.Row>!

    // MARK: - Public
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        preconditionFailure("HistoryCollectionViewController is created in code, never from a storyboard")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureDataSource()

        viewModel.onStateChange = { [weak self] state in self?.apply(state) }
        apply(viewModel.state)

        watching = Task { await viewModel.observe() }
    }

    deinit {
        watching?.cancel()
    }

    func apply(_ state: HistoryViewState) {
        title = state.title
        navigationItem.prompt = state.emptyText ?? state.summaryText

        var snapshot = NSDiffableDataSourceSnapshot<Section, HistoryViewState.Row>()
        snapshot.appendSections([.main])
        snapshot.appendItems(state.rows, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Private
    private func configureCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.showsSeparators = true

        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration)
        )
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "history.list"
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, HistoryViewState.Row> { cell, _, row in
            var content = cell.defaultContentConfiguration()
            content.text = row.dayText
            content.secondaryText = [row.badgeText, row.totalText].compactMap { $0 }.joined(separator: " · ")
            content.secondaryTextProperties.color = HydrationAccent.uiColor(row.accent)
            cell.contentConfiguration = content
            cell.accessibilityIdentifier = row.identifier
            cell.accessories = row.isSelected ? [.checkmark(), .disclosureIndicator()] : [.disclosureIndicator()]
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, row in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: row)
        }
    }
}

// MARK: - HistoryCollectionViewController + UICollectionViewDelegate
extension HistoryCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let row = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.select(rowID: row.id)
    }
}
#endif
