import Foundation
import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import SwiftUI
import Combine
import SnapKit

class NavigationStatusBarController {
    // View components
    private var statusBarView: StatusBarView?
    private var verticalStatusBarView: VerticalStatusBarView?

    // Controllers
    private var parentViewController: UIViewController
    private var weatherViewModel: WeatherViewModel
    private var verticalViewModel = VerticalStatusBarViewModel()
    private var navigationService: NavigationDistanceService?

    // State tracking
    private var bannerFrame: CGRect = .zero

    init(parent: UIViewController, viewModel: WeatherViewModel) {
        self.parentViewController = parent
        self.weatherViewModel = viewModel
    }

    func setup() {
        // Setup horizontal status bar
        let statusBar = StatusBarView(weatherViewModel: weatherViewModel)
        statusBarView = statusBar
        parentViewController.view.addSubview(statusBar)

        // Setup vertical status bar
        let verticalBar = VerticalStatusBarView(viewModel: verticalViewModel)
        verticalStatusBarView = verticalBar
        parentViewController.view.addSubview(verticalBar)

        // Setup navigation service
        navigationService = NavigationDistanceService.createCombinedService(
            horizontalViewModel: weatherViewModel,
            verticalViewModel: verticalViewModel
        )
        navigationService?.startObserving()

        updatePosition(animated: false)
    }

    func updatePosition(animated: Bool = false) {
        guard let statusBarView = statusBarView,
              let verticalStatusBarView = verticalStatusBarView else { return }

        let isLandscape = UIDevice.current.orientation.isLandscape
        let instructionsBanner = MapboxViewFinder.findInstructionsBanner(in: parentViewController)

        // Position both views with/without animation
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.positionBars(
                    horizontal: statusBarView,
                    vertical: verticalStatusBarView,
                    isLandscape: isLandscape,
                    instructionsBanner: instructionsBanner
                )
                self.parentViewController.view.layoutIfNeeded()
            }
        } else {
            positionBars(
                horizontal: statusBarView,
                vertical: verticalStatusBarView,
                isLandscape: isLandscape,
                instructionsBanner: instructionsBanner
            )
        }

        // Ensure bars are in front
        parentViewController.view.bringSubviewToFront(statusBarView)
        parentViewController.view.bringSubviewToFront(verticalStatusBarView)
    }

    private func positionBars(
        horizontal: StatusBarView,
        vertical: VerticalStatusBarView,
        isLandscape: Bool,
        instructionsBanner: UIView?
    ) {

        horizontal.snp.remakeConstraints { make in
            make.height.equalTo(46)

            if let banner = instructionsBanner {
                make.top.equalTo(banner.snp.bottom).offset(8)
                bannerFrame = banner.frame
            } else {
                make.top.equalTo(parentViewController.view.safeAreaLayoutGuide.snp.top).offset(8)
            }

            if isLandscape {
                // Landscape: 40% width on left
                make.leading.equalToSuperview().offset(12)
                make.width.equalTo(parentViewController.view.snp.width).multipliedBy(0.4)
            } else {
                // Portrait: full width
                make.leading.equalToSuperview().offset(12)
                make.trailing.equalToSuperview().offset(-12)
            }
        }

        vertical.snp.remakeConstraints { make in

            make.width.equalTo(40)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(horizontal.snp.bottom).offset(8)
            make.bottom.equalTo(parentViewController.view.safeAreaLayoutGuide.snp.bottom).offset(-100)
        }
    }

    func checkForBannerChanges() -> Bool {
        if let banner = MapboxViewFinder.findInstructionsBanner(in: parentViewController),
           banner.frame != bannerFrame {
            return true
        }
        return false
    }
}
