import UIKit
import CoreData

extension Notification.Name {
    static let userRegistered = Notification.Name("userRegistered")
}

class RegisterViewController: UIViewController {

    private let usernameField: UITextField = {
        let f = UITextField()
        f.placeholder = "Имя пользователя"
        f.borderStyle = .roundedRect
        f.autocapitalizationType = .none
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    private let passwordField: UITextField = {
        let f = UITextField()
        f.placeholder = "Пароль"
        f.borderStyle = .roundedRect
        f.isSecureTextEntry = true
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    private let confirmField: UITextField = {
        let f = UITextField()
        f.placeholder = "Повторите пароль"
        f.borderStyle = .roundedRect
        f.isSecureTextEntry = true
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()



    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Регистрация"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        setupViews()
    }

    private func setupViews() {
        view.addSubview(usernameField)
        view.addSubview(passwordField)
        view.addSubview(confirmField)


        NSLayoutConstraint.activate([
            usernameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usernameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            usernameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),

            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: usernameField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: usernameField.trailingAnchor),

            confirmField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 12),
            confirmField.leadingAnchor.constraint(equalTo: usernameField.leadingAnchor),
            confirmField.trailingAnchor.constraint(equalTo: usernameField.trailingAnchor),

        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }



    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "ОК", style: .default))
        present(a, animated: true)
    }
}
