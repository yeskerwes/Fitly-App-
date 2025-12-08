//
//  Push.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 08.12.2025.
//

import Foundation

protocol PushupCameraDelegate: AnyObject {
    func pushupSessionDidFinish(count: Int)
    func pushupSessionDidCancel()
}
