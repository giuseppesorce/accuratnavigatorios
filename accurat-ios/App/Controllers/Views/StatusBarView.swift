import UIKit
import SnapKit
import Combine

class StatusBarView: UIView {
    // MARK: - UI Elements
    private let weatherIconLabel = UILabel()
    private let weatherStatusLabel = UILabel()
    private let distanceLabel = UILabel()
    private let humidityContainer = UIView()
    private let humidityIconLabel = UILabel()
    private let humidityPercentageLabel = UILabel()

    // MARK: - Properties
    private var viewModel: StatusBarViewModel

    // MARK: - Initialization
    init(viewModel: StatusBarViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        updateContent()

        viewModel.onDataChanged = { [weak self] in
            self?.updateContent()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        // View setup
        backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8)
        layer.cornerRadius = 8

        // Weather icon
        weatherIconLabel.font = .systemFont(ofSize: 18)
        weatherIconLabel.textColor = .white
        addSubview(weatherIconLabel)

        // Weather status
        weatherStatusLabel.font = .systemFont(ofSize: 18, weight: .medium)
        weatherStatusLabel.textColor = .white
        addSubview(weatherStatusLabel)

        // Distance info
        distanceLabel.font = .systemFont(ofSize: 18)
        distanceLabel.textColor = .white
        distanceLabel.textAlignment = .center
        addSubview(distanceLabel)

        // Humidity container
        humidityContainer.backgroundColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        humidityContainer.layer.cornerRadius = 16
        addSubview(humidityContainer)

        // Humidity icon
        humidityIconLabel.text = "⚡"
        humidityIconLabel.font = .systemFont(ofSize: 18)
        humidityIconLabel.textColor = .white
        humidityContainer.addSubview(humidityIconLabel)

        // Humidity percentage
        humidityPercentageLabel.font = .systemFont(ofSize: 18, weight: .medium)
        humidityPercentageLabel.textColor = .white
        humidityContainer.addSubview(humidityPercentageLabel)

        setupConstraints()
        updateContent()
    }

    private func setupConstraints() {
        // Weather icon and status (left)
        weatherIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        weatherStatusLabel.snp.makeConstraints { make in
            make.leading.equalTo(weatherIconLabel.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
        }

        // Distance (center)
        distanceLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // Humidity container (right)
        humidityContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }

        // Humidity icon
        humidityIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }

        // Humidity percentage
        humidityPercentageLabel.snp.makeConstraints { make in
            make.leading.equalTo(humidityIconLabel.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    // MARK: - Content Update
    private func updateContent() {
        weatherIconLabel.text = getWeatherIcon(for: viewModel.weatherStatus)
        weatherStatusLabel.text = viewModel.weatherStatus
        distanceLabel.text = viewModel.distanceInfo
        humidityPercentageLabel.text = "\(viewModel.humidityPercentage)%"
    }

    private func getWeatherIcon(for status: String) -> String {
        switch status.lowercased() {
        case "rainy":
            return "🌧"
        case "sunny":
            return "☀️"
        case "cloudy":
            return "☁️"
        default:
            return "🌤"
        }
    }
}
