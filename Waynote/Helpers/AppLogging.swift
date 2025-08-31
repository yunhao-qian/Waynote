//
//  AppLogging.swift
//  Waynote
//
//  Created by Yunhao Qian on 8/31/25.
//

import Foundation
import os

enum AppLogging {
    static let general = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "general")
}
