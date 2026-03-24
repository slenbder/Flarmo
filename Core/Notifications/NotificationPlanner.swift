//
//  NotificationPlanner.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/9/25.
//

import Foundation
import UserNotifications

protocol UserNotificationCentering {
    func add(_ request: UNNotificationRequest)
    func getPendingIDs(completion: @escaping (Set<String>) -> Void)
    func remove(withIDs ids: [String])
}

extension UNUserNotificationCenter: UserNotificationCentering {
    func add(_ request: UNNotificationRequest) {
        add(request, withCompletionHandler: nil)
    }
    func getPendingIDs(completion: @escaping (Set<String>) -> Void) {
        getPendingNotificationRequests { reqs in
            completion(Set(reqs.map(\.identifier)))
        }
    }
    func remove(withIDs ids: [String]) {
        removePendingNotificationRequests(withIdentifiers: ids)
    }
}

protocol RecurrenceCalculating {
    /// Возвращает массив ближайших дат по типу расписания в заданном окне
    func nextOccurrences(for schedule: Schedule, from start: Date, until end: Date, limit: Int?) -> [Date]
}

protocol NotificationPlanning {
    /// Полный пересчёт для всех расписаний
    func planAll(schedules: [Schedule])
    /// Точечный пересчёт для одного расписания (по месту сохранения/изменения)
    /// Вариант по-умолчанию: подтягивает provider, чтобы соблюдать глобальный лимит.
    func plan(for schedule: Schedule)
}

final class NotificationPlanner: NotificationPlanning {
    private let calculator: RecurrenceCalculating
    private let registry: NotificationRegistry
    private let center: UserNotificationCentering
    private let nowProvider: () -> Date
    private let queue = DispatchQueue(label: "notification-planner.queue", qos: .userInitiated)

    /// Опциональный провайдер «всех актуальных расписаний», чтобы в `plan(for:)` можно было удерживать глобальный лимит 60.
    private let allSchedulesProvider: (() -> [Schedule])?

    // MARK: - Debug helper
    private let debugEnabled: Bool = true
    private func log(_ message: @autoclosure () -> String) {
        guard debugEnabled else { return }
        print("[Planner] " + message())
    }

    init(
        calculator: RecurrenceCalculating,
        registry: NotificationRegistry,
        center: UserNotificationCentering = UNUserNotificationCenter.current(),
        nowProvider: @escaping () -> Date = Date.init,
        allSchedulesProvider: (() -> [Schedule])? = nil
    ) {
        self.calculator = calculator
        self.registry = registry
        self.center = center
        self.nowProvider = nowProvider
        self.allSchedulesProvider = allSchedulesProvider
    }

    func planAll(schedules: [Schedule]) {
        queue.async {
            self._planAll(schedules: schedules)
        }
    }

    func plan(for schedule: Schedule) {
        // Если есть провайдер — делаем глобальный пересчёт, чтобы гарантировать лимит 60.
        if let provider = allSchedulesProvider {
            planAll(schedules: provider())
            return
        }
        // Иначе — делаем точечный пересчёт (может слегка превышать глобальный лимит в редком кейсе).
        queue.async {
            self._planOnly(schedule: schedule)
        }
    }

    // MARK: - Private

