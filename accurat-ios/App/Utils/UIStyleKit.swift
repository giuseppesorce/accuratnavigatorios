//
//  UIStyle.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 10/04/25.
//

import UIKit
import SnapKit
import Combine
import MapboxNavigation
import MapboxCoreNavigation
import CoreLocation
import MapboxDirections

// MARK: - UIStyle Helper Class
class UIStyleKit {

    // Aggiunta al UIStyleKit.swift

    // MARK: - StatusBar Styling
    static func styleStatusBar(_ view: UIView) {
        // Sfondo e bordi
        view.backgroundColor = UIColor(hex: "#222222", alpha: 0.9) // #222222E5
        view.layer.cornerRadius = 8

        // Ombra esterna
        view.layer.shadowColor = UIColor(hex: "#6F3CFF", alpha: 0.3).cgColor // #6F3CFF4D
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = 10
        view.layer.shadowOpacity = 1.0

        // Ombra interna - da chiamare dopo che la view è stata layout
        addInnerShadow(to: view,
                      color: UIColor(hex: "#FFFFFF", alpha: 0.08).cgColor,
                      radius: 1,
                      offset: CGSize.zero)
    }

    // Metodo helper per aggiungere ombra interna
    static func addInnerShadow(to view: UIView, color: CGColor, radius: CGFloat, offset: CGSize) {
        // Rimuovi precedenti ombre interne
        view.layer.sublayers?.filter { $0.name == "innerShadowLayer" }.forEach { $0.removeFromSuperlayer() }

        let innerShadowLayer = CALayer()
        innerShadowLayer.name = "innerShadowLayer" // Per identificarlo facilmente
        innerShadowLayer.frame = view.bounds
        innerShadowLayer.backgroundColor = UIColor.clear.cgColor
        innerShadowLayer.shadowColor = color
        innerShadowLayer.shadowOffset = offset
        innerShadowLayer.shadowOpacity = 1.0
        innerShadowLayer.shadowRadius = radius
        innerShadowLayer.cornerRadius = view.layer.cornerRadius
        innerShadowLayer.masksToBounds = false

        // Maschera per l'ombra interna
        let path = UIBezierPath(roundedRect: view.bounds.insetBy(dx: -20, dy: -20),
                               cornerRadius: view.layer.cornerRadius)
        let cutout = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).reversing()
        path.append(cutout)

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        innerShadowLayer.mask = mask

        view.layer.addSublayer(innerShadowLayer)
    }

    // Metodo per configurare il container delle precipitazioni con icona
    static func configurePrecipitationContainer(_ container: UIView, label: UILabel, parentView: UIView) {
        container.layer.cornerRadius = 8
        container.backgroundColor = Colors.precipitationBlue.withAlphaComponent(0.8)

        // Configura l'icona drop
        let dropIconImageView = UIImageView(image: UIImage(named: "drop"))
        dropIconImageView.contentMode = .scaleAspectFit
        container.addSubview(dropIconImageView)

        // Configura label
        label.textColor = Colors.lightBackground
        applyTextStyle(to: label, style: .regular, alignment: .center)

        // Layout
        dropIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        label.snp.makeConstraints { make in
            make.leading.equalTo(dropIconImageView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }
    }

    // Metodo per configurare interamente una StatusBarView
    static func configureStatusBarView(_ statusBar: StatusBarView, weatherViewModel: WeatherViewModel) {
        // Configura lo sfondo e le ombre
        styleStatusBar(statusBar)

        // Inizializza e configura tutti i componenti interni
        // (Questo metodo può essere espanso se necessario)
    }
    
    enum TextStyle {
        case regular
        case medium
        case semibold
    }
    
    static func applyTextStyle(to label: UILabel, style: TextStyle, alignment: NSTextAlignment = .left) {
        // Imposta il font base
        switch style {
        case .regular:
            label.font = Fonts.regular(size: 14)
        case .medium:
            label.font = Fonts.medium(size: 14)
        case .semibold:
            label.font = Fonts.semibold(size: 14)
        }

        // Imposta l'allineamento
        label.textAlignment = alignment

        // Imposta le proprietà di stile avanzate attraverso attributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2 // Line height 120%

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .kern: -0.14, // Letter spacing -1%
            .font: label.font!,
            .foregroundColor: label.textColor
        ]

        // Preserva il testo ma applica gli attributi
        let currentText = label.text ?? ""
        label.attributedText = NSAttributedString(string: currentText, attributes: attributes)
    }

    // MARK: - Colors
    struct Colors {
        static let background = UIColor(hex: "#111111")
        static let weatherYellow = UIColor(hex: "#FAC608")
        static let weatherYellowShadow = UIColor(hex: "#FAC608", alpha: 0.5)
        static let innerShadow = UIColor(hex: "#F3F3F3", alpha: 0.25)
        static let precipitationBlue = UIColor(hex: "#4D90D5")
        static let textWhite = UIColor.white
        static let textBlack = UIColor.black
        static let lightBackground = UIColor(hex: "#F3F3F3", alpha: 0.7) // #F3F3F3B2
    }
    // MARK: - Fonts
    struct Fonts {
        static func regular(size: CGFloat) -> UIFont {
            // Verifica se Switzer è disponibile, altrimenti usa un font di sistema
            if let customFont = UIFont(name: "Switzer-Regular", size: size) {
                return customFont
            }
            return UIFont.systemFont(ofSize: size)
        }

        static func medium(size: CGFloat) -> UIFont {
            if let customFont = UIFont(name: "Switzer-Medium", size: size) {
                return customFont
            }
            return UIFont.systemFont(ofSize: size, weight: .medium)
        }

        static func semibold(size: CGFloat) -> UIFont {
            if let customFont = UIFont(name: "Switzer-SemiBold", size: size) {
                return customFont
            }
            return UIFont.systemFont(ofSize: size, weight: .semibold)
        }
    }

    // MARK: - Container Styling
    static func styleWeatherContainer(_ container: UIView) {
        // Dimensioni e bordi
        container.layer.cornerRadius = 8

        // Sfondi
        container.backgroundColor = Colors.weatherYellow

        // Ombre
        container.layer.shadowColor = Colors.weatherYellowShadow.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 0)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 1.0

        // Ombra interna (simulata con un layer aggiuntivo)
        let innerShadowLayer = CALayer()
        innerShadowLayer.frame = container.bounds
        innerShadowLayer.backgroundColor = UIColor.clear.cgColor
        innerShadowLayer.shadowColor = Colors.innerShadow.cgColor
        innerShadowLayer.shadowOffset = CGSize(width: 0, height: 1)
        innerShadowLayer.shadowOpacity = 1.0
        innerShadowLayer.shadowRadius = 2
        innerShadowLayer.cornerRadius = 8
        innerShadowLayer.masksToBounds = false

        // Aggiungi maschera per l'ombra interna
        let path = UIBezierPath(roundedRect: container.bounds.insetBy(dx: -20, dy: -20),
                                cornerRadius: 8)
        let cutout = UIBezierPath(roundedRect: container.bounds, cornerRadius: 8).reversing()
        path.append(cutout)

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        innerShadowLayer.mask = mask

        container.layer.addSublayer(innerShadowLayer)
    }

    static func stylePrecipitationContainer(_ container: UIView) {
        container.layer.cornerRadius = 8
        container.backgroundColor = UIColor.clear
    }
}
