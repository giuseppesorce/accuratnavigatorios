//
//  VerticalStatusBarViewModel.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 07/04/25.
//

import Foundation
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import Combine

class VerticalStatusBarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var waypointWeatherConditions: [Int: WeatherCondition] = [:]
    @Published var activeWaypoints: [WaypointInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let weatherService = XWeatherService()
    private var weatherUpdateTimer: Timer?
    private let maxWaypoints = 6
    private var allWaypoints: [WaypointInfo] = []
    private var lastWeatherUpdateTime: Date = Date.distantPast
    private let weatherUpdateInterval: TimeInterval = 600

    // MARK: - Types
    struct WaypointInfo: Identifiable {
        let id = UUID()
        let index: Int
        let waypoint: Waypoint
        var isPassed: Bool = false
    }

    // MARK: - Public Methods
    func setupWaypoints(waypoints: [Waypoint]) {
        // Utilizziamo i waypoint forniti da HomeViewController
        allWaypoints = waypoints.enumerated().map { index, waypoint in
            WaypointInfo(index: index, waypoint: waypoint, isPassed: false)
        }

        // Inizializza i waypoint attivi
        updateActiveWaypoints()

        // Aggiorna immediatamente le condizioni meteo
        fetchWeatherForActiveWaypoints()

        // Imposta il timer per gli aggiornamenti periodici
        startWeatherUpdateTimer()
    }

    func updateUserLocation(userLocation: CLLocationCoordinate2D, routeProgress: RouteProgress) {
        // Determina quali waypoint sono stati superati
        updateWaypointPassedStatus(userLocation: userLocation, routeProgress: routeProgress)

        // Aggiorna la lista dei waypoint attivi
        updateActiveWaypoints()
    }

    func stopUpdates() {
        weatherUpdateTimer?.invalidate()
        weatherUpdateTimer = nil
    }

    // MARK: - Private Methods
    private func updateActiveWaypoints() {
        // Filtra i waypoint non ancora superati
        let nonPassedWaypoints = allWaypoints.filter { !$0.isPassed }

        // Prendi solo i primi maxWaypoints
        activeWaypoints = Array(nonPassedWaypoints.prefix(maxWaypoints))

        // Se ci sono più waypoint di quelli che possiamo mostrare, assicuriamoci
        // che l'ultimo waypoint attivo non sia la destinazione finale (a meno che non sia l'unico rimasto)
        if nonPassedWaypoints.count > maxWaypoints && activeWaypoints.count == maxWaypoints {
            if let lastWaypointIndex = activeWaypoints.last?.index,
               lastWaypointIndex == allWaypoints.last?.index {
                // Rimuovi l'ultimo waypoint (la destinazione) e aggiungi quello precedente nell'elenco
                activeWaypoints.removeLast()
                if let nextWaypoint = nonPassedWaypoints.dropFirst(maxWaypoints - 1).first {
                    activeWaypoints.append(nextWaypoint)
                }
            }
        }
    }
    
    private func updateWaypointPassedStatus(userLocation: CLLocationCoordinate2D, routeProgress: RouteProgress) {
        // Per ogni waypoint, verifichiamo se è stato superato
        for i in 0..<allWaypoints.count {
            // Calcola la distanza tra la posizione dell'utente e il waypoint
            let waypointCoordinate = allWaypoints[i].waypoint.coordinate
            let waypointLocation = CLLocation(latitude: waypointCoordinate.latitude,
                                             longitude: waypointCoordinate.longitude)
            let userLoc = CLLocation(latitude: userLocation.latitude,
                                     longitude: userLocation.longitude)
            let distance = userLoc.distance(from: waypointLocation)

            // Segna come superato se l'utente è a meno di 50 metri dal waypoint o l'ha già passato
            if distance < 50 || allWaypoints[i].isPassed {
                allWaypoints[i].isPassed = true
            }
        }
    }

    private func startWeatherUpdateTimer() {
        // Prima fermiamo eventuali timer esistenti
        stopUpdates()

        // Creiamo un nuovo timer che aggiorna il meteo ogni 10 minuti
        weatherUpdateTimer = Timer.scheduledTimer(withTimeInterval: weatherUpdateInterval, repeats: true) { [weak self] _ in
            self?.fetchWeatherForActiveWaypoints()
        }

        // Aggiunge il timer al RunLoop corrente per assicurarsi che funzioni correttamente
        if let timer = weatherUpdateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func fetchWeatherForActiveWaypoints() {
        // Aggiorna il timestamp dell'ultimo aggiornamento
        lastWeatherUpdateTime = Date()

        // Evita aggiornamenti se non ci sono waypoint attivi
        guard !activeWaypoints.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        // Crea un gruppo di dispatch per gestire le richieste multiple
        let group = DispatchGroup()

        // Per ogni waypoint attivo, aggiorna le condizioni meteo
        for waypoint in activeWaypoints {
            group.enter()

            weatherService.fetchWeatherConditions(for: waypoint.waypoint.coordinate) { [weak self] result in
                defer { group.leave() }

                DispatchQueue.main.async {
                    guard let self = self else { return }

                    switch result {
                    case .success(let weather):
                        self.waypointWeatherConditions[waypoint.index] = weather
                    case .failure(let error):
                        print("Errore nel recupero meteo per waypoint \(waypoint.index): \(error.localizedDescription)")
                        // Memorizza solo il primo errore riscontrato
                        if self.errorMessage == nil {
                            self.errorMessage = "Meteo: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }

        // Quando tutte le richieste sono completate
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    // Metodo per forzare un aggiornamento del meteo se è passato troppo tempo
    func checkAndUpdateWeatherIfNeeded() {
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastWeatherUpdateTime) >= weatherUpdateInterval {
            fetchWeatherForActiveWaypoints()
        }
    }
}
