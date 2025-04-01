import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import CoreLocation

class ViewController: UIViewController {

    var mapView: MapView!
    var navigationViewController: NavigationViewController?
    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocationPermissions()

        mapView = MapView(frame: view.bounds)
        let cameraOptions = CameraOptions(center:
            CLLocationCoordinate2D(latitude: 39.5, longitude: -98.0),
            zoom: 2, bearing: 0, pitch: 0)
        mapView.mapboxMap.setCamera(to: cameraOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let navigationButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 100, width: view.bounds.width - 40, height: 50))
        navigationButton.backgroundColor = .systemBlue
        navigationButton.setTitle("Avvia Navigazione", for: .normal)
        navigationButton.layer.cornerRadius = 8
        navigationButton.addTarget(self, action: #selector(startNavigation), for: .touchUpInside)

        view.addSubview(mapView)
        view.addSubview(navigationButton)

        mapView.location.delegate = self
        mapView.location.options.puckType = .puck2D()
//        mapView.location.locationProvider = AppleLocationProvider()
        mapView.location.options.puckBearingSource = .heading

        mapView.location.options.puckType = .puck2D()
        try? mapView.location.locationProvider?.startUpdatingLocation()
    }

    func setupLocationPermissions() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Permesso di localizzazione richiesto",
            message: "Per utilizzare la navigazione, è necessario abilitare la localizzazione nelle impostazioni.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Impostazioni", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))

        present(alert, animated: true)
    }

    @objc func startNavigation() {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
              CLLocationManager.authorizationStatus() == .authorizedAlways else {
            showLocationPermissionAlert()
            return
        }

        guard let userLocation = mapView.location.latestLocation?.coordinate else {
            return
        }

        let destinationLocation = CLLocationCoordinate2D(latitude: userLocation.latitude + 0.05, longitude: userLocation.longitude + 0.05)

        // Create waypoints for origin and destination
        let origin = Waypoint(coordinate: userLocation, name: "Posizione attuale")
        let destination = Waypoint(coordinate: destinationLocation, name: "Destinazione")

        // Set options using NavigationRouteOptions
        let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])

        // Request a route using MapboxDirections
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print("Error calculating route: \(error.localizedDescription)")

            case .success(let response):
                guard let strongSelf = self else {
                    return
                }

                // Pass the generated route response directly to the NavigationViewController
                let viewController = NavigationViewController(for: response, routeIndex: 0, routeOptions: routeOptions)
                viewController.modalPresentationStyle = .fullScreen
                viewController.delegate = strongSelf

                strongSelf.present(viewController, animated: true, completion: nil)
                strongSelf.navigationViewController = viewController
            }
        }
    }
}

extension ViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
        self.navigationViewController = nil
    }
}

extension ViewController: LocationPermissionsDelegate {
    func locationManager(_ locationManager: LocationManager, didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.location.options.puckType = .puck2D()
            try? mapView.location.locationProvider?.startUpdatingLocation()
        case .denied, .restricted:
            showLocationPermissionAlert()
        default:
            break
        }
    }
}
