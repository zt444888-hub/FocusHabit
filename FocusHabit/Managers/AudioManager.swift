import Foundation
import AVFoundation

@MainActor
@Observable
final class AudioManager {
    static let shared = AudioManager()
    private var engine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private(set) var isPlaying = false
    private(set) var currentSound: AmbientSound?
    
    private init() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        configureAudioSession()
        NSLog("[FocusHabit Audio] AudioManager initialized with AVAudioEngine")
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            NSLog("[FocusHabit Audio] Audio session configured for playback")
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
        NSLog("[FocusHabit Audio] Found file: %@", url.lastPathComponent)
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let capacity = AVAudioFrameCount(audioFile.length)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
                NSLog("[FocusHabit Audio] Failed to create PCM buffer")
                return
            }
            try audioFile.read(into: buffer)
            NSLog("[FocusHabit Audio] Loaded buffer: %d frames", buffer.frameLength)
            
            // Schedule with looping on the already-attached player node
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            
            if !engine.isRunning {
                try engine.start()
            }
            
            playerNode.volume = 0.8
            playerNode.play()
            
            NSLog("[FocusHabit Audio] Engine playing: %@", sound.rawValue)
            isPlaying = true
            currentSound = sound
            
        } catch {
            NSLog("[FocusHabit Audio] Engine error: %@", error.localizedDescription)
        }
    }
    
    func stop() {
        playerNode.stop()
        isPlaying = false
        currentSound = nil
        NSLog("[FocusHabit Audio] Stopped")
    }
    

    
    func toggle(_ sound: AmbientSound) {
        if currentSound == sound && isPlaying {
            stop()
        } else {
            play(sound)
        }
    }
    
}
