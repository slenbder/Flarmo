//
//  Date+Extensions.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation

extension Date {
    /// Формат: HH:mm (только время)
    func formattedTime() -> String {
        return Date.timeFormatter.string(from: self)
    }

    /// Формат: yyyy-MM-dd HH:mm (дата + время)
    func formattedDateTime() -> String {
        return Date.dateTimeFormatter.string(from: self)
    }

    /// Полный формат (например, для отладки)
    func formattedFull() -> String {
        return Date.fullFormatter.string(from: self)
    }
}

private extension Date {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current
        return formatter
    }()

    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = .current
        return formatter
    }()

    static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        formatter.timeZone = .current
        return formatter
    }()
}
