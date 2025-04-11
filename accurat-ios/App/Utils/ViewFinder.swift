//
//  File.swift
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

// MARK: - Banner Finder
class MapboxViewFinder {

    static func findView<T: UIView>(ofType type: T.Type, in containerView: UIView?) -> T? {
        guard let containerView = containerView else { return nil }

        // Check if the container is the type we're looking for
        if let targetView = containerView as? T {
            return targetView
        }

        // Search first level
        for subview in containerView.subviews {
            if let targetView = subview as? T {
                return targetView
            }

            // Search second level (limited depth to avoid performance issues)
            for childView in subview.subviews {
                if let targetView = childView as? T {
                    return targetView
                }
            }
        }
        
        return nil
    }

//    static func findInstructionsBanner(in viewController: UIViewController) -> UIView? {
//        for subview in viewController.view.subviews {
//            if let bannerClass = NSClassFromString("MapboxNavigation.InstructionsBannerView"),
//               subview.isKind(of: bannerClass) {
//                return !subview.isHidden && subview.alpha > 0 ? subview : nil
//            }
//        }
//        return nil
//    }

    // Specific finder for InstructionsBannerView
    static func findInstructionsBanner(in viewController: UIViewController) -> InstructionsBannerView? {
        // Try to find in main view
        if let banner = findView(ofType: InstructionsBannerView.self, in: viewController.view) {
            return banner
        }

        // Check in child view controllers
        for child in viewController.children {
            if let banner = findView(ofType: InstructionsBannerView.self, in: child.view) {
                return banner
            }
        }

        return nil
    }
}
