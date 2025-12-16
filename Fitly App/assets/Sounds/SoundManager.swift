//
//  SoundManager.swift
//  Fitly App
//
//  Created by Bakdaulet Yeskermes on 12.12.2025.
//

import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    private var dingPlayer: AVAudioPlayer?
    private var successPlayer: AVAudioPlayer?

    private func urlForSound(named name: String) -> URL? {
        let exts = ["mp3", "m4a"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            return url
        }
        return nil
    }

    func prepareSounds(dingName: String = "ding", successName: String = "success") {
        if dingPlayer == nil, let u = urlForSound(named: dingName) {
            do {
                dingPlayer = try AVAudioPlayer(contentsOf: u)
                dingPlayer?.volume = 1.0
                dingPlayer?.numberOfLoops = 0
                dingPlayer?.prepareToPlay()
            } catch {
                print("SoundManager: failed to prepare ding:", error)
            }
        }

        if successPlayer == nil, let u = urlForSound(named: successName) {
            do {
                successPlayer = try AVAudioPlayer(contentsOf: u)
                successPlayer?.volume = 1.0
                successPlayer?.numberOfLoops = 0
                successPlayer?.prepareToPlay()
            } catch {
                print("SoundManager: failed to prepare success:", error)
            }
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("SoundManager: AVAudioSession error:", error)
        }
    }

    func playDing() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.dingPlayer == nil {
                self.prepareSounds()
            }
            DispatchQueue.main.async {
                self.dingPlayer?.currentTime = 0
                self.dingPlayer?.play()
            }
        }
    }

    func playSuccess() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.successPlayer == nil {
                self.prepareSounds()
            }
            DispatchQueue.main.async {
                self.successPlayer?.currentTime = 0
                self.successPlayer?.play()
            }
        }
    }
}
