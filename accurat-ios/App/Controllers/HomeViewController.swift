import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import CoreLocation

class HomeViewController: UIViewController {

    var navigationViewController: NavigationViewController?
    var locationManager = CLLocationManager()

    // Aggiunta del flag per abilitare la simulazione
    var useSimulation = false

    lazy var bikeGpxWaypoints: [Waypoint] = {
        return [
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.8313835, longitude: 10.8708131), name: "Fossoli Nord"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.8413835, longitude: 10.8758131), name: "Budrione"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.8513835, longitude: 10.8738131), name: "Migliarina"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.7913835, longitude: 10.8138131), name: "Modena Nord"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.9813835, longitude: 10.9338131), name: "Mirandola Centro"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.8063835, longitude: 10.7358131), name: "Campogalliano"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 45.0113835, longitude: 10.8958131), name: "San Felice"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.7713835, longitude: 10.9758131), name: "Bastiglia"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.9513835, longitude: 10.7258131), name: "Reggiolo"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: 44.8163835, longitude: 11.0258131), name: "Finale Emilia")
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocationPermissions()
        
        // Aggiungiamo il bottone per la navigazione normale
        let navigationButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 150, width: view.bounds.width - 40, height: 50))
        navigationButton.backgroundColor = .systemBlue
        navigationButton.setTitle("Avvia Navigazione", for: .normal)
        navigationButton.layer.cornerRadius = 8
        navigationButton.addTarget(self, action: #selector(startNavigation), for: .touchUpInside)

        // Aggiungiamo il bottone per la simulazione
        let simulationButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 90, width: view.bounds.width - 40, height: 50))
        simulationButton.backgroundColor = .systemGreen
        simulationButton.setTitle("Avvia Simulazione", for: .normal)
        simulationButton.layer.cornerRadius = 8
        simulationButton.addTarget(self, action: #selector(startSimulation), for: .touchUpInside)

        view.addSubview(navigationButton)
        view.addSubview(simulationButton)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.startSimulation()
        }
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

    // Nuovo metodo per avviare la simulazione
    @objc func startSimulation() {
        useSimulation = true
        startNavigationProcess()
    }

    @objc func startNavigation() {
        useSimulation = false
        startNavigationProcess()
    }

    // Metodo comune per il processo di navigazione
    func startNavigationProcess() {
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                CLLocationManager.authorizationStatus() == .authorizedAlways else {
            showLocationPermissionAlert()
            return
        }
        let startingPoint: CLLocationCoordinate2D

        if useSimulation {
            startingPoint = bikeGpxWaypoints.first!.coordinate
        } else {
            guard let userLocation = locationManager.location?.coordinate else {
                print("Could not get user's current location")
                return
            }
            startingPoint = userLocation
        }

        var waypointsToUse = bikeGpxWaypoints

        if !useSimulation {
            waypointsToUse.insert(Waypoint(coordinate: startingPoint, name: "Posizione attuale"), at: 0)
        }

        let coordinates = waypointsToUse.map { $0.coordinate }

        let routeOptions = NavigationRouteOptions(waypoints: waypointsToUse, profileIdentifier: .cycling)
        routeOptions.includesSteps = true
        routeOptions.routeShapeResolution = .full
        routeOptions.includesAlternativeRoutes = false

        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print("Error calculating route: \(error.localizedDescription)")

            case .success(let response):
                guard let strongSelf = self else {
                    return
                }
                let indexedResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)


                if strongSelf.useSimulation {
                    let navigationOptions = NavigationOptions()
                    navigationOptions.simulationMode = strongSelf.useSimulation ? .always : .never
                    
                    let customNavigationViewController = HomeNavigationController(
                        for: indexedResponse,
                        navigationOptions: navigationOptions
                    )
                    
                    customNavigationViewController.modalPresentationStyle = .fullScreen
                    customNavigationViewController.delegate = strongSelf

                    if strongSelf.useSimulation && customNavigationViewController.navigationService != nil {
                        customNavigationViewController.navigationService.simulationSpeedMultiplier = 3.0
                    }

                    strongSelf.present(customNavigationViewController, animated: true, completion: nil)
                    strongSelf.navigationViewController = customNavigationViewController
                } else {
                    let customNavigationViewController = HomeNavigationController(
                        for: indexedResponse,
                        navigationOptions: nil
                    )
                    customNavigationViewController.modalPresentationStyle = .fullScreen
                    customNavigationViewController.delegate = strongSelf

                    strongSelf.present(customNavigationViewController, animated: true, completion: nil)
                    strongSelf.navigationViewController = customNavigationViewController
                }
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
            // Non avviamo automaticamente la navigazione all'autorizzazione
            // perché ora abbiamo due opzioni (normale e simulazione)
            break
        case .denied, .restricted:
            showLocationPermissionAlert()
        default:
            break
        }
    }
}
