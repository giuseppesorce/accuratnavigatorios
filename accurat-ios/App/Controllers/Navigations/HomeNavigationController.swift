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
        
        setupBothStatusBar()

        subscribeToRouteProgress()
        customizeUserLocationIcon()

        repositionAttributionButton()
        customizeMapControlIcons()

        InstructionsBannerView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).backgroundColor = .clear
    }
    
    static func createWithCustomBanner(for indexedRouteResponse: IndexedRouteResponse, navigationOptions: NavigationOptions?) -> HomeNavigationController {
          let options = navigationOptions ?? NavigationOptions()

          // Crea il custom bottom banner
//          let customBottomBanner = CustomBottomBannerViewController()
//          options.bottomBanner = customBottomBanner

          // Crea il navigation controller con le options personalizzate
          let navController = HomeNavigationController(for: indexedRouteResponse, navigationOptions: options)

          return navController
      }

    private func setupBothStatusBar() {
        let route = navigationService.route

        let sampleWaypoints = generateSamplePointsEvery50km(route: route)

        verticalStatusBarViewModel.setupWaypoints(waypoints: sampleWaypoints)

        if let location = navigationService.router.location?.coordinate {
            verticalStatusBarViewModel.updateUserLocation(
                userLocation: location,
                routeProgress: navigationService.routeProgress
            )
        }
    }

    private func customizeMapControlIcons() {
        navigationView.floatingButtons = []

        guard let floatingButtons = navigationView.floatingButtons else { return }
        for (index, button) in floatingButtons.enumerated() {
            if let floatingButton = button as? FloatingButton {
                // Customize mute button (second button)
                if index == 1 {
                    // Replace the mute button image with our custom images
                    floatingButton.setImage(UIImage(named: "icon_mute"), for: .normal)
                    floatingButton.setImage(UIImage(named: "icon_unmute"), for: .selected)
                }

                // Customize overview button (first button)
                if index == 0 {
                    floatingButton.setImage(UIImage(named: "icon_overview"), for: .normal)
                }

                // Customize report button (third button)
                if index == 2 {
                    floatingButton.setImage(UIImage(named: "icon_feedback"), for: .normal)
                }

                // Customize button appearance
                floatingButton.backgroundColor = .white
                floatingButton.tintColor = .black
                floatingButton.layer.shadowColor = UIColor.black.cgColor
                floatingButton.layer.shadowOffset = CGSize(width: 0, height: 2)
                floatingButton.layer.shadowOpacity = 0.3
                floatingButton.layer.shadowRadius = 2
            }
        }

        // Set the position of the floating buttons (if needed)
        // Options: .topLeading, .topTrailing, .bottomLeading, .bottomTrailing
        self.floatingButtonsPosition = .topTrailing
    }

    private func generateSamplePointsEvery50km(route: Route) -> [Waypoint] {
        var sampleWaypoints = [Waypoint]()

        // Utilizza la LineString del percorso completo da Route.shape
        guard let routeShape = route.shape else {
            print("Errore: impossibile ottenere la geometria del percorso")
            return []
        }

        let sampleDistanceInterval: Double = 50000 // 50km
        let totalRouteDistance = route.distance

        // Calcola il numero di campioni
        let numberOfSamples = Int(totalRouteDistance / sampleDistanceInterval)
        print("Totale distanza percorso: \(totalRouteDistance) metri")
        print("Numero di sample points: \(numberOfSamples)")

        // Se il percorso è troppo breve, restituisci una lista vuota
        if numberOfSamples <= 0 {
            return []
        }

        // Campiona punti lungo il percorso utilizzando Turf LineString
        for i in 1...numberOfSamples {
            let distanceAlongRoute = Double(i) * sampleDistanceInterval

            // Verifica che la distanza non superi la lunghezza totale
            if distanceAlongRoute < totalRouteDistance {
                // Ottieni le coordinate alla distanza specificata della LineString
                if let coordinateAtDistance = routeShape.coordinateFromStart(distance: distanceAlongRoute) {
                    print("Sample point \(i) a distanza \(distanceAlongRoute)m: \(coordinateAtDistance.latitude), \(coordinateAtDistance.longitude)")
                    let waypoint = Waypoint(coordinate: coordinateAtDistance)
                    sampleWaypoints.append(waypoint)
                }
            }
        }

        print("Sample waypoints generati: \(sampleWaypoints.count)")
        return sampleWaypoints
    }

    private func repositionAttributionButton() {
        guard let mapView = navigationMapView?.mapView else { return }

        var attributionOptions = mapView.ornaments.options.attributionButton
        attributionOptions.position = .bottomLeading
        attributionOptions.margins = CGPoint(x: 10, y: 10)

        //var compassOptions = mapView.ornaments.options.compass
        //compassOptions.visibility = .hidden
        //mapView.ornaments.options.compass = compassOptions
        mapView.ornaments.options.attributionButton = attributionOptions

        var logoOptions = mapView.ornaments.options.logo
        logoOptions.position = .bottomTrailing
        logoOptions.margins = CGPoint(x: 10, y: 10)
        mapView.ornaments.options.logo = logoOptions

        self.floatingButtonsPosition = .topLeading

        // Da approfondire, rompe il layout.
        //        if let speedLimitView = MapboxViewFinder.findSpeedLimitView(in: view) {
        //            speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        //            speedLimitView.superview?.constraints.forEach { constraint in
        //                if constraint.firstItem as? SpeedLimitView == speedLimitView || constraint.secondItem as? SpeedLimitView == speedLimitView {
        //                    constraint.isActive = false
        //                }
        //            }
        //            if let bannerView = MapboxViewFinder.findBottomBanner(in: self) {
        //                speedLimitView.snp.makeConstraints { make in
        //                    make.leading.equalTo(view.safeAreaLayoutGuide).offset(8)
        //                    make.bottom.equalTo(bannerView.snp.top).offset(-58)
        //                }
        //            }
        //        }
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
            setupBothStatusBar()
        }
    }

    @objc private func didUpdateProgress(_ notification: Notification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
              let location = navigationService.router.location?.coordinate else {
            return
        }

        if let firstSampleWaypoint = verticalStatusBarViewModel.activeWaypoints.first {
            // Usa direttamente la shape della route per calcolare la distanza
            if let shape = routeProgress.route.shape {
                // Ottieni la coordinata attuale lungo il percorso
                let userCoordinate = location
                let waypointCoordinate = firstSampleWaypoint.waypoint.coordinate

                // Trova il punto attuale del percorso
                if let closestUserPoint = shape.closestCoordinate(to: userCoordinate) {
                    // Trova il punto del waypoint sul percorso
                    if let closestWaypointPoint = shape.closestCoordinate(to: waypointCoordinate) {
                        // Calcola la distanza tra i due punti lungo il percorso
                        if let distanceToWaypoint = shape.distance(from: closestUserPoint.coordinate, to: closestWaypointPoint.coordinate) {
                            // Formatta la distanza
                            let formatter = DistanceFormatter()
                            let formattedDistance = formatter.string(from: distanceToWaypoint)
                            weatherViewModel.updateDistance(distance: formattedDistance)
                        }
                    }
                }
            }
        }

        // Calcola la distanza percorsa e definisci l'intervallo di aggiornamento
        let currentDistance = routeProgress.distanceTraveled
        let updateInterval: Double = 250  // in metri

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
