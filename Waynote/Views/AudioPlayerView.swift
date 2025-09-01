//
//  AudioPlayerView.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import AVFAudio
import Combine
import SwiftUI
import os

struct AudioPlayerView: View {
    let content: AudioNoteContent

    @State private var isPlaying: Bool = false
    @State private var progress: TimeInterval = 0
    @State private var player: AVAudioPlayer? = nil
    @State private var wasPlayingBeforeSliderEdit: Bool = false

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        let playPauseButtonSize: CGFloat = 32
        let forwardBackButtonSize: CGFloat = 24

        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 8) {
                Text(formatTime(0))
                    .monospacedDigit()
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: $progress,
                    in: 0...(content.duration > 0 ? content.duration : 1)
                ) { isEditing in
                    if isEditing {
                        wasPlayingBeforeSliderEdit = isPlaying
                        pause()
                    } else if wasPlayingBeforeSliderEdit {
                        play()
                    }
                }
                Text(formatTime(content.duration))
                    .monospacedDigit()
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(formatTime(progress))
                .monospacedDigit()
                .font(.title)
                .fontWeight(.bold)
            HStack(spacing: 48) {
                // buttonStyle is required for correct hit testing:
                // https://stackoverflow.com/a/59402642
                Button {
                    seek(to: progress - 15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .resizable()
                        .scaledToFit()
                        .frame(width: forwardBackButtonSize, height: forwardBackButtonSize)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back 15 seconds")
                Button {
                    if isPlaying {
                        if let player {
                            progress = player.currentTime
                        }
                        pause()
                    } else {
                        play()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: playPauseButtonSize, height: playPauseButtonSize)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
                Button {
                    seek(to: progress + 15)
                } label: {
                    Image(systemName: "goforward.15")
                        .resizable()
                        .scaledToFit()
                        .frame(width: forwardBackButtonSize, height: forwardBackButtonSize)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Forward 15 seconds")
            }
        }
        .onReceive(timer) { _ in
            guard let player, isPlaying else {
                return
            }
            progress = player.currentTime
            if !player.isPlaying {
                pause()
            }
        }
        .onDisappear {
            player?.stop()
            player = nil
        }
    }

    private func play() {
        guard !isPlaying else {
            return
        }
        if player == nil {
            do {
                player = try AVAudioPlayer(contentsOf: content.fileURL)
            } catch {
                AppLogging.general.error(
                    "Failed to initialize AVAudioPlayer: \(error.localizedDescription)"
                )
            }
        }
        guard let player else {
            return
        }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            AppLogging.general.error(
                "Failed to set up audio session: \(error.localizedDescription)"
            )
            return
        }
        player.currentTime = progress
        player.play()
        isPlaying = true
    }

    private func pause() {
        player?.pause()
        isPlaying = false
    }

    private func seek(to time: TimeInterval) {
        let wasPlaying = isPlaying
        pause()
        progress = min(max(0, time), content.duration)
        if wasPlaying {
            play()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let int = Int(time)
        let minutes = int / 60
        let seconds = int % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    AudioPlayerView(content: AudioNoteContent(fileName: "foo.m4a"))
}
