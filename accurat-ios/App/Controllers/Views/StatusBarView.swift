
import UIKit
import SnapKit
import Combine
import MapboxNavigation
import MapboxCoreNavigation
import CoreLocation
import MapboxDirections

class StatusBarView: UIView {
    // MARK: - UI Elements
    // Meteo a sinistra
    private let weatherContainer = UIView()
    private let weatherIconLabel = UILabel()
    private let weatherStatusLabel = UILabel()

    // Temperatura al centro
    private let temperatureLabel = UILabel()

    // Precipitazioni a destra
    private let precipitationContainer = UIView()
    private let precipitationPercentageLabel = UILabel()
    private var dropIconImageView: UIImageView!

    // Elementi secondari
    private let distanceLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Properties
    private var weatherViewModel: WeatherViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(weatherViewModel: WeatherViewModel) {
        self.weatherViewModel = weatherViewModel
        super.init(frame: .zero)
        setupUI()
        bindViewModels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {
        // View setup - Utilizziamo UIStyleKit
        backgroundColor = UIColor(hex: "#222222", alpha: 0.9) // #222222E5
        layer.cornerRadius = 8

        // Ombra esterna
        layer.shadowColor = UIColor(hex: "#6F3CFF", alpha: 0.3).cgColor // #6F3CFF4D
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 10
        layer.shadowOpacity = 1.0

        // Meteo container (sinistra)
        addSubview(weatherContainer)
        weatherContainer.backgroundColor = UIStyleKit.Colors.weatherYellow
        weatherContainer.layer.cornerRadius = 8

        weatherIconLabel.font = UIStyleKit.Fonts.regular(size: 14)
        weatherIconLabel.textColor = UIStyleKit.Colors.textBlack
        weatherContainer.addSubview(weatherIconLabel)

        weatherStatusLabel.font = UIStyleKit.Fonts.regular(size: 14)
        weatherStatusLabel.textColor = UIStyleKit.Colors.textBlack
        weatherStatusLabel.lineBreakMode = .byTruncatingTail
        weatherStatusLabel.adjustsFontSizeToFitWidth = true
        weatherStatusLabel.minimumScaleFactor = 0.8
        weatherContainer.addSubview(weatherStatusLabel)

        // Temperatura (centro)
        temperatureLabel.font = UIStyleKit.Fonts.regular(size: 14)
        temperatureLabel.textColor = UIStyleKit.Colors.textWhite
        temperatureLabel.textAlignment = .center
        addSubview(temperatureLabel)

        // Precipitazioni (destra)
        precipitationContainer.backgroundColor = UIColor.clear
        precipitationContainer.layer.cornerRadius = 8
        addSubview(precipitationContainer)

        // Configurazione icona drop
        dropIconImageView = UIImageView(image: UIImage(named: "drop"))
        dropIconImageView.contentMode = .scaleAspectFit
        precipitationContainer.addSubview(dropIconImageView)

        precipitationPercentageLabel.font = UIStyleKit.Fonts.regular(size: 14)
        precipitationPercentageLabel.textColor = UIStyleKit.Colors.lightBackground
        precipitationPercentageLabel.textAlignment = .center
        precipitationContainer.addSubview(precipitationPercentageLabel)

        // Distance info (nascosto)
        distanceLabel.font = UIStyleKit.Fonts.regular(size: 14)
        distanceLabel.textColor = UIStyleKit.Colors.textWhite
        distanceLabel.textAlignment = .center
        distanceLabel.isHidden = true
        addSubview(distanceLabel)

        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = UIStyleKit.Colors.textWhite
        addSubview(loadingIndicator)

        // Applica gli stili di testo avanzati
        UIStyleKit.applyTextStyle(to: temperatureLabel, style: .regular, alignment: .center)
        UIStyleKit.applyTextStyle(to: precipitationPercentageLabel, style: .regular, alignment: .center)
        UIStyleKit.applyTextStyle(to: weatherStatusLabel, style: .regular, alignment: .left)

        setupConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Aggiunge l'ombra interna al contenitore principale
        UIStyleKit.addInnerShadow(
            to: self,
            color: UIColor(hex: "#FFFFFF", alpha: 0.08).cgColor,
            radius: 1,
            offset: CGSize.zero
        )

        // Aggiunge l'ombra al container del meteo
        UIStyleKit.styleWeatherContainer(weatherContainer)
    }

    private func setupConstraints() {
        // Meteo container (sinistra)
        weatherContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
            // Larghezza dinamica basata sul contenuto con limiti minimo e massimo
            make.width.greaterThanOrEqualTo(67) // Larghezza minima
            make.width.lessThanOrEqualTo(150) // Larghezza massima
        }

        // Weather icon
        weatherIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
        }

