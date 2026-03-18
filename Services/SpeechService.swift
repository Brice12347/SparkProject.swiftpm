import AVFoundation
import Combine

@MainActor
class SpeechService: NSObject, ObservableObject, @unchecked Sendable {
    static let shared = SpeechService()

    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private var voiceSpeed: VoiceSpeed = .normal
    private var speechQueue: [String] = []

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    func setSpeed(_ speed: VoiceSpeed) {
        voiceSpeed = speed
    }

    /// Stops any current speech, clears the queue, and speaks the full text immediately.
    /// Used for error fallback paths and single-shot speech (e.g. lesson feedback).
    func speak(_ text: String) {
        speechQueue.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
        speakImmediate(text)
    }

    /// Queues a single sentence for playback. If nothing is currently speaking,
    /// it starts immediately; otherwise it waits until the current utterance finishes.
    func enqueueSentence(_ sentence: String) {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synthesizer.isSpeaking {
            speechQueue.append(trimmed)
        } else {
            speakImmediate(trimmed)
        }
    }

    func stop() {
        speechQueue.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func speakImmediate(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = voiceSpeed.rate
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    private func dequeueNext() {
        guard !speechQueue.isEmpty else {
            isSpeaking = false
            return
        }
        let next = speechQueue.removeFirst()
        speakImmediate(next)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session config failed silently
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.dequeueNext()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.speechQueue.removeAll()
            self.isSpeaking = false
        }
    }
}
