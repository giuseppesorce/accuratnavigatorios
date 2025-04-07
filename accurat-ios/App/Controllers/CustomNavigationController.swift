import MapboxNavigation
import MapboxCoreNavigation
import SwiftUI
import Combine
import SnapKit

// MARK: - Custom Navigation View Controller

class CustomNavigationController: NavigationViewController {
    private let viewModel = StatusBarViewModel()
    private var statusBarController: NavigationStatusBarController?
    private var progressObserver: NavigationService?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.setupComponents()
//        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setupComponents()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupComponents() {
        // Setup status bar controller
        statusBarController = NavigationStatusBarController(parent: self, viewModel: viewModel)
        statusBarController?.setup()
        
        // Setup route progress observer
        progressObserver = NavigationService(viewModel: viewModel)
        progressObserver?.startObserving()

        // Setup view model updates
        viewModel.$weatherStatus
            .combineLatest(viewModel.$distanceInfo, viewModel.$humidityPercentage)
            .sink { [weak self] _, _, _ in
                self?.statusBarController?.updateContent()
            }
            .store(in: &cancellables)
    }

    @objc private func orientationChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.statusBarController?.updatePosition()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.statusBarController?.updatePosition()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Only update if banner has moved
        if statusBarController?.checkForBannerChanges() == true {
            statusBarController?.updatePosition()
        }
    }
}
