//
//  ViewControllerPreview.swift
//  Fitly
//
//  Created by Bakdaulet Yeskermes on 23.10.2025.
//

import SwiftUI
import UIKit

@available(iOS 13.0, *)
struct ViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: ViewController

    init(_ builder: @escaping () -> ViewController) {
        viewController = builder()
    }

    func makeUIViewController(context: Context) -> ViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}
