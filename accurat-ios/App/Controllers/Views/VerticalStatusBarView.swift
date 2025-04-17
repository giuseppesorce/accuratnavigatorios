import UIKit
import SnapKit
import Combine
import MapboxDirections

class VerticalStatusBarView: UIView {
    // MARK: - UI Elements
    private let topLocationIcon = UIImageView()
    private let verticalLine = UIView()
    private let bottomIconView = UIImageView()
    private let morePointsIndicator = UIImageView()

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
            }
            .store(in: &cancellables)

        // Observe changes in weather conditions
        viewModel.$waypointWeatherConditions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conditions in
                self?.updateWeatherIcons(with: conditions)
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
        // Top location icon
        setupTopLocationIcon()

        // Main vertical line
        setupVerticalLine()

        // Bottom container (destination)
        setupBottomContainer()

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

    private func setupVerticalLine() {
        verticalLine.backgroundColor = UIStyleKit.Colors.weatherYellow
        addSubview(verticalLine)
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
        morePointsIndicator.backgroundColor = UIStyleKit.Colors.weatherYellow
        morePointsIndicator.layer.cornerRadius = 20
        morePointsIndicator.clipsToBounds = true
        morePointsIndicator.contentMode = .scaleAspectFit
        morePointsIndicator.image = UIImage(named: "more")
        morePointsIndicator.tintColor = UIStyleKit.Colors.textWhite
        morePointsIndicator.isHidden = true

        morePointsIndicator.layer.shadowColor = UIStyleKit.Colors.weatherYellowShadow.cgColor
        morePointsIndicator.layer.shadowOffset = CGSize(width: 0, height: 0)
        morePointsIndicator.layer.shadowRadius = 5.53
        morePointsIndicator.layer.shadowOpacity = 1.0

        addSubview(morePointsIndicator)

        // Add inner shadow after layout
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIStyleKit.addInnerShadow(
                to: self.morePointsIndicator,
                color: UIStyleKit.Colors.innerShadow.cgColor,
                radius: 2.76,
                offset: CGSize(width: 0, height: 1.38)
            )
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

            // Hide all containers initially
            container.isHidden = true
        }
    }

    private func createWeatherContainer(forIndex index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = UIStyleKit.Colors.weatherYellow
        container.layer.cornerRadius = 20
        container.clipsToBounds = true
        container.tag = index // Store index in tag

        // Add shadow
        container.layer.shadowColor = UIStyleKit.Colors.weatherYellowShadow.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 0)
        container.layer.shadowRadius = 5.53
        container.layer.shadowOpacity = 1.0

        // Add icon (default icon)
        let iconView = UIImageView()
        iconView.tag = 100 // Tag to identify icon within container
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIStyleKit.Colors.textWhite
        iconView.image = UIImage(named: "CL") // Default clear/sunny icon

        container.addSubview(iconView)

        // Setup icon constraints
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }

        // Add inner shadow after layout
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
        // Top location icon
        topLocationIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(50)
        }

        // Vertical line
        verticalLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(1)
            make.width.equalTo(4)
            make.top.equalTo(topLocationIcon.snp.bottom).offset(-9)
            make.bottom.equalTo(bottomIconView.snp.top).offset(2)
        }

        // Calculate space to distribute waypoints evenly
        let availableHeight = UIScreen.main.bounds.height - 200
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
        bottomIconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
            make.width.height.equalTo(50)
        }

        // More points indicator (three dots)
        morePointsIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(40)
            make.width.height.equalTo(40)
        }
    }

    // MARK: - Content Update Methods

    private func updateWeatherPointsWithWaypoints(_ waypoints: [VerticalStatusBarViewModel.WaypointInfo]) {
        // Hide all weather points initially
        for container in weatherContainerViews {
            container.isHidden = true
        }

        // Show only points for active waypoints (up to 6)
        let maxVisiblePoints = min(waypoints.count, 6)

        for i in 0..<maxVisiblePoints {
            if i < weatherContainerViews.count {
                weatherContainerViews[i].isHidden = false
            }
        }

        // Handle special case when more than 6 waypoints
        if waypoints.count > 6 {
            // Show "more points" indicator and hide final destination
            morePointsIndicator.isHidden = false
            topLocationIcon.isHidden = true
        } else {
            // Show final destination and hide "more points" indicator
            morePointsIndicator.isHidden = true
            topLocationIcon.isHidden = false
        }

        // Update vertical line color
        updateLineColors()
    }

    private func updateWeatherIcons(with conditions: [Int: WeatherCondition]) {
        // For each visible container, update icon based on weather code
        for container in weatherContainerViews where !container.isHidden {
            let waypointIndex = container.tag

            if let weather = conditions[waypointIndex],
               let iconView = container.viewWithTag(100) as? UIImageView {

                // Get weather icon name (derived from the weather code)
                let weatherPart = weather.weatherCode.split(separator: ":").last ?? "CL"
                let iconName = weather.isDay ? String(weatherPart) : "\(weatherPart)-night"

                // Set icon image
                if let iconImage = UIImage(named: iconName) {
                    iconView.image = iconImage
                    iconView.isHidden = false
                } else {
                    // Fallback to default icon if image not found
                    iconView.isHidden = true
                }

                // Set container color based on weather type
                let containerColor = getWeatherColor(for: weather)
                container.backgroundColor = containerColor

                // Update shadow color
                container.layer.shadowColor = containerColor.withAlphaComponent(0.5).cgColor
            }
        }
    }

    private func updateLoadingState(_ isLoading: Bool) {
        alpha = isLoading ? 0.7 : 1.0
    }

    private func updateLineColors() {
        // We could customize line color based on various conditions
        // For now using the default yellow color
        verticalLine.backgroundColor = UIStyleKit.Colors.weatherYellow
    }

    // MARK: - Helper Methods

    private func getWeatherColor(for weather: WeatherCondition) -> UIColor {
        // Parse the weather code to get the main component
        let weatherPart = weather.weatherCode.split(separator: ":").last?.lowercased() ?? ""

        // Determine color based on weather type
        switch String(weatherPart) {
        case "cl", "fw": // Clear or fair/mostly sunny
            return UIStyleKit.Colors.weatherYellow

        case "sc", "bk", "ov": // Partly cloudy, mostly cloudy, overcast
            return UIColor(hex: "#3C7BF7") // Blue

        case "r", "rw", "l", "zr", "zl": // Rain, rain showers, drizzle, freezing rain/drizzle
            return UIColor(hex: "#6F3CFF") // Purple

        case "s", "sw", "ip", "si": // Snow, snow showers, sleet, snow/sleet mix
            return UIColor(hex: "#3C7BF7") // Blue

        case "t": // Thunderstorms
            return UIColor(hex: "#F45118") // Orange

        case "f", "h", "br", "if", "zf": // Fog, haze, mist, ice fog, freezing fog
            return UIColor(hex: "#6F3CFF") // Purple

        default:
            return UIStyleKit.Colors.weatherYellow // Default yellow
        }
    }
}
