import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import SwiftUI
import Combine
import SnapKit
import Foundation
import MapboxMaps

// MARK: - Updated Navigation Controller
class HomeNavigationController: NavigationViewController {

    private var statusBarController: NavigationStatusBarController?

    private let weatherViewModel = WeatherViewModel()
    private var weatherUpdateTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        customizeRouteColors()

        DispatchQueue.main.async {
            self.setupComponents()
        }

        subscribeToRouteProgress()
        customizeUserLocationIcon()

        repositionAttributionButton()
    }

    private func repositionAttributionButton() {
        // Check if navigation map view is initialized
        guard let mapView = navigationMapView?.mapView else { return }

        // Configure the attribution button position
        // The options are: .topLeft, .topRight, .bottomLeft, .bottomRight,
        // .topLeading, .topTrailing, .bottomLeading, .bottomTrailing

        // For text direction independence, use the Leading/Trailing variants
        var attributionOptions = mapView.ornaments.options.attributionButton
        attributionOptions.position = .bottomLeading // Move to bottom left
        attributionOptions.margins = CGPoint(x: 10, y: 10) // Set margins

        // Apply the updated options
        mapView.ornaments.options.attributionButton = attributionOptions

        // Hide the compass since we don't need it with our custom UI
        var compassOptions = mapView.ornaments.options.compass
        compassOptions.visibility = .hidden
        mapView.ornaments.options.compass = compassOptions

        // Hide the scale bar which might interfere with our vertical status bar
        var scaleBarOptions = mapView.ornaments.options.scaleBar
        scaleBarOptions.visibility = .hidden
        mapView.ornaments.options.scaleBar = scaleBarOptions

        // Adjust the logo position if needed
        var logoOptions = mapView.ornaments.options.logo
        logoOptions.position = .bottomTrailing // Move to bottom right
        logoOptions.margins = CGPoint(x: 10, y: 10)
        mapView.ornaments.options.logo = logoOptions

        self.floatingButtonsPosition = .topLeading
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        statusBarController?.updatePosition()
        startWeatherUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopWeatherUpdates()
    }

    private func customizeUserLocationIcon() {
        let customPuckImage = UIImage(named: "user_gps")
        let smallScale = MapboxMaps.Value<Double>.constant(0.1)

        let puckConfiguration = Puck2DConfiguration(
            topImage: customPuckImage,
            bearingImage: customPuckImage,
            shadowImage: nil,
            scale: smallScale,
            showsAccuracyRing: true
        )
        navigationMapView?.userLocationStyle = .puck2D(configuration: puckConfiguration)
    }

    private func customizeRouteColors() {
        let yellowColor = UIColor(red: 249/255.0, green: 202/255.0, blue: 28/255.0, alpha: 1.0)
        let lightGrayColor = UIColor.lightGray

        navigationMapView?.trafficUnknownColor = yellowColor
        navigationMapView?.trafficLowColor = yellowColor
        navigationMapView?.trafficModerateColor = yellowColor
        navigationMapView?.trafficHeavyColor = yellowColor
        navigationMapView?.trafficSevereColor = yellowColor

        navigationMapView?.routeCasingColor = .black

        navigationMapView?.routeAlternateColor = .lightGray
        navigationMapView?.routeAlternateCasingColor = .darkGray

        navigationMapView?.traversedRouteColor = lightGrayColor
        navigationMapView?.routeLineTracksTraversal = true

        let route = navigationService.route
        navigationMapView?.show([route], legIndex:navigationService.routeProgress.legIndex)
    }

    private func setupComponents() {
        statusBarController = NavigationStatusBarController(parent: self,
                                                            viewModel: weatherViewModel)
        statusBarController?.setup()
    }

    private func startWeatherUpdates() {
        updateWeatherForCurrentLocation()

        weatherUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1000, repeats: true) { [weak self] _ in
            self?.updateWeatherForCurrentLocation()
        }
    }

    private func stopWeatherUpdates() {
        weatherUpdateTimer?.invalidate()
        weatherUpdateTimer = nil
    }

    private func updateWeatherForCurrentLocation() {
        guard let location = navigationService.router.location?.coordinate else { return }

        weatherViewModel.updateConditions(at: location)
    }

    private func subscribeToRouteProgress() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUpdateRoute(_:)),
            name: .routeControllerDidReroute,
            object: navigationService.router
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUpdateProgress(_:)),
            name: .routeControllerProgressDidChange,
            object: navigationService.router
        )
    }

    @objc private func didUpdateRoute(_ notification: Notification) {
        if let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress {
            weatherViewModel.updateRouteRoadConditions(for: routeProgress.route)
        }
    }

    @objc private func didUpdateProgress(_ notification: Notification) {
        if let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress {

            let currentDistance = routeProgress.distanceTraveled
            let updateInterval = 5000.0  // 5 kilometers in meters

            //            if currentDistance.truncatingRemainder(dividingBy: updateInterval) < 100 {
            //                updateWeatherForCurrentLocation()
            //            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.statusBarController?.updatePosition(animated: true)
        }, completion: { _ in
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