    private func _planAll(schedules: [Schedule]) {
        let now = nowProvider()
        let windowEnd = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now.addingTimeInterval(30*24*3600)
        let maxTotal = 60

        log("planAll: input schedules=\(schedules.count)")

        center.getPendingIDs { systemIDs in
            self.log("system pending snapshot=\(systemIDs.count)")

            // Самоисцеление реестра: выкинуть несуществующие
            self.registry.reloadFromSystemSnapshot(systemIDs)

            // 1) Активные расписания
            let active = schedules.filter { $0.isActive }
            self.log("active schedules=\(active.count)")

            // 2) Собрать кандидатов: (schedule, date, id)
            var candidates: [(Schedule, Date, String)] = []
            candidates.reserveCapacity(128)

            for s in active {
                let dates = self.calculator.nextOccurrences(for: s, from: now, until: windowEnd, limit: nil)
                for d in dates {
                    let id = self.makeID(scheduleID: s.id.uuidString, fireDate: d)
                    candidates.append((s, d, id))
                }
            }

            self.log("candidates total=\(candidates.count)")

            // 3) Глобальный лимит 60 — обрезаем по ближайшим датам
            candidates.sort { $0.1 < $1.1 }
            let desired = candidates.prefix(maxTotal)
            let desiredIDs: Set<String> = Set(desired.map { $0.2 })
            self.log("desired after cap(\(maxTotal))=\(desired.count)")

            // 4) Текущее известное состояние
            let currentKnown = self.registry.ids.intersection(systemIDs)

            // 5) Посчитать разницу множеств
            let toAdd = desiredIDs.subtracting(currentKnown)
            let toRemove = currentKnown.subtracting(desiredIDs)

            self.log("toAdd=\(toAdd.count), toRemove=\(toRemove.count)")

            // 6) Снять устаревшие
            if !toRemove.isEmpty {
                self.center.remove(withIDs: Array(toRemove))
                self.registry.remove(toRemove)
                self.log("removed old ids=\(toRemove.count)")
            }

            // 7) Добавить недостающие
            if !toAdd.isEmpty {
                for (schedule, date, id) in desired where toAdd.contains(id) {
                    let req = NotificationFactory.makeRequest(schedule: schedule, fireDate: date, id: id)
                    self.center.add(req)
                }
                self.registry.add(toAdd)
                self.log("added new ids=\(toAdd.count)")
            }
        }
    }

    private func _planOnly(schedule: Schedule) {
        let now = nowProvider()
        let windowEnd = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now.addingTimeInterval(30*24*3600)

        log("planOnly: schedule=\(schedule.id) name=\(schedule.name)")

        center.getPendingIDs { systemIDs in
            self.log("system pending snapshot=\(systemIDs.count)")

            self.registry.reloadFromSystemSnapshot(systemIDs)

            // Снять все старые ID этого расписания, которых не будет в новом наборе
            let prefix = "flarmo.\(schedule.id.uuidString)."

            // Новый набор ID (без глобального капа здесь)
            let dates = self.calculator.nextOccurrences(for: schedule, from: now, until: windowEnd, limit: nil)
            let newIDs: Set<String> = Set(dates.map { self.makeID(scheduleID: schedule.id.uuidString, fireDate: $0) })

            self.log("newIDs for schedule=\(newIDs.count)")

            let existingForSchedule = self.registry.ids.intersection(systemIDs).filter { $0.hasPrefix(prefix) }
            let toRemove = existingForSchedule.subtracting(newIDs)

            self.log("toRemove for schedule=\(toRemove.count)")

            if !toRemove.isEmpty {
                self.center.remove(withIDs: Array(toRemove))
                self.registry.remove(toRemove)
                self.log("removed ids=\(toRemove.count)")
            }

            // Добавить недостающие
            let toAdd = newIDs.subtracting(existingForSchedule)

            self.log("toAdd for schedule=\(toAdd.count)")

            if !toAdd.isEmpty {
                for (date, id) in zip(dates, dates.map { self.makeID(scheduleID: schedule.id.uuidString, fireDate: $0) }) {
                    if toAdd.contains(id) {
                        let req = NotificationFactory.makeRequest(schedule: schedule, fireDate: date, id: id)
                        self.center.add(req)
                    }
                }
                self.registry.add(toAdd)
                self.log("added ids=\(toAdd.count)")
            }
        }
    }

    private func makeID(scheduleID: String, fireDate: Date) -> String {
        let stamp = Self.idFormatter.string(from: fireDate)
        return "flarmo.\(scheduleID).\(stamp)"
    }
}

private extension NotificationPlanner {
    static let idFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyyMMdd'T'HHmmZ"
        return df
    }()
}

