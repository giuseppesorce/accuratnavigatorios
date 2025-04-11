import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import CoreLocation

class HomeViewController: UIViewController {

    var navigationViewController: NavigationViewController?
    var locationManager = CLLocationManager()

//    lazy var gpxWaypoints: [Waypoint] = {
//          return [
//              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.93217600, longitude: 10.91521400), name: "Punto 1"),
//              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.92917300, longitude: 10.91555200), name: "Punto 12"),
//              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.94046900, longitude: 10.94358100), name: "Punto 12"),
//          ]
//      }()
    
//    lazy var appleGpxWaypoints: [Waypoint] = {
//          return [
//              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.33172861, longitude: -122.03068446), name: "Punto 1"),
//              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.33084313, longitude: -122.03058427), name: "Punto 2"),
//           ]
//      }()

    lazy var bikeGpxWaypoints: [Waypoint] = {
          return [
              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.8213835, longitude: 10.8808131), name: "Fossoli"),
              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.875632, longitude: 10.853933), name: "Rolo"),
              Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.9340683, longitude: 10.9129489), name: "Casa"),
          ]
      }()

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

        var waypointsToUse = bikeGpxWaypoints

        waypointsToUse.insert(Waypoint(coordinate: userLocation, name: "Posizione attuale"), at: 0)

        let routeOptions = NavigationRouteOptions(waypoints: waypointsToUse, profileIdentifier: .cycling)
        routeOptions.includesAlternativeRoutes = false

        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print("Error calculating route: \(error.localizedDescription)")

            case .success(let response):
                guard let strongSelf = self else {
                    return
                }
                
                let customNavigationViewController = HomeNavigationController(for: response, routeIndex: 0, routeOptions: routeOptions)
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
            break
        case .denied, .restricted:
            showLocationPermissionAlert()
        default:
            break
        }
    }
}
