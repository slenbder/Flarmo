//
//  NotificationFactory.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/9/25.
//

import Foundation
import UserNotifications

struct NotificationFactory {
    static func makeRequest(schedule: Schedule, fireDate: Date, id: String) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = schedule.name
        // В body выносим тип и время срабатывания
        content.body = makeBody(for: schedule, fireDate: fireDate)
        content.sound = .default

        // Важно: использовать календарные компоненты пользователя (часовой пояс/ DST)
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    private static func makeBody(for schedule: Schedule, fireDate: Date) -> String {
        // Небольшой, но полезный body — локализованный «во столько-то»
        let when = bodyFormatter.string(from: fireDate)

        switch schedule.type {
        case .oneTime:
            return "Разовый будильник — \(when)"
        case .weekdays:
            return "Будни — \(when)"
        case .shiftPattern:
            return "Сменный график — \(when)"
        case .customDates:
            return "Выбранные даты — \(when)"
        }
    }

    private static let bodyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.doesRelativeDateFormatting = true
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()
}
