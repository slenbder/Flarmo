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
    private let queue = DispatchQueue(label: "notif.scheduler.v2")
    private var pendingWork: DispatchWorkItem?
    init(calc: ScheduleCalculating = ScheduleCalculator()) { self.calc = calc }

    func reschedule(for schedules: [Schedule]) {
        queue.async {
            guard !schedules.isEmpty else { return }
            self.pendingWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?._rescheduleNow(for: schedules)
            }
            self.pendingWork = work
            self.queue.asyncAfter(deadline: .now() + 0.15, execute: work)
        }
    }

    private func _rescheduleNow(for schedules: [Schedule]) {
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
                guard !nexts.isEmpty else { continue }
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
                    content.categoryIdentifier = "ALARM_CATEGORY"

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
    
    static func registerCategories() {
        let snooze = UNNotificationAction(identifier: "SNOOZE_ACTION", title: "Отложить", options: [])
        let stop = UNNotificationAction(identifier: "STOP_ACTION", title: "Выключить", options: [.destructive])
        let category = UNNotificationCategory(identifier: "ALARM_CATEGORY", actions: [snooze, stop], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
