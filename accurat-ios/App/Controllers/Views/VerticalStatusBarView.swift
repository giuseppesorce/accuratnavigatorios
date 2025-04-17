import UIKit
import SnapKit
import Combine

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

    // MARK: - Initialization
    init(viewModel: VerticalStatusBarViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        updateContent()

//        viewModel.onDataChanged = { [weak self] in
//            self?.updateContent()
//        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        bottomIconView.backgroundColor = UIColor(hex: "#3C7BF7") // Blue
        bottomIconView.layer.cornerRadius = 10
        bottomIconView.clipsToBounds = true
        bottomIconView.contentMode = .scaleAspectFit
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
        }
    }

    private func createWeatherContainer(forIndex index: Int) -> UIView {
        // Determine weather type (alternating for demo purposes)
        let weatherType = index % 3

        let container = UIView()
        if weatherType == 0 {
            // Rain weather (purple)
            container.backgroundColor = UIColor(hex: "#6F3CFF") // Purple
            container.tag = 0 // Tag for rain
        } else if weatherType == 1 {
            // Warning (orange)
            container.backgroundColor = UIColor(hex: "#F45118") // Orange
            container.tag = 1 // Tag for warning
        } else {
            // Sunny (yellow)
            container.backgroundColor = UIStyleKit.Colors.weatherYellow
            container.tag = 2 // Tag for sunny
        }

        container.layer.cornerRadius = 20
        container.clipsToBounds = true

        // Add shadow based on container color
        container.layer.shadowColor = container.backgroundColor?.withAlphaComponent(0.5).cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 0)
        container.layer.shadowRadius = 5.53
        container.layer.shadowOpacity = 1.0

        // Add icon based on weather type
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIStyleKit.Colors.textWhite

        if weatherType == 0 {
            // Rain icon
            iconView.image = UIImage(named: "drop")
        } else if weatherType == 1 {
            // Warning icon
            iconView.image = UIImage(named: "alert")
        } else {
            // Sun icon
            iconView.image = UIImage(named: "sunny")
        }

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
            make.top.equalTo(topLocationIcon.snp.bottom)
            make.bottom.equalTo(bottomContainer.snp.top)
        }

        // Top location icon - now directly on main view
        topLocationIcon.snp.makeConstraints { make in
            make.top.equalToSuperview()
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

        // Position weather containers along the vertical line
        let totalSpacing = (UIScreen.main.bounds.height - 200) / CGFloat(weatherContainerViews.count + 1)

        for (index, container) in weatherContainerViews.enumerated() {
            container.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(warningContainer.snp.bottom).offset(Int(totalSpacing) * (index + 1))
                make.width.height.equalTo(40)
            }
        }

        bottomContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(10)
            make.width.height.equalTo(40)
        }

        // Bottom icon
        bottomIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }
    
    // MARK: - Content Update
    private func updateContent() {
        // Update line colors based on weather conditions
        updateLineColors()

        // Update weather points (this would use real data from the view model)
        updateWeatherPoints()

        // Update the bottom icon based on conditions
        updateBottomIcon()
    }

    private func updateLineColors() {

    }

    private func updateWeatherPoints() {
        for (index, container) in weatherContainerViews.enumerated() {
            // Example logic - you would replace this with your actual data logic
            let shouldShow = index < 6 // Show max 6 points as specified
            container.isHidden = true // !shouldShow
        }
    }

    private func updateBottomIcon() {
        bottomIconView.image = UIImage(named: "user_gps")
    }
}
