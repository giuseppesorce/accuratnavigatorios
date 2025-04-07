//
//  StatusbarVC.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 03/04/25.
//
import Foundation
import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import SwiftUI
import Combine

import UIKit
import MapboxNavigation
import SnapKit

class NavigationStatusBarController {
    private var statusBarView: StatusBarView?
    private var parentViewController: UIViewController
    private var viewModel: StatusBarViewModel
    private var bannerFrame: CGRect = .zero

    init(parent: UIViewController, viewModel: StatusBarViewModel) {
        self.parentViewController = parent
        self.viewModel = viewModel
    }

    func setup() {
        let statusBar = StatusBarView(viewModel: viewModel)
        statusBarView = statusBar

        parentViewController.view.addSubview(statusBar)
        updatePosition()
    }

    func updatePosition() {
        guard let statusBarView = statusBarView else { return }

        let isLandscape = UIDevice.current.orientation.isLandscape
        let instructionsBanner = MapboxViewFinder.findInstructionsBanner(in: parentViewController)

        statusBarView.snp.remakeConstraints { make in
            make.height.equalTo(44)

            if let banner = instructionsBanner {
                // Position below instructions banner
                make.top.equalTo(banner.snp.bottom).offset(8)
                bannerFrame = banner.frame
            }

            if isLandscape {
                // Landscape: 40% width on left
                make.leading.equalToSuperview().inset(-8)
                make.width.equalTo(parentViewController.view.snp.width).multipliedBy(0.4)
            } else {
                // Portrait: full width
                make.leading.equalToSuperview().offset(12)
                make.trailing.equalToSuperview().offset(-12)
            }
        }

        parentViewController.view.bringSubviewToFront(statusBarView)
    }

    func checkForBannerChanges() -> Bool {
        if let banner = MapboxViewFinder.findInstructionsBanner(in: parentViewController),
           banner.frame != bannerFrame {
            return true
        }
        return false
    }
}

//
//class NavigationStatusBarController {
//    
//    private var hostingController: UIHostingController<StatusBarView>?
//    private var parentViewController: UIViewController
//    private var viewModel: StatusBarViewModel
//    private var bannerFrame: CGRect = .zero
//
//    init(parent: UIViewController, viewModel: StatusBarViewModel) {
//        self.parentViewController = parent
//        self.viewModel = viewModel
//    }
//
//    func setup() {
//        let statusBar = UIHostingController(
//            rootView: StatusBarView(
//                weatherStatus: viewModel.weatherStatus,
//                distanceInfo: viewModel.distanceInfo,
//                humidityPercentage: viewModel.humidityPercentage
//            )
//        )
//
//        hostingController = statusBar
//        statusBar.view.backgroundColor = .clear
//
//        parentViewController.addChild(statusBar)
//        parentViewController.view.addSubview(statusBar.view)
//        statusBar.didMove(toParent: parentViewController)
//
//        updatePosition()
//    }
//
//    func updateContent() {
//        hostingController?.rootView = StatusBarView(
//            weatherStatus: viewModel.weatherStatus,
//            distanceInfo: viewModel.distanceInfo,
//            humidityPercentage: viewModel.humidityPercentage
//        )
//    }
//
//    func updatePosition() {
//        guard let statusBarView = hostingController?.view else { return }
//
//        let isLandscape = UIDevice.current.orientation.isLandscape
//        let instructionsBanner = MapboxViewFinder.findInstructionsBanner(in: parentViewController)
//
//        statusBarView.snp.remakeConstraints { make in
//            make.height.equalTo(44)
//
//            if let banner = instructionsBanner {
//                // Position below instructions banner
//                make.top.equalTo(banner.snp.bottom).offset(8)
//                bannerFrame = banner.frame
//            }
//
//            if isLandscape {
//                // Landscape: 40% width on left
//                make.leading.equalToSuperview().inset(-8) // .offset(12)
//                make.width.equalTo(parentViewController.view.snp.width).multipliedBy(0.4)
//            } else {
//                // Portrait: full width
//                make.leading.equalToSuperview().offset(12)
//                make.trailing.equalToSuperview().offset(-12)
//            }
//        }
//        parentViewController.view.bringSubviewToFront(statusBarView)
//    }
//
//    func checkForBannerChanges() -> Bool {
//        if let banner = MapboxViewFinder.findInstructionsBanner(in: parentViewController),
//           banner.frame != bannerFrame {
//            return true
//        }
//        return false
//    }
//}
