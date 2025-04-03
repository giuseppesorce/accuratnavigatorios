import MapboxNavigation
import MapboxCoreNavigation
import SwiftUI
import Combine

class CustomNavigationViewController: NavigationViewController {
    private var statusBarController: UIHostingController<StatusBarView>?
    private let viewModel = StatusBarViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupStatusBar()
        observeRouteProgress()
    }

    private func setupStatusBar() {
        let statusBar = UIHostingController(
            rootView: StatusBarView(
                weatherStatus: viewModel.weatherStatus,
                distanceInfo: viewModel.distanceInfo,
                humidityPercentage: viewModel.humidityPercentage
            )
        )

        statusBarController = statusBar
        statusBar.view.backgroundColor = .clear

        addChild(statusBar)
        view.addSubview(statusBar.view)
        statusBar.didMove(toParent: self)

        statusBar.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusBar.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusBar.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            statusBar.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            statusBar.view.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Aggiornamenti automatici quando cambiano i dati
        viewModel.$weatherStatus
            .combineLatest(viewModel.$distanceInfo, viewModel.$humidityPercentage)
            .sink { [weak self] weather, distance, humidity in
                self?.updateStatusBarView()
            }
            .store(in: &cancellables)
    }

    private func updateStatusBarView() {
        statusBarController?.rootView = StatusBarView(
            weatherStatus: viewModel.weatherStatus,
            distanceInfo: viewModel.distanceInfo,
            humidityPercentage: viewModel.humidityPercentage
        )
    }

    private func observeRouteProgress() {
        // Monitora progresso percorso e aggiorna la distanza
        NotificationCenter.default.publisher(for: .routeControllerProgressDidChange)
            .compactMap { notification -> RouteProgress? in
                return notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            }
            .sink { [weak self] progress in
                let formatter = DistanceFormatter()
                let distance = formatter.string(from: progress.distanceRemaining)
                self?.viewModel.updateDistance(distance: "In \(distance)")
            }
            .store(in: &cancellables)
    }
}
