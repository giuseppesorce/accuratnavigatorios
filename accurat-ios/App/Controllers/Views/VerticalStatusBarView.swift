import UIKit
import SnapKit
import Combine
import MapboxDirections

class VerticalStatusBarView: UIView {
    // MARK: - UI Elements
    private var lineSegments: [UIView] = []
    private let verticalLineContainer = UIView() // Contenitore per i segmenti di linea

    private let topLocationIcon = UIImageView()
    private let verticalLine = UIView()
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
        // Observe changes in active waypoints
        viewModel.$activeWaypoints
            .receive(on: DispatchQueue.main)
            .sink { [weak self] waypoints in
                self?.updateWeatherPointsWithWaypoints(waypoints)
                self?.updateWeatherIcons(waypoints)
            }
            .store(in: &cancellables)

        // Observe loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)

        // Observe errors
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    print("Error in vertical bar: \(error)")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Main vertical line
        setupVerticalLine()

        // Bottom container (destination)
        setupBottomContainer()

        // Top location icon (aggiunto dopo la linea per essere sopra)
        setupTopLocationIcon()

        // Setup "more points" indicator
        setupMorePointsIndicator()

        // Create initial weather points (6 maximum)
        setupWeatherPoints(count: 6)

        // Setup layout constraints
        setupConstraints()
    }

    private func setupTopLocationIcon() {
        topLocationIcon.image = UIImage(named: "location")
        topLocationIcon.contentMode = .scaleAspectFit
        topLocationIcon.backgroundColor = UIColor.clear

        addSubview(topLocationIcon)

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

    private func setupBottomContainer() {
        bottomIconView.backgroundColor = UIColor.clear
        bottomIconView.contentMode = .scaleAspectFit
        bottomIconView.image = UIImage(named: "user_status_bar")
        bottomIconView.tintColor = UIStyleKit.Colors.textWhite

        addSubview(bottomIconView)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIStyleKit.addInnerShadow(
                to: self.bottomIconView,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 2.76,
                offset: CGSize(width: 0, height: 1.38)
            )
        }
    }

    private func setupMorePointsIndicator() {
        if (viewModel.waypointsMoreThanMax) {
            topLocationIcon.isHidden = true

            for i in 0..<3 {
                let dashedLine = UIView()
                dashedLine.backgroundColor = UIStyleKit.Colors.weatherYellow
                dashedLine.layer.cornerRadius = 2
                dashedLine.tag = 200 + i

                // Aggiungi ombra esterna
                dashedLine.layer.shadowColor = UIStyleKit.Colors.weatherYellowShadow.cgColor
                dashedLine.layer.shadowOffset = CGSize(width: 0, height: 0)
                dashedLine.layer.shadowRadius = 5.53
                dashedLine.layer.shadowOpacity = 1.0

                addSubview(dashedLine)

                // Posiziona la linea nella stessa posizione verticale di topLocationIcon
                dashedLine.snp.makeConstraints { make in
                    make.centerX.equalToSuperview().offset(1)
                    make.width.equalTo(6)
                    make.height.equalTo(8)

                    // Centra verticalmente rispetto a topLocationIcon
                    let baseOffset = CGFloat(30) + CGFloat(25) - CGFloat(12)  // offset + metà altezza topLocationIcon - metà altezza totale delle tre linee
                    let lineOffset = CGFloat(i * 12)
                    make.top.equalToSuperview().offset(Int(baseOffset + lineOffset))
                }

                DispatchQueue.main.async {
                    UIStyleKit.addInnerShadow(
                        to: dashedLine,
                        color: UIStyleKit.Colors.innerShadow.cgColor,
                        radius: 2.76,
                        offset: CGSize(width: 0, height: 1.38)
                    )
                }
            }
        }
    }

    private func setupWeatherPoints(count: Int) {
        // Remove any existing weather containers
        for container in weatherContainerViews {
            container.removeFromSuperview()
        }
        weatherContainerViews.removeAll()

        // Create new weather containers
        for i in 0..<count {
            let container = createWeatherContainer(forIndex: i)
            weatherContainerViews.append(container)
            addSubview(container)
            container.isHidden = false
        }
    }

    private func createWeatherContainer(forIndex index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIStyleKit.Colors.weatherYellow
        container.layer.cornerRadius = 4
        container.clipsToBounds = true
        container.tag = index

        container.layer.shadowColor = UIStyleKit.Colors.weatherYellowShadow.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 0)
        container.layer.shadowRadius = 5.53
        container.layer.shadowOpacity = 1.0

        // Add icon (default icon)
        let iconView = UIImageView()
        iconView.tag = 100 // Tag to identify icon within container
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIStyleKit.Colors.textWhite
        container.addSubview(iconView)

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(15)
        }

        // Add inner shadow after layout
        let containerRef = container
        DispatchQueue.main.async {
            UIStyleKit.addInnerShadow(
                to: containerRef,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 4,
                offset: CGSize(width: 2, height: 2)
            )
        }

        return container
    }

    private func updateWeatherContainerPositions() {
        // Assicuriamoci che ci siano waypoint attivi
        guard !viewModel.activeWaypoints.isEmpty, !weatherContainerViews.isEmpty else { return }

        let lineHeight = self.verticalLine.frame.height
        let topY = topLocationIcon.frame.maxY - 7 // Offset per avvicinare all'icona

        let containerHeight: CGFloat = 25
        let visibleContainers = viewModel.activeWaypoints.count

        let spacing = lineHeight / CGFloat(visibleContainers + 1)
        var visibleIndex = 0

        for (index, container) in weatherContainerViews.enumerated() {
            if index < viewModel.activeWaypoints.count && !container.isHidden {
                visibleIndex += 1

                // Calcoliamo la posizione equidistante
                let yPosition = topY + (spacing * CGFloat(visibleIndex))
                container.snp.remakeConstraints { make in
                    make.centerX.equalTo(verticalLine.snp.centerX)
                    make.top.equalToSuperview().offset(yPosition - containerHeight/2)
                    make.width.height.equalTo(containerHeight)
                }
            }
        }
        layoutIfNeeded()
    }

    private func updateLoadingState(_ isLoading: Bool) {
        alpha = isLoading ? 0.7 : 1.0
    }

    private func updateLineColors() {
        verticalLine.backgroundColor = UIStyleKit.Colors.weatherYellow
    }

    // MARK: - Helper Methods

    private func getWeatherColor(for weather: WeatherCondition) -> UIColor {
        // Parse the weather code to get the main component
        let weatherPart = weather.weatherCode.split(separator: ":").last?.lowercased() ?? ""

        print("weather is \(weather) - weatherPart \(weatherPart)")
        // Determine color based on weather type
        switch String(weatherPart) {
        case "cl", "fw": // Clear or fair/mostly sunny
            return UIStyleKit.Colors.weatherYellow
        case "sc", "bk": // Partly cloudy, mostly cloudy, overcast
            return UIStyleKit.Colors.precipitationBlue
        case "r", "rw", "l", "zr", "zl", "ov": // Rain, rain showers, drizzle, freezing rain/drizzle
            return UIStyleKit.Colors.precipitationPurple
        case "s", "sw", "ip", "si": // Snow, snow showers, sleet, snow/sleet mix
            return UIStyleKit.Colors.precipitationBlue
        case "t": // Thunderstorms
            return UIStyleKit.Colors.precipitationBlue
        case "f", "h", "br", "if", "zf": // Fog, haze, mist, ice fog, freezing fog
            return UIStyleKit.Colors.precipitationBlue
        default:
            fatalError()
        }
    }

    private func setupVerticalLine() {
        // Rimuovi la linea singola e aggiungi il contenitore
        verticalLineContainer.backgroundColor = UIColor.clear
        addSubview(verticalLineContainer)

        // La linea verticale originale diventa invisibile o può essere rimossa
        verticalLine.backgroundColor = UIColor.clear
        verticalLine.isHidden = true
        addSubview(verticalLine)
    }

    private func setupConstraints() {
        topLocationIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(50)
        }

        // Configura il contenitore della linea verticale
        verticalLineContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(1)
            make.width.equalTo(6)
            make.top.equalTo(topLocationIcon.snp.bottom).offset(-7)
            make.bottom.equalTo(bottomIconView.snp.top).offset(2)
        }
        
        verticalLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(1)
            make.width.equalTo(6)
            make.top.equalTo(topLocationIcon.snp.bottom).offset(-7)
            make.bottom.equalTo(bottomIconView.snp.top).offset(2)
        }

        bottomIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
            make.width.height.equalTo(50)
        }

        // Prima impostiamo i vincoli di base per tutti i container
        for container in weatherContainerViews {
            container.snp.makeConstraints { make in
                make.centerX.equalTo(verticalLine.snp.centerX)
                make.width.height.equalTo(40)
            }
        }
    }

    // Modificare il metodo updateLineSegments per usare colori solidi senza gradienti
    private func updateLineSegments() {
        // Rimuovi tutti i segmenti esistenti
        for segment in lineSegments {
            segment.removeFromSuperview()
        }
        lineSegments.removeAll()

        let visibleContainers = weatherContainerViews.filter { !$0.isHidden }

        guard !visibleContainers.isEmpty else {
            // Se non ci sono contenitori visibili, crea una linea singola con il colore predefinito
            let singleSegment = createLineSegment(color: UIStyleKit.Colors.weatherYellow)
            verticalLineContainer.addSubview(singleSegment)
            lineSegments.append(singleSegment)

            singleSegment.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            return
        }

        // Ordina i container per posizione Y (dall'alto verso il basso)
        let sortedContainers = visibleContainers.sorted { $0.frame.minY < $1.frame.minY }

        // 1. Segmento dall'icona superiore al primo container
        if let firstContainer = sortedContainers.first {
            // Usa il colore del primo container invece di weatherYellow
            let topSegment = createLineSegment(color: firstContainer.backgroundColor ?? UIStyleKit.Colors.weatherYellow)
            verticalLineContainer.addSubview(topSegment)
            lineSegments.append(topSegment)

            topSegment.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(firstContainer.snp.centerY)
            }
        }

        // 2. Segmenti tra i container
        for i in 0..<sortedContainers.count - 1 {
            let upperContainer = sortedContainers[i]
            let lowerContainer = sortedContainers[i + 1]

            let upperColor = upperContainer.backgroundColor!
            let lowerColor = lowerContainer.backgroundColor!

            if upperColor == lowerColor {
                // Se i colori sono uguali, crea un solo segmento
                let segment = createLineSegment(color: upperColor)
                verticalLineContainer.addSubview(segment)
                lineSegments.append(segment)

                segment.snp.makeConstraints { make in
                    make.top.equalTo(upperContainer.snp.centerY)
                    make.bottom.equalTo(lowerContainer.snp.centerY)
                    make.left.right.equalToSuperview()
                }
            } else {
                // Se i colori sono diversi, crea due segmenti con colori solidi
                let middleY = (upperContainer.frame.maxY + lowerContainer.frame.minY) / 2

                // Calcola la posizione esatta usando constraints
                let upperContainerBottom = upperContainer.frame.maxY
                let lowerContainerTop = lowerContainer.frame.minY
                let transitionPoint = upperContainerBottom + ((lowerContainerTop - upperContainerBottom) / 2)

                // Segmento superiore
                let upperSegment = createLineSegment(color: upperColor)
                verticalLineContainer.addSubview(upperSegment)
                lineSegments.append(upperSegment)

                upperSegment.snp.makeConstraints { make in
                    make.top.equalTo(upperContainer.snp.centerY)
                    make.left.right.equalToSuperview()
                    // Usa un valore assoluto per bottom per evitare problemi di calcolo
                    if let superview = upperSegment.superview {
                        let bottomDistance = transitionPoint - superview.frame.minY
                        make.height.equalTo(transitionPoint - upperContainer.center.y)
                    }
                }

                // Segmento inferiore
                let lowerSegment = createLineSegment(color: lowerColor)
                verticalLineContainer.addSubview(lowerSegment)
                lineSegments.append(lowerSegment)

                lowerSegment.snp.makeConstraints { make in
                    make.top.equalTo(upperSegment.snp.bottom)
                    make.bottom.equalTo(lowerContainer.snp.centerY)
                    make.left.right.equalToSuperview()
                }
            }
        }

        // 3. Segmento dall'ultimo container all'icona inferiore
        if let lastContainer = sortedContainers.last {
            let bottomSegment = createLineSegment(color: lastContainer.backgroundColor ?? UIStyleKit.Colors.weatherYellow)
            verticalLineContainer.addSubview(bottomSegment)
            lineSegments.append(bottomSegment)

            bottomSegment.snp.makeConstraints { make in
                make.bottom.left.right.equalToSuperview()
                make.top.equalTo(lastContainer.snp.centerY)
            }
        }
    }
    // Crea un segmento di linea con colore specificato
    private func createLineSegment(color: UIColor) -> UIView {
        let segment = UIView()
        segment.backgroundColor = color
        segment.layer.cornerRadius = 0

        segment.layer.shadowColor = color.withAlphaComponent(0.5).cgColor
        segment.layer.shadowOffset = CGSize(width: 0, height: 0)
        segment.layer.shadowRadius = 4
        segment.layer.shadowOpacity = 1.0

        DispatchQueue.main.async {
            UIStyleKit.addInnerShadow(
                to: segment,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 4,
                offset: CGSize(width: 4, height: 4)
            )
        }

        return segment
    }

    // MARK: - Override dei metodi esistenti

    // Aggiorna il metodo layoutSubviews per gestire i gradienti
    override func layoutSubviews() {
        super.layoutSubviews()

        // Aggiorna i gradienti quando le dimensioni cambiano
//        for (index, segment) in lineSegments.enumerated() {
//            if let gradientLayer = segment.layer.sublayers?.first as? CAGradientLayer {
//                gradientLayer.frame = segment.bounds
//            }
//        }
    }

    private func updateWeatherPointsWithWaypoints(_ waypoints: [WaypointInfo]) {
        print("==== DEBUG: updateWeatherPointsWithWaypoints ====")
        print("Received waypoints: \(waypoints.count)")
        print("Waypoint indices: \(waypoints.map { $0.index })")
        print("Weather container views: \(weatherContainerViews.count)")

        for (index, container) in weatherContainerViews.enumerated() {
            print("Initial state - Container \(index) hidden: \(container.isHidden), tag: \(container.tag)")
            container.isHidden = true
        }

        // Ottieni waypoint attivi ordinati per indice in ordine decrescente (indici maggiori in alto)
        let sortedWaypoints = waypoints.sorted { $0.index > $1.index }
        print("Sorted waypoints indices: \(sortedWaypoints.map { $0.index })")

        // Mostra solo i punti per i waypoint attivi (fino a 6)
        let maxVisiblePoints = min(sortedWaypoints.count, 6)
        print("Will show \(maxVisiblePoints) visible points")

        for i in 0..<maxVisiblePoints {
            if i < weatherContainerViews.count {
                let waypointIndex = sortedWaypoints[i].index
                print("Making container \(i) visible for waypoint \(waypointIndex)")
                weatherContainerViews[i].tag = waypointIndex
                weatherContainerViews[i].isHidden = false
            }
        }
        
        if viewModel.waypointsMoreThanMax {
            topLocationIcon.isHidden = true
        } else {
            topLocationIcon.isHidden = false
        }

        updateWeatherContainerPositions()

        print("Scheduling line segments update")
        DispatchQueue.main.async { [weak self] in
            self?.updateLineSegments()
        }
    }

    private func updateWeatherIcons(_ waypoints: [WaypointInfo]) {
        print("==== DEBUG: updateWeatherIcons ====")
        print("weatherContainerViews count: \(weatherContainerViews.count)")
        print("Active waypoints count: \(waypoints.count)")
        print("Active waypoints indices: \(waypoints.map { $0.index })")

        // Print all container visibility status
        for (index, container) in weatherContainerViews.enumerated() {
            print("Container \(index) - Hidden: \(container.isHidden)")
        }

        for (containerIndex, container) in weatherContainerViews.enumerated() where !container.isHidden {
            let waypointIndex = container.tag
            print("Processing container \(containerIndex) with tag \(waypointIndex)")

            // Find matching waypoint
            let matchingWaypoints = waypoints.filter { $0.index == waypointIndex }
            print("Found \(matchingWaypoints.count) matching waypoints for index \(waypointIndex)")

            if let waypointInfo = matchingWaypoints.first,
               let weather = waypointInfo.weather,
               let iconView = container.viewWithTag(100) as? UIImageView {

                print("Waypoint \(waypointIndex): Weather found - \(weather.weatherCode), icon name: \(weather.iconName)")

                if let iconImage = UIImage(named: weather.iconName) {
                    print("Icon image loaded successfully for \(weather.iconName)")
                    iconView.image = iconImage
                    iconView.isHidden = false
                } else {
                    print("⚠️ Failed to load icon image for \(weather.iconName)")
                    iconView.isHidden = true
                }

                let containerColor = getWeatherColor(for: weather)
                print("Weather color for container \(containerIndex): \(containerColor)")
                container.backgroundColor = containerColor
                container.layer.shadowColor = containerColor.withAlphaComponent(0.5).cgColor
            } else {
                print("⚠️ Container \(containerIndex): Missing waypoint info or weather data")
                if let iconView = container.viewWithTag(100) as? UIImageView {
                    iconView.isHidden = true
                }
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateLineSegments()
        }
    }
}
