import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognitionService: ObservableObject, @unchecked Sendable {
    static let shared = SpeechRecognitionService()

    @Published var isRecording = false
    @Published var transcript = ""

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var onTranscriptFinished: (@MainActor (String) -> Void)?

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startRecording(onFinished: @escaping @MainActor (String) -> Void) {
        guard !isRecording else { return }
        onTranscriptFinished = onFinished
        transcript = ""

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        guard let speechRecognizer, speechRecognizer.isAvailable else { return }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.cleanupRecording()
                }
            }
        }

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let bufferRequest = request
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            bufferRequest.append(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
            audioEngine = engine
            recognitionRequest = request
            isRecording = true
        } catch {
            cleanupRecording()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        let finalTranscript = transcript
        cleanupRecording()
        if !finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onTranscriptFinished?(finalTranscript)
        }
        onTranscriptFinished = nil
    }

    private func cleanupRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
