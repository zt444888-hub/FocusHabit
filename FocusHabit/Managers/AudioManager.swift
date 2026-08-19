import Foundation
import AVFoundation

@MainActor
@Observable
final class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    private(set) var isPlaying = false
    private(set) var currentSound: AmbientSound?

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            NSLog("[FocusHabit Audio] Audio session setup failed: %@", error.localizedDescription)
        }
    }

    enum AmbientSound: String, CaseIterable, Identifiable {
        case rain
        case ocean
        case whitenoise
        case forest

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .rain: T("Rain")
            case .ocean: T("Ocean Waves")
            case .whitenoise: T("White Noise")
            case .forest: T("Forest")
            }
        }

        var icon: String {
            switch self {
            case .rain: return "cloud.rain"
            case .ocean: return "water.waves"
            case .whitenoise: return "circle.hexagongrid"
            case .forest: return "tree.fill"
            }
        }
    }

    func play(_ sound: AmbientSound) {
        stop()
        configureAudioSession()

        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            NSLog("[FocusHabit Audio] File not found: %@.mp3", sound.rawValue)
            return
        }

        do {
            // AVAudioPlayer 对"循环播放单个音频文件"更轻量：无 AVAudioEngine 图开销，内存占用低
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = 0.8
            p.play()
            player = p
            isPlaying = true
            currentSound = sound
        } catch {
            NSLog("[FocusHabit Audio] Playback error: %@", error.localizedDescription)
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentSound = nil
    }

    func toggle(_ sound: AmbientSound) {
        if currentSound == sound && isPlaying {
            stop()
        } else {
            play(sound)
        }
    }
}
