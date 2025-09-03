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
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: self)
    }
    
    /// Формат: yyyy-MM-dd HH:mm (дата + время)
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: self)
    }
    
    /// Полный формат (например, для отладки)
    func formattedFull() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        formatter.timeZone = .current
        return formatter.string(from: self)
    }
}