        // Weather status
        weatherStatusLabel.snp.makeConstraints { make in
            make.leading.equalTo(weatherIconLabel.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }

        // Temperatura (centro)
        temperatureLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        // Precipitazioni (destra)
        precipitationContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(67)
            make.width.lessThanOrEqualTo(120)
        }

        // Icona drop
        dropIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // Percentuale precipitazioni
        precipitationPercentageLabel.snp.makeConstraints { make in
            make.leading.equalTo(dropIconImageView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }

        // Loading indicator
        loadingIndicator.snp.makeConstraints { make in
            make.trailing.equalTo(temperatureLabel.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        // Distance (nascosto)
        distanceLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    // MARK: - View Model Binding
    private func bindViewModels() {
        // Observe loading state
        weatherViewModel.$isLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
                self?.updateWeatherContent()
            }
            .store(in: &cancellables)
        
        // Observe error message
        weatherViewModel.$weatherErrorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWeatherContent()
            }
            .store(in: &cancellables)

        // Observe weather changes
        weatherViewModel.$currentWeather
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWeatherContent()
            }
            .store(in: &cancellables)

        // Observe distance
        weatherViewModel.$distanceRemaining
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWeatherContent()
            }
            .store(in: &cancellables)

        // Initial update
        updateWeatherContent()
    }

    private func updateWeatherContent() {
        if weatherViewModel.isLoading {
            loadingIndicator.startAnimating()
            return
        }

        loadingIndicator.stopAnimating()

        if let _ = weatherViewModel.weatherErrorMessage {
            weatherIconLabel.text = "⚠️"
            return
        }

        if let weather = weatherViewModel.currentWeather {
            // Aggiorna icona meteo
            weatherIconLabel.text = getWeatherIcon(for: weather.weatherDescription)

            // Aggiorna descrizione meteo
            weatherStatusLabel.text = weather.weatherDescription
            UIStyleKit.applyTextStyle(to: weatherStatusLabel, style: .regular, alignment: .left)

            // Aggiorna temperatura
            temperatureLabel.text = "\(Int(weather.temperatureC))°C"
            UIStyleKit.applyTextStyle(to: temperatureLabel, style: .regular, alignment: .center)

            // Aggiorna precipitazioni
            precipitationPercentageLabel.text = "\(weather.precipitationProbability)%"
            UIStyleKit.applyTextStyle(to: precipitationPercentageLabel, style: .regular, alignment: .center)
        } else {
            precipitationPercentageLabel.text = "0%"
            UIStyleKit.applyTextStyle(to: precipitationPercentageLabel, style: .regular, alignment: .center)
        }

        // Aggiorna la distanza (anche se nascosta)
        if let distance = weatherViewModel.distanceRemaining {
            distanceLabel.text = distance
        }
    }

    private func getWeatherIcon(for status: String) -> String {
        let lowercasedStatus = status.lowercased()

        if lowercasedStatus.contains("rain") || lowercasedStatus.contains("pioggia") {
            return "🌧"
        } else if lowercasedStatus.contains("sun") || lowercasedStatus.contains("sole") || lowercasedStatus.contains("sereno") {
            return "☀️"
        } else if lowercasedStatus.contains("cloud") || lowercasedStatus.contains("nuvol") {
            return "☁️"
        } else if lowercasedStatus.contains("snow") || lowercasedStatus.contains("neve") {
            return "❄️"
        } else if lowercasedStatus.contains("fog") || lowercasedStatus.contains("nebbia") {
            return "🌫"
        } else if lowercasedStatus.contains("storm") || lowercasedStatus.contains("tempesta") {
            return "⛈"
        } else {
            return "🌤" // Partially cloudy as default
        }
    }

    // MARK: - Public Methods
    func updateConditions(at coordinate: CLLocationCoordinate2D) {
        weatherViewModel.updateConditions(at: coordinate)
    }

    func updateRouteRoadConditions(for route: Route) {
        weatherViewModel.updateRouteRoadConditions(for: route)
    }
}
