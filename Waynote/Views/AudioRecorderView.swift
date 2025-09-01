//
//  AudioRecorderView.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import AVFAudio
import Combine
import SwiftUI
import os

struct AudioRecorderView: View {
    let content: AudioNoteContent

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var recordingStartDate = Date.distantPast
    @State private var recordingDuration: TimeInterval = 0
    @State private var recorder: AVAudioRecorder? = nil

    // https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-a-timer-with-swiftui
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var store: NoteStore {
        NoteStore(context: modelContext)
    }

    var body: some View {
        let circleSize: CGFloat = 64
        let squareCornerRadius: CGFloat = isRecording ? 4 : 28
        let squareSize: CGFloat = isRecording ? 32 : 52

        VStack(alignment: .center, spacing: 8) {
            Text("Audio Recording")
                .font(.headline)
            Divider()
            Spacer()
            if isRecording {
                Text(formatDuration(recordingDuration))
                    .monospacedDigit()
                    .font(.title)
                    .fontWeight(.bold)
            } else {
                Text("Start Audio Recording")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                if isRecording {
                    dismiss()
                } else {
                    Task {
                        await observeAudioInterruptions()
                    }
                    Task {
                        await startRecording()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(.gray, lineWidth: 4)
                        .frame(width: circleSize, height: circleSize)
                    RoundedRectangle(cornerRadius: squareCornerRadius)
                        .fill(.red)
                        .animation(.spring(response: 0.2), value: isRecording)
                        .frame(width: squareSize, height: squareSize)
                }
            }
            .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
        }
        .padding()
        .onReceive(timer) { date in
            if isRecording {
                recordingDuration = date.timeIntervalSince(recordingStartDate)
            }
        }
        .onDisappear {
            if isRecording {
                stopRecording()
            } else if let note = content.note {
                store.deleteNote(note)
            }
        }
    }

    @MainActor
    private func startRecording() async {
        let session = AVAudioSession.sharedInstance()
        guard await AVAudioApplication.requestRecordPermission() else {
            AppLogging.general.error("Microphone permission denied")
            return
        }
        do {
            try session.setCategory(.playAndRecord)
            try session.setActive(true)
        } catch {
            AppLogging.general.error(
                "Failed to set up audio session: \(error.localizedDescription)"
            )
            return
        }
        do {
            recorder = try AVAudioRecorder(
                url: content.fileURL,
                settings: [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 12000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                ]
            )
        } catch {
            AppLogging.general.error(
                "Failed to create audio recorder: \(error.localizedDescription)"
            )
            return
        }
        recorder?.record()
        isRecording = true
        recordingStartDate = .now
        recordingDuration = 0
    }

    private func stopRecording() {
        recorder?.stop()
        recorder = nil
        do {
            content.duration = try AVAudioPlayer(contentsOf: content.fileURL).duration
            AppLogging.general.info("Audio duration: \(content.duration) seconds")
        } catch {
            AppLogging.general.error("Failed to get audio duration: \(error.localizedDescription)")
        }
        store.saveNote(content.note!)
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            AppLogging.general.error(
                "Failed to deactivate audio session: \(error.localizedDescription)"
            )
        }
    }

    @MainActor
    private func observeAudioInterruptions() async {
        for await notification in NotificationCenter.default.notifications(
            named: AVAudioSession.interruptionNotification
        ) {
            guard let value = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: value)
            else {
                continue
            }
            if type == .began {
                dismiss()
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let int = Int(duration)
        let minutes = int / 60
        let seconds = int % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    AudioRecorderView(content: AudioNoteContent(fileName: "foo.m4a"))
}
