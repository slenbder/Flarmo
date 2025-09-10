//
//  DefaultNotificationsScheduler.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/10/25.
//

import Foundation
import UserNotifications

/// Временная реализация, чтобы не падала сборка после удаления легаси.
/// TODO: заменить на реальный планировщик расписаний.
final class DefaultNotificationsScheduler: NotificationsScheduling {
    func rescheduleAllIfNeeded() {
        // no-op до подключения реального планировщика
    }
}
