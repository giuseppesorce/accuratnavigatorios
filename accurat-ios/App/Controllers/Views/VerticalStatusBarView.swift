import UIKit
import SnapKit
import Combine
import MapboxDirections

class VerticalStatusBarView: UIView {
    // MARK: - UI Elements
    private let topLocationIcon = UIImageView()
    private let verticalLine = UIView()
    private let warningContainer = UIView()
    private let warningIcon = UIImageView()
    private let bottomContainer = UIView()
    private let bottomIconView = UIImageView()

    // MARK: - Properties
    private var viewModel: VerticalStatusBarViewModel
    private var weatherContainerViews: [UIView] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(viewModel: VerticalStatusBarViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        bindViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        // Osserva i cambiamenti nei waypoint attivi
        viewModel.$activeWaypoints
            .receive(on: DispatchQueue.main)
            .sink { [weak self] waypoints in
                self?.updateWeatherPointsWithWaypoints(waypoints)
            }
            .store(in: &cancellables)

        // Osserva i cambiamenti nelle condizioni meteo
        viewModel.$waypointWeatherConditions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conditions in
                self?.updateWeatherIcons(with: conditions)
            }
            .store(in: &cancellables)

        // Osserva lo stato di caricamento
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)

        // Osserva gli errori
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    print("Errore nella barra verticale: \(error)")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Top location icon (directly on the view)
        setupTopLocationIcon()

        // Main vertical line
        setupVerticalLine()

        // Warning container (orange)
        setupWarningContainer()

        // Setup bottom navigation indicator
        setupBottomContainer()

        // Create initial weather points (up to 6 maximum)
        setupWeatherPoints(count: 6)

        setupConstraints()
    }

    private func setupTopLocationIcon() {
        // Location icon directly on main view
        topLocationIcon.image = UIImage(named: "location")
        topLocationIcon.tintColor = UIStyleKit.Colors.textWhite
        topLocationIcon.contentMode = .scaleAspectFit
        topLocationIcon.backgroundColor = UIColor.clear
        topLocationIcon.layer.cornerRadius = 20
        topLocationIcon.clipsToBounds = true

        // Add shadows
        topLocationIcon.layer.shadowColor = UIStyleKit.Colors.weatherYellowShadow.cgColor
        topLocationIcon.layer.shadowOffset = CGSize(width: 0, height: 0)
        topLocationIcon.layer.shadowRadius = 5.53
        topLocationIcon.layer.shadowOpacity = 1.0

        addSubview(topLocationIcon)

        // Add inner shadow after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIStyleKit.addInnerShadow(
                to: self.topLocationIcon,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 2.76,
                offset: CGSize(width: 0, height: 1.38)
            )
        }
    }

    private func setupVerticalLine() {
        verticalLine.backgroundColor = UIStyleKit.Colors.weatherYellow
        addSubview(verticalLine)
    }

    private func setupWarningContainer() {
        warningContainer.backgroundColor = UIColor(hex: "#F45118") // Orange
        warningContainer.layer.cornerRadius = 20
        warningContainer.clipsToBounds = true
        warningContainer.layer.shadowColor = UIColor(hex: "#F45118").withAlphaComponent(0.5).cgColor
        warningContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        warningContainer.layer.shadowRadius = 5.53
        warningContainer.layer.shadowOpacity = 1.0
        warningContainer.isHidden = true // Nascosto di default, mostrato solo quando necessario
        addSubview(warningContainer)

        // Warning icon
        warningIcon.image = UIImage(named: "alert")
        warningIcon.tintColor = UIStyleKit.Colors.textWhite
        warningIcon.contentMode = .scaleAspectFit
        warningContainer.addSubview(warningIcon)

        // Add inner shadow after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIStyleKit.addInnerShadow(
                to: self.warningContainer,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 2.76,
                offset: CGSize(width: 0, height: 1.38)
            )
        }
    }

    private func setupBottomContainer() {
        bottomContainer.backgroundColor = UIStyleKit.Colors.weatherYellow
        bottomContainer.layer.cornerRadius = 15
        bottomContainer.clipsToBounds = true
        bottomContainer.layer.shadowColor = UIColor(hex: "#6F3CFF").withAlphaComponent(0.5).cgColor
        bottomContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        bottomContainer.layer.shadowRadius = 5.53
        bottomContainer.layer.shadowOpacity = 1.0
        addSubview(bottomContainer)

        // Bottom icon
        bottomIconView.backgroundColor = UIColor.clear
        bottomIconView.layer.cornerRadius = 10
        bottomIconView.clipsToBounds = true
        bottomIconView.contentMode = .scaleAspectFit
        bottomIconView.image = UIImage(named: "destination")
        bottomContainer.addSubview(bottomIconView)

        // Add inner shadow after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIStyleKit.addInnerShadow(
                to: self.bottomContainer,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 2.76,
                offset: CGSize(width: 0, height: 1.38)
            )
        }
    }

    private func setupWeatherPoints(count: Int) {
        // First remove any existing weather containers
        for container in weatherContainerViews {
            container.removeFromSuperview()
        }
        weatherContainerViews.removeAll()

        // Create new weather containers
        for i in 0..<count {
            let container = createWeatherContainer(forIndex: i)
            weatherContainerViews.append(container)
            addSubview(container)

            // Nascondi tutti i contenitori all'inizio
            container.isHidden = true
        }
    }

    private func createWeatherContainer(forIndex index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIStyleKit.Colors.weatherYellow // Default color
        container.layer.cornerRadius = 20
        container.clipsToBounds = true
        container.tag = index // Conserviamo l'indice nel tag

        // Add shadow based on container color
        container.layer.shadowColor = container.backgroundColor?.withAlphaComponent(0.5).cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 0)
        container.layer.shadowRadius = 5.53
        container.layer.shadowOpacity = 1.0

        // Add icon (default icon)
        let iconView = UIImageView()
        iconView.tag = 100 // Tag per identificare l'icona all'interno del container
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIStyleKit.Colors.textWhite
        iconView.image = UIImage(named: "sunny") // Default icon

        container.addSubview(iconView)

        // Setup icon constraints
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }

        let containerRef = container
        DispatchQueue.main.async {
            UIStyleKit.addInnerShadow(
                to: containerRef,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 2.76,
                offset: CGSize(width: 0, height: 1.38)
            )
        }

        return container
    }

    private func setupConstraints() {
        // Vertical line
        verticalLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(4)
            make.top.equalTo(topLocationIcon.snp.bottom).offset(5)
            make.bottom.equalTo(bottomContainer.snp.top).offset(-5)
        }

        // Top location icon - now directly on main view
        topLocationIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40) // Distanza dal bordo superiore
            make.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }

        // Warning container
        warningContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topLocationIcon.snp.bottom).offset(60)
            make.width.height.equalTo(40)
        }

        // Warning icon
        warningIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // Distanza per distribuire i waypoints uniformemente
        let availableHeight = UIScreen.main.bounds.height - 220 // Sottraiamo lo spazio per top e bottom
        let waypointSpacing = availableHeight / CGFloat(weatherContainerViews.count + 1)

        // Position weather containers along the vertical line
        for (index, container) in weatherContainerViews.enumerated() {
            container.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(topLocationIcon.snp.bottom).offset(
                    Int(waypointSpacing) * (index + 1)
                )
                make.width.height.equalTo(40)
            }
        }

        // Bottom container (destination icon)
        bottomContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(40) // Distanza dal bordo inferiore
            make.width.height.equalTo(40)
        }

        // Bottom icon
        bottomIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    // MARK: - Content Update Methods

    private func updateWeatherPointsWithWaypoints(_ waypoints: [VerticalStatusBarViewModel.WaypointInfo]) {
        // Nascondi tutti i punti meteo
        for container in weatherContainerViews {
            container.isHidden = true
        }

        // Mostra solo i punti per i waypoint attivi
        for (index, waypoint) in waypoints.enumerated() {
            if index < weatherContainerViews.count {
                weatherContainerViews[index].isHidden = false

                // Se abbiamo più di 6 waypoint e questo è l'ultimo, mostriamo l'icona dei puntini
                if waypoints.count > 6 && index == 5 && waypoints.count > 6 {
                    if let iconView = weatherContainerViews[index].viewWithTag(100) as? UIImageView {
                        iconView.image = UIImage(named: "more") // Icona per "più waypoint"
                    }
                }
            }
        }

        // Mostra la destinazione finale solo se abbiamo meno di 6 waypoint
        bottomContainer.isHidden = waypoints.count > 6

        // Aggiorna il colore della linea verticale
        updateLineColors()
    }

    private func updateWeatherIcons(with conditions: [Int: WeatherCondition]) {
        // Per ogni container visibile, aggiorna l'icona in base al codice meteo
        for container in weatherContainerViews where !container.isHidden {
            let waypointIndex = container.tag

            if let weather = conditions[waypointIndex],
               let iconView = container.viewWithTag(100) as? UIImageView {

                // Imposta l'icona in base al codice meteo
                let iconName = getWeatherIconName(for: weather)
                iconView.image = UIImage(named: iconName)

                // Imposta il colore del container in base al tipo di meteo
                let containerColor = getWeatherColor(for: weather)
                container.backgroundColor = containerColor

                // Aggiorna anche il colore dell'ombra
                container.layer.shadowColor = containerColor.withAlphaComponent(0.5).cgColor
            }
        }
    }

    private func updateLoadingState(_ isLoading: Bool) {
        // Puoi aggiungere un indicatore di caricamento se necessario
        alpha = isLoading ? 0.7 : 1.0
    }

    private func updateLineColors() {
        // Qui puoi personalizzare il colore della linea in base alle condizioni meteo
        // Per ora usiamo il colore giallo predefinito
        verticalLine.backgroundColor = UIStyleKit.Colors.weatherYellow
    }

    // MARK: - Helper Methods

    private func getWeatherIconName(for weather: WeatherCondition) -> String {
        // Converti il codice meteo nel nome dell'icona corrispondente
        // Questo è un esempio - dovresti adattarlo alle tue icone reali
        switch weather.code {
        case "clear", "sunny":
            return "sunny"
        case "partly-cloudy", "mostly-cloudy":
            return "partly-cloudy"
        case "cloudy":
            return "cloudy"
        case "rain", "showers":
            return "rain"
        case "snow", "flurries":
            return "snow"
        case "thunderstorm":
            return "thunderstorm"
        case "fog", "haze":
            return "fog"
        case "wind":
            return "wind"
        default:
            return "sunny" // Icona predefinita
        }
    }

    private func getWeatherColor(for weather: WeatherCondition) -> UIColor {
        // Converti il codice meteo nel colore del container
        switch weather.code {
        case "clear", "sunny":
            return UIStyleKit.Colors.weatherYellow
        case "partly-cloudy", "mostly-cloudy", "cloudy":
            return UIColor(hex: "#3C7BF7") // Blu
        case "rain", "showers":
            return UIColor(hex: "#6F3CFF") // Viola
        case "snow", "flurries":
            return UIColor(hex: "#3C7BF7") // Blu
        case "thunderstorm":
            return UIColor(hex: "#F45118") // Arancione
        case "fog", "haze":
            return UIColor(hex: "#6F3CFF") // Viola
        case "wind":
            return UIColor(hex: "#3C7BF7") // Blu
        default:
            return UIStyleKit.Colors.weatherYellow
        }
    }
}
