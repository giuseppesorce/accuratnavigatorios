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

    private var statusBarController: StatusBarController?

    private let weatherViewModel = WeatherViewModel()
    private let verticalStatusBarViewModel = VerticalStatusBarViewModel()

    private var weatherUpdateTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        customizeRouteColors()

        DispatchQueue.main.async {
            self.setupComponents()
        }

        // Inizializza i waypoints per la barra di stato verticale
        setupVerticalStatusBar()

        subscribeToRouteProgress()
        customizeUserLocationIcon()

        repositionAttributionButton()
    }

    private func setupVerticalStatusBar() {
        let route = navigationService.route
        // Estrai i waypoint dalla route
        let waypoints = route.legs.map { $0.destination! }

        // Se abbiamo un punto di partenza, aggiungiamolo all'inizio
        var allWaypoints = waypoints
        if let origin = route.legs.first?.source {
            allWaypoints.insert(origin, at: 0)
        }

        // Inizializza il viewmodel con i waypoint
        verticalStatusBarViewModel.setupWaypoints(waypoints: allWaypoints)

        // Aggiorna subito le condizioni per la posizione attuale
        if let location = navigationService.router.location?.coordinate {
            verticalStatusBarViewModel.updateUserLocation(
                userLocation: location,
                routeProgress: navigationService.routeProgress
            )
        }
    }

    private func repositionAttributionButton() {
        guard let mapView = navigationMapView?.mapView else { return }

        var attributionOptions = mapView.ornaments.options.attributionButton
        attributionOptions.position = .bottomLeading
        attributionOptions.margins = CGPoint(x: 10, y: 10)

        //        var compassOptions = mapView.ornaments.options.compass
        //        compassOptions.visibility = .hidden
        //        mapView.ornaments.options.compass = compassOptions
        mapView.ornaments.options.attributionButton = attributionOptions

        var logoOptions = mapView.ornaments.options.logo
        logoOptions.position = .bottomTrailing
        logoOptions.margins = CGPoint(x: 10, y: 10)
        mapView.ornaments.options.logo = logoOptions

        self.floatingButtonsPosition = .topLeading

        if let speedLimitView = MapboxViewFinder.findSpeedLimitView(in: view) {
            speedLimitView.translatesAutoresizingMaskIntoConstraints = false
            speedLimitView.superview?.constraints.forEach { constraint in
                if constraint.firstItem as? SpeedLimitView == speedLimitView || constraint.secondItem as? SpeedLimitView == speedLimitView {
                    constraint.isActive = false
                }
            }
            if let bannerView = MapboxViewFinder.findBottomBanner(in: self) {
                speedLimitView.snp.makeConstraints { make in
                    make.leading.equalTo(view.safeAreaLayoutGuide).offset(8)
                    make.bottom.equalTo(bannerView.snp.top).offset(-58)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        statusBarController?.updatePosition()
        startWeatherUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stopWeatherUpdates()
        verticalStatusBarViewModel.stopUpdates()
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
        statusBarController = StatusBarController(parent: self,
                                                  viewModel: weatherViewModel,
                                                  verticalViewModel: verticalStatusBarViewModel)
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

            // Quando la rotta viene ricalcolata, aggiorna anche i waypoint per la barra verticale
            setupVerticalStatusBar()
        }
    }

    @objc private func didUpdateProgress(_ notification: Notification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
              let location = navigationService.router.location?.coordinate else {
            return
        }
        // DEBUG - ON
        verticalStatusBarViewModel.updateUserLocation(
            userLocation: location,
            routeProgress: routeProgress
        )
        
        // Aggiorna la distanza rimanente
        let formatter = DistanceFormatter()
        let distanceRemaining = formatter.string(from: routeProgress.distanceRemaining)
        weatherViewModel.updateDistance(distance: distanceRemaining)

        // Calcola la distanza percorsa e definisci l'intervallo di aggiornamento
        let currentDistance = routeProgress.distanceTraveled
        let updateInterval = 5000.0  // 5 chilometri in metri

        // Controlla se è il momento di aggiornare in base alla distanza percorsa
        if abs(currentDistance.truncatingRemainder(dividingBy: updateInterval)) < 100 {
            // Aggiorna prima la posizione dell'utente
            verticalStatusBarViewModel.updateUserLocation(
                userLocation: location,
                routeProgress: routeProgress
            )
            // Poi verifica e aggiorna il meteo se necessario
            verticalStatusBarViewModel.checkAndUpdateWeatherIfNeeded()
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
