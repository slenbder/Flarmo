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
    private let center = UNUserNotificationCenter.current()
    private let calc: ScheduleCalculating
    init(calc: ScheduleCalculating = ScheduleCalculator()) { self.calc = calc }

    func reschedule(for schedules: [Schedule]) {
            print("[NotificationScheduler] Rescheduling for \(schedules.count) schedules")
            center.getPendingNotificationRequests { [weak self] pending in
                let ourIds = pending
                    .map(\.identifier)
                    .filter { $0.hasPrefix("sched_") }
                print("[NotificationScheduler] Removing \(ourIds.count) old v2 notifications")

                self?.center.removePendingNotificationRequests(withIdentifiers: ourIds)
                self?.scheduleNew(for: schedules)
            }
        }

    private func scheduleNew(for schedules: [Schedule]) {
            for s in schedules where s.isActive {
                let nexts = calc.nextTriggers(for: s, limit: 8, from: Date())
                print("[NotificationScheduler] \(s.name) → scheduling \(nexts.count) triggers")
                for date in nexts {
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: Calendar.current.dateComponents(
                            [.year,.month,.day,.hour,.minute,.second], from: date),
                        repeats: false
                    )
                    let content = UNMutableNotificationContent()
                    content.title = s.name
                    content.body = "Будильник"
                    content.sound = s.toneId != nil
                        ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(s.toneId!).caf"))
                        : .default

                    let id = "sched_\(s.id.uuidString)_\(Int(date.timeIntervalSince1970))"
                    let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(req) { error in
                        if let error = error {
                            print("[NotificationScheduler] Failed to add \(id): \(error)")
                        } else {
                            print("[NotificationScheduler] Scheduled \(id) at \(date)")
                        }
                    }
                }
            }
        }
}
