//
//  NotificationSchedulerV2.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation
import UserNotifications

protocol NotificationsScheduling {
    func reschedule(for schedules: [Schedule])
}

final class NotificationSchedulerV2: NotificationsScheduling {
    /// Легаси-класс. Оставлен как заглушка, чтобы старые вызовы не ломали поведение.
    /// Фактическое планирование делается через NotificationPlanner (этап E).

    init() {}

    func reschedule(for schedules: [Schedule]) {
        // no-op: пересчёт теперь выполняет NotificationPlanner.
        // Оставлено пустым намеренно, чтобы не плодить дубли «sched_*» и не путать логи.
    }

    static func registerCategories() {
        let snooze = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Отложить", options: [])
        let stop = UNNotificationAction(identifier: "STOP_ACTION", title: "Выключить", options: [.destructive])
        let category = UNNotificationCategory(identifier: "ALARM_CATEGORY", actions: [snooze, stop], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
