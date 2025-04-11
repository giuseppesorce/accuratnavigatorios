import MapboxNavigation
import MapboxCoreNavigation
import UIKit
import Combine
import SnapKit

// MARK: - Weather Status View
class WeatherStatusView: UIView {
    // UI Components
    private let containerView = UIView()
    private let statusLabel = UILabel()
    private let temperatureLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let precipitationLabel = UILabel()
    private let roadConditionLabel = UILabel()
    private let riskLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // View Model
    private var viewModel: WeatherViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: WeatherViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
        bindViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Container setup
        addSubview(containerView)
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        containerView.layer.cornerRadius = 8
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Loading indicator
        containerView.addSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(20)
        }

        // Status label (for errors or loading text)
        containerView.addSubview(statusLabel)
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .darkGray
        statusLabel.numberOfLines = 2
        statusLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(loadingIndicator.snp.right).offset(8)
            make.right.equalToSuperview().offset(-12)
        }

        // Temperature label
        containerView.addSubview(temperatureLabel)
        temperatureLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        temperatureLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(12)
        }

        // Weather description label
        containerView.addSubview(descriptionLabel)
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.snp.makeConstraints { make in
            make.centerY.equalTo(temperatureLabel)
            make.left.equalTo(temperatureLabel.snp.right).offset(8)
            make.right.equalToSuperview().offset(-12)
        }

        // Precipitation label
        containerView.addSubview(precipitationLabel)
        precipitationLabel.font = UIFont.systemFont(ofSize: 12)
        precipitationLabel.textColor = .darkGray
        precipitationLabel.snp.makeConstraints { make in
            make.top.equalTo(temperatureLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }

        // Road condition label
        containerView.addSubview(roadConditionLabel)
        roadConditionLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        roadConditionLabel.textColor = .orange
        roadConditionLabel.numberOfLines = 0
        roadConditionLabel.snp.makeConstraints { make in
            make.top.equalTo(precipitationLabel.snp.bottom).offset(6)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }

        // Risk label
        containerView.addSubview(riskLabel)
        riskLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        riskLabel.textColor = .red
        riskLabel.numberOfLines = 0
        riskLabel.snp.makeConstraints { make in
            make.top.equalTo(roadConditionLabel.snp.bottom).offset(4)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }

        // Hide all by default
        temperatureLabel.isHidden = true
        descriptionLabel.isHidden = true
        precipitationLabel.isHidden = true
        roadConditionLabel.isHidden = true
        riskLabel.isHidden = true
    }

    private func bindViewModel() {
        // Observe loading state
        viewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoadingState()
                } else {
                    self?.updateUI()
                }
            }
            .store(in: &cancellables)

        // Observe error message
        viewModel.$errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)

        // Observe weather changes
        viewModel.$currentWeather
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)

        // Observe road condition changes
        viewModel.$currentRoadCondition
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateUI()
            }
            .store(in: &cancellables)

        // Initial update
        updateUI()
    }

    private func showLoadingState() {
        loadingIndicator.startAnimating()
        statusLabel.text = "Aggiornamento..."
        statusLabel.isHidden = false

        temperatureLabel.isHidden = true
        descriptionLabel.isHidden = true
        precipitationLabel.isHidden = true
        roadConditionLabel.isHidden = true
        riskLabel.isHidden = true
    }

    private func updateUI() {
        if viewModel.isLoading {
            showLoadingState()
            return
        }

        loadingIndicator.stopAnimating()

        if let errorMessage = viewModel.errorMessage {
            statusLabel.text = "Errore: \(errorMessage)"
            statusLabel.textColor = .red
            statusLabel.isHidden = false

            temperatureLabel.isHidden = true
            descriptionLabel.isHidden = true
            precipitationLabel.isHidden = true
            roadConditionLabel.isHidden = true
            riskLabel.isHidden = true
            return
        }

        if let weather = viewModel.currentWeather {
            statusLabel.isHidden = true

            temperatureLabel.text = "\(Int(weather.temperatureC))°C"
            temperatureLabel.isHidden = false

            descriptionLabel.text = weather.weatherDescription
            descriptionLabel.isHidden = false

            if weather.precipitationProbability > 0 {
                precipitationLabel.text = "Precipitazioni: \(weather.precipitationProbability)%"
                precipitationLabel.isHidden = false
            } else {
                precipitationLabel.isHidden = true
            }
        } else {
            statusLabel.text = "In attesa dei dati..."
            statusLabel.textColor = .darkGray
            statusLabel.isHidden = false

            temperatureLabel.isHidden = true
            descriptionLabel.isHidden = true
            precipitationLabel.isHidden = true
        }

        if let roadCondition = viewModel.currentRoadCondition, roadCondition.summaryIndex > 0 {
            if let surfaceCondition = roadCondition.surfaceCondition {
                roadConditionLabel.text = surfaceCondition.rawValue
                roadConditionLabel.isHidden = false
            } else {
                roadConditionLabel.isHidden = true
            }

            if let riskType = roadCondition.riskType {
                riskLabel.text = riskType.rawValue
                riskLabel.isHidden = false
            } else {
                riskLabel.isHidden = true
            }
        } else {
            roadConditionLabel.isHidden = true
            riskLabel.isHidden = true
        }
    }
}
