import Foundation
import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import SwiftUI
import Combine
import SnapKit

class StatusBarController {
    // View components
    private var statusBarView: StatusBarView?
    private var verticalStatusBarView: VerticalStatusBarView?

    // Controllers
    private var parentViewController: UIViewController
    private var weatherViewModel: WeatherViewModel
    private var verticalViewModel: VerticalStatusBarViewModel

    private var navigationService: NavigationDistanceService?

    // State tracking
    private var bannerFrame: CGRect = .zero

    init(parent: UIViewController,
         viewModel: WeatherViewModel,
         verticalViewModel: VerticalStatusBarViewModel) {
        
        self.parentViewController = parent
        self.verticalViewModel = verticalViewModel
        self.weatherViewModel = viewModel
    }

    func setup() {
        // Crea la StatusBarView principale
        let statusBar = StatusBarView(weatherViewModel: weatherViewModel,
                                      showDistance: true)

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

        if let bottomPaddingView = MapboxViewFinder.findBottomPaddingView(in: parentViewController) {
            let embeddedStatusBar = StatusBarView(weatherViewModel: weatherViewModel,
                                                  showDistance: false)
            bottomPaddingView.addSubview(embeddedStatusBar)

            embeddedStatusBar.snp.makeConstraints { make in
                make.height.equalTo(46)
                make.leading.equalToSuperview().offset(12)
                make.trailing.equalToSuperview().offset(-12)
                make.top.equalToSuperview().offset(-20)
            }
        }
        updatePosition(animated: false)
    }

    func updatePosition(animated: Bool = false) {
        guard let statusBarView = statusBarView,
              let verticalStatusBarView = verticalStatusBarView else { return }

        let isLandscape = UIDevice.current.orientation.isLandscape
        let nextBannerView = MapboxViewFinder.findNextBanner(in: parentViewController)

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.positionBars(
                    horizontal: statusBarView,
                    vertical: verticalStatusBarView,
                    isLandscape: isLandscape,
                    nextBannerView: nextBannerView
                )
                self.parentViewController.view.layoutIfNeeded()
            }
        } else {
            positionBars(
                horizontal: statusBarView,
                vertical: verticalStatusBarView,
                isLandscape: isLandscape,
                nextBannerView: nextBannerView
            )
        }
        parentViewController.view.bringSubviewToFront(statusBarView)
        parentViewController.view.bringSubviewToFront(verticalStatusBarView)
    }

    private func positionBars(
        horizontal: StatusBarView,
        vertical: VerticalStatusBarView,
        isLandscape: Bool,
        nextBannerView: UIView?
    ) {

        horizontal.snp.remakeConstraints { make in
            make.height.equalTo(46)

            if let banner = nextBannerView {
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
