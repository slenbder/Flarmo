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
    private var calendar: Calendar = { var cal = Calendar.current; cal.timeZone = .current; return cal }()
    private static let isoFormatter: ISO8601DateFormatter = { let f = ISO8601DateFormatter(); f.timeZone = .current; f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }()
    private let queue = DispatchQueue(label: "notif.scheduler.v2")
    private var pendingWork: DispatchWorkItem?
    init(calc: ScheduleCalculating = ScheduleCalculator()) { self.calc = calc }

    func reschedule(for schedules: [Schedule]) {
        queue.async {
            let thread = Thread.isMainThread ? "main" : "bg"
            print("[NotificationScheduler] reschedule request: count=\(schedules.count) on thread=\(thread)")
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
            print("[NotificationScheduler] total pending before purge: \(pending.count)")
            print("[NotificationScheduler] Removing old v2 notifications: count=\(ourIds.count)")

            self?.center.removePendingNotificationRequests(withIdentifiers: ourIds)
            self?.scheduleNew(for: schedules)
        }
    }

    private func scheduleNew(for schedules: [Schedule]) {
        let active = schedules.filter { $0.isActive }
        guard !active.isEmpty else { return }
        for s in active {
            let nexts = calc.nextTriggers(for: s, limit: 8, from: Date())
            guard !nexts.isEmpty else { continue }
            print("[NotificationScheduler] \(s.name) → scheduling \(nexts.count) triggers")
            for date in nexts {
                let triggerDate = date
                if triggerDate <= Date() { continue }
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute, .second], from: triggerDate),
                    repeats: false
                )
                let content = UNMutableNotificationContent()
                content.title = s.name
                content.body = "Будильник"
                content.sound = s.toneId != nil
                    ? UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(s.toneId!).caf"))
                    : .default
                content.categoryIdentifier = "ALARM_CATEGORY"

                let id = "sched_\(s.id.uuidString)_\(Int(triggerDate.timeIntervalSince1970))"
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(req) { error in
                    if let error = error {
                        print("[NotificationScheduler] ❌ add id=\(id) ts=\(Self.isoFormatter.string(from: triggerDate)) error=\(error)")
                    } else {
                        print("[NotificationScheduler] ✅ scheduled id=\(id) ts=\(Self.isoFormatter.string(from: triggerDate)) name=\(s.name)")
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
