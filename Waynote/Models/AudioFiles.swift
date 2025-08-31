//
//  AudioFiles.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import Foundation
import os

enum AudioFiles {
    static let directoryName = "AudioFiles"

    static var baseURL: URL {
        let directory = URL.documentsDirectory.appending(
            path: directoryName,
            directoryHint: .isDirectory
        )
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            AppLogging.general.error("Failed to create directory: \(error.localizedDescription)")
        }
        return directory
    }

    static func url(for fileName: String) -> URL {
        baseURL.appending(path: fileName, directoryHint: .notDirectory)
    }
}
