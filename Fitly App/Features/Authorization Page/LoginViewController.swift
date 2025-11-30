import UIKit
import CoreData

class LoginViewController: UIViewController {

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



    private let goToRegisterButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Регистрация", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Вход"
        setupViews()
    }

    private func setupViews() {
        view.addSubview(usernameField)
        view.addSubview(passwordField)
        view.addSubview(goToRegisterButton)

        goToRegisterButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            usernameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usernameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            usernameField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),

            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: usernameField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: usernameField.trailingAnchor),

            goToRegisterButton.leadingAnchor.constraint(equalTo: usernameField.leadingAnchor),
            goToRegisterButton.trailingAnchor.constraint(equalTo: usernameField.trailingAnchor),
            goToRegisterButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }



    @objc private func registerTapped() {
        let registerVC = RegisterViewController()
        let nav = UINavigationController(rootViewController: registerVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true, completion: nil)
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "ОК", style: .default))
        present(a, animated: true)
    }
}
