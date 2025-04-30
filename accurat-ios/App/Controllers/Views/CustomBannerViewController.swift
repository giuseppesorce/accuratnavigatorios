import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class CustomBottomBannerViewController: BottomBannerViewController {

    // La tua custom view
    lazy var miaCustomView: MiaCustomView = {
        let view = MiaCustomView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Aggiungi la tua custom view dopo che il layout di base è stato impostato
        setupMiaCustomView()
    }

    private func setupMiaCustomView() {
        // Aggiungi la tua view al bottom banner
        bottomBannerView.addSubview(miaCustomView)

        // Definisci i vincoli per la tua view
        let constraints = [
            // Posiziona sotto gli elementi esistenti
            miaCustomView.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor, constant: 8),
            miaCustomView.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor, constant: 8),
            miaCustomView.trailingAnchor.constraint(equalTo: verticalDividerView.leadingAnchor, constant: -8),
            miaCustomView.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor, constant: -8),
            miaCustomView.heightAnchor.constraint(equalToConstant: 40) // Altezza personalizzabile
        ]

        NSLayoutConstraint.activate(constraints)

        // Aggiorna l'altezza del banner per accomodare la nuova view
        let heightConstraint = bottomBannerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 140)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }
}

// La tua custom view
class MiaCustomView: UIView {
    // Aggiungi qui i tuoi elementi UI
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .systemBlue.withAlphaComponent(0.2)
        layer.cornerRadius = 8

        // Configura label di esempio
        label.text = "Informazioni personalizzate"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .darkText
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }

    // Metodo per aggiornare il contenuto della view
    func updateContent(with text: String) {
        label.text = text
    }
}
