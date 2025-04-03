import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import CoreLocation

class HomeViewController: UIViewController {

    var navigationViewController: NavigationViewController?
    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocationPermissions()
        
        let navigationButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 100, width: view.bounds.width - 40, height: 50))
        navigationButton.backgroundColor = .systemBlue
        navigationButton.setTitle("Avvia Navigazione", for: .normal)
        navigationButton.layer.cornerRadius = 8
        navigationButton.addTarget(self, action: #selector(startNavigation), for: .touchUpInside)

        view.addSubview(navigationButton)
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
        guard let userLocation = locationManager.location?.coordinate else {
            print("Could not get user's current location");
            return
        }

        let destinationLocation = CLLocationCoordinate2D(latitude: userLocation.latitude + 0.05, longitude: userLocation.longitude + 0.05)

        // Create waypoints for origin and destination
        let origin = Waypoint(coordinate: userLocation, name: "Posizione attuale")
        let destination = Waypoint(coordinate: destinationLocation, name: "Destinazione")

        let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])

        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print("Error calculating route: \(error.localizedDescription)")

            case .success(let response):
                guard let strongSelf = self else {
                    return
                }

                let customNavigationViewController = CustomNavigationViewController(for: response, routeIndex: 0, routeOptions: routeOptions)
                customNavigationViewController.modalPresentationStyle = .fullScreen
                customNavigationViewController.delegate = strongSelf

                strongSelf.present(customNavigationViewController, animated: true, completion: nil)
                strongSelf.navigationViewController = customNavigationViewController
            }
        }
    }
}

extension HomeViewController: NavigationViewControllerDelegate {

    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        dismiss(animated: true, completion: nil)
        self.navigationViewController = nil
    }
}

extension HomeViewController: LocationPermissionsDelegate {

    func locationManager(_ locationManager: LocationManager, didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {

    }
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startNavigation();
        case .denied, .restricted:
            showLocationPermissionAlert()
        default:
            break
        }
    }
}
