//
//  NotificationCategoriesRegistrar.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/10/25.
//

import UserNotifications

enum NotificationCategoriesRegistrar {
    static func register() {
        // Пример: категории для будильника
        let stop = UNNotificationAction(identifier: "ALARM_STOP", title: "Стоп", options: [.destructive])
        let snooze = UNNotificationAction(identifier: "ALARM_SNOOZE", title: "Повтор через 10 мин", options: [])

        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_ACTIONS",
            actions: [stop, snooze],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
}
