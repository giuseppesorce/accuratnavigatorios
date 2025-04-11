import MapboxNavigation
import MapboxCoreNavigation
import SwiftUI
import Combine
import SnapKit

class HomeNavigationController: NavigationViewController {
    private let statusBarViewModel = StatusBarViewModel()
    private var statusBarController: NavigationStatusBarController?

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.async {
            self.setupComponents()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        statusBarController?.updatePosition()
    }

    private func setupComponents() {
        statusBarController = NavigationStatusBarController(parent: self,
                                                            viewModel: statusBarViewModel)
        statusBarController?.setup()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            // Animate position update during transition
            self.statusBarController?.updatePosition(animated: true)
        }, completion: { _ in
            // Final position update after transition
            self.statusBarController?.updatePosition()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if statusBarController?.checkForBannerChanges() == true {
            statusBarController?.updatePosition()
        }
    }
}
