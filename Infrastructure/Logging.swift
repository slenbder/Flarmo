//
//  Logging.swift
//  Flarmo
//

import OSLog

private let subsystem = "com.Slenbder.Flarmo"

extension Logger {
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let repository    = Logger(subsystem: subsystem, category: "repository")
    static let recurrence    = Logger(subsystem: subsystem, category: "recurrence")
    static let ui            = Logger(subsystem: subsystem, category: "ui")
    static let lifecycle     = Logger(subsystem: subsystem, category: "lifecycle")
}
