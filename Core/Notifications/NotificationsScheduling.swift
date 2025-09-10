//
//  NotificationsScheduling.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/10/25.
//

import Foundation

/// Контракт для модуля планирования локальных уведомлений.
protocol NotificationsScheduling: AnyObject {
    /// Рескейдлить все уведомления на основе текущего состояния расписаний.
    func rescheduleAllIfNeeded()
}
