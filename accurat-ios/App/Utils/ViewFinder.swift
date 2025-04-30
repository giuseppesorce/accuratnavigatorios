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

    static func findNextBanner(in viewController: UIViewController) -> NextBannerView? {
          // First try to find the InstructionsBanner
          if let instructionsBanner = findInstructionsBanner(in: viewController) {
              // Then look for the NextBannerView within it
              if let nextBanner = findView(ofType: NextBannerView.self, in: instructionsBanner) {
                  return nextBanner
              }
          }

          // If not found, try a broader search
          if let nextBanner = findView(ofType: NextBannerView.self, in: viewController.view) {
              return nextBanner
          }

          // Check in child view controllers
          for child in viewController.children {
              if let nextBanner = findView(ofType: NextBannerView.self, in: child.view) {
                  return nextBanner
              }
          }

          return nil
      }

    
    static func findBottomPaddingViewBanner(in viewController: UIViewController) -> BottomPaddingView? {
        // Try to find in main view
        if let banner = findView(ofType:  BottomPaddingView.self, in: viewController.view) {
            return banner
        }

        // Check in child view controllers
        for child in viewController.children {
            if let banner = findView(ofType: BottomPaddingView.self, in: child.view) {
                return banner
            }
        }

        return nil
    }

    // Helper function to find SpeedLimitView in view hierarchy
    static func findSpeedLimitView(in view: UIView) -> SpeedLimitView? {
        if let speedLimitView = view as? SpeedLimitView {
            return speedLimitView
        }
        for subview in view.subviews {
            if let found = findSpeedLimitView(in: subview) {
                return found
            }
        }
        return nil
    }

    // Aggiungiamo questo metodo alla classe MapboxViewFinder
    static func findBottomPaddingView(in viewController: UIViewController) -> UIView? {
        // Cerca in modo ricorsivo la vista che contiene "BottomPaddingView" nel nome della classe
        return findViewWithClassNameContaining("BottomPaddingView", in: viewController.view)
    }

    // Funzione di utility per trovare una vista in base al nome parziale della classe
    static func findViewWithClassNameContaining(_ className: String, in view: UIView?) -> UIView? {
        guard let view = view else { return nil }

        // Controlla se il nome della classe della vista corrente contiene la stringa cercata
        let viewClassName = String(describing: type(of: view))
        if viewClassName.contains(className) {
            return view
        }

        // Cerca nelle sottoviste
        for subview in view.subviews {
            if let found = findViewWithClassNameContaining(className, in: subview) {
                return found
            }
        }

        return nil
    }
}
