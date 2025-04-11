//
//  VerticalStatusBarView.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 07/04/25.
//

import UIKit
import SnapKit
import Combine

class VerticalStatusBarView: UIView {
    // MARK: - UI Elements
    private let topIndicatorView = UIView()
    private let warningContainer = UIView()
    private let warningIconLabel = UILabel()
    private let weatherContainer = UIView()
    private let weatherIconLabel = UILabel()
    private let sunnyContainer = UIView()
    private let sunnyIconLabel = UILabel()
    private let bottomContainer = UIView()
    private let bottomIconView = UIImageView()

    private let verticalLine = UIView()

    // MARK: - Properties
    private var viewModel: VerticalStatusBarViewModel

    // MARK: - Initialization
    init(viewModel: VerticalStatusBarViewModel) {
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
        // Main vertical line
        verticalLine.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0) // Yellow-orange
        addSubview(verticalLine)

        // Top indicator (yellow dot)
        topIndicatorView.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0) // Yellow
        topIndicatorView.layer.cornerRadius = 15
        topIndicatorView.clipsToBounds = true
        addSubview(topIndicatorView)

        // Warning container (orange)
        warningContainer.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0) // Orange
        warningContainer.layer.cornerRadius = 8
        addSubview(warningContainer)

        // Warning icon
        warningIconLabel.text = "⚠️"
        warningIconLabel.font = .systemFont(ofSize: 18)
        warningIconLabel.textAlignment = .center
        warningContainer.addSubview(warningIconLabel)

        // Weather container (purple)
        weatherContainer.backgroundColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0) // Purple
        weatherContainer.layer.cornerRadius = 8
        addSubview(weatherContainer)

        // Weather icon
        weatherIconLabel.text = "🌧"
        weatherIconLabel.font = .systemFont(ofSize: 18)
        weatherIconLabel.textAlignment = .center
        weatherContainer.addSubview(weatherIconLabel)

        // Sunny container (yellow)
        sunnyContainer.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0) // Yellow
        sunnyContainer.layer.cornerRadius = 8
        addSubview(sunnyContainer)

        // Sunny icon
        sunnyIconLabel.text = "☀️"
        sunnyIconLabel.font = .systemFont(ofSize: 18)
        sunnyIconLabel.textAlignment = .center
        sunnyContainer.addSubview(sunnyIconLabel)

        // Bottom container (blue-yellow)
        bottomContainer.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0) // Yellow
        bottomContainer.layer.cornerRadius = 15
        bottomContainer.clipsToBounds = true
        addSubview(bottomContainer)

        // Bottom icon (placeholder for a custom image)
        bottomIconView.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0) // Blue
        bottomIconView.layer.cornerRadius = 10
        bottomIconView.clipsToBounds = true
        bottomIconView.contentMode = .center
        bottomContainer.addSubview(bottomIconView)

        setupConstraints()
    }

    private func setupConstraints() {
        // Vertical line
        verticalLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(4)
            make.top.equalTo(topIndicatorView.snp.bottom)
            make.bottom.equalTo(bottomContainer.snp.top)
        }

        // Top indicator
        topIndicatorView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(30)
        }

        // Warning container
        warningContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(topIndicatorView.snp.bottom).offset(60)
            make.width.height.equalTo(40)
        }

        // Warning icon
        warningIconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Weather container
        weatherContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(warningContainer.snp.bottom).offset(70)
            make.width.height.equalTo(40)
        }

        // Weather icon
        weatherIconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Sunny container
        sunnyContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(weatherContainer.snp.bottom).offset(70)
            make.width.height.equalTo(40)
        }

        // Sunny icon
        sunnyIconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Bottom container
        bottomContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.height.equalTo(30)
        }

        // Bottom icon
        bottomIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    // MARK: - Content Update
    private func updateContent() {
        // Update the UI based on the view model data
        weatherIconLabel.text = getWeatherIcon(for: viewModel.weatherStatus)

        // Change the color of the vertical sections based on status
        updateLineColors()

        // Update warning visibility
        warningContainer.isHidden = !viewModel.hasWarning

        // Update the bottom icon based on conditions
        updateBottomIcon()
    }

    private func updateLineColors() {
        // Example: Change line colors based on weather conditions
        if viewModel.weatherStatus.lowercased() == "rainy" {
            // Set line segments to appropriate colors
            verticalLine.backgroundColor = UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0) // Purple for rainy
        } else if viewModel.hasWarning {
            verticalLine.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0) // Orange for warning
        } else {
            verticalLine.backgroundColor = UIColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0) // Default yellow-orange
        }
    }

    private func updateBottomIcon() {
        // You would implement custom logic here to update the bottom icon
        // based on your view model's properties
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
