//
//  NavigationService.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 03/04/25.
//

import Foundation
import UIKit
import SwiftUI
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Combine

class NavigationService {
    private var cancellables = Set<AnyCancellable>()
    private weak var viewModel: StatusBarViewModel?

    init(viewModel: StatusBarViewModel) {
        self.viewModel = viewModel
    }

    func startObserving() {
        NotificationCenter.default.publisher(for: .routeControllerProgressDidChange)
            .compactMap { notification -> RouteProgress? in
                return notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
            }
            .sink { [weak self] progress in
                guard let viewModel = self?.viewModel else { return }

                let formatter = DistanceFormatter()
                let distance = formatter.string(from: progress.distanceRemaining)
                viewModel.updateDistance(distance: "In \(distance)")
            }
            .store(in: &cancellables)
    }
}
