//
//  ScheduleCalculator.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

protocol ScheduleCalculating {
    func nextTriggers(for item: Schedule, limit: Int, from: Date) -> [Date]
}

final class ScheduleCalculator: ScheduleCalculating {
    private let calendar: Calendar
    init(calendar: Calendar = .current) {
        var cal = calendar
        cal.locale = .current
        cal.timeZone = .current
        self.calendar = cal
    }

    func nextTriggers(for item: Schedule, limit: Int = 5, from: Date = Date()) -> [Date] {
        guard item.isActive else { return [] }
        switch item.type {
        case .oneTime(let date):
            return date >= from ? [date] : []
        case .customDates(let arr):
            return arr.filter { $0 >= from }.sorted().prefix(limit).map { $0 }
        case .weekdays(let days, let time):
            return nextWeekdays(days: days, time: time, limit: limit, from: from)
        case .shiftPattern(let start, let on, let off, let time):
            return nextShift(start: start, onDays: on, offDays: off, time: time, limit: limit, from: from)
        }
    }

    private func date(bySetting time: TimeOfDay, on day: Date) -> Date? {
        calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
    }

    private func nextWeekdays(days: Set<Weekday>, time: TimeOfDay, limit: Int, from: Date) -> [Date] {
        guard !days.isEmpty else { return [] }
        var results: [Date] = []
        var cursor = from

        let maxSteps = 8 * 7
        for _ in 0..<maxSteps where results.count < limit {
            let wdRaw = calendar.component(.weekday, from: cursor)
            if let wd = Weekday(rawValue: wdRaw), days.contains(wd),
               let dt = date(bySetting: time, on: cursor), dt >= from {
                results.append(dt)
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: cursor))!
        }
        return Array(results.prefix(limit)).sorted()
    }

    private func nextShift(start: Date, onDays: Int, offDays: Int, time: TimeOfDay, limit: Int, from: Date) -> [Date] {
        guard onDays > 0 && offDays >= 0 else { return [] }
        let cycle = onDays + offDays
        var results: [Date] = []

        let startDay = calendar.startOfDay(for: start)
        let fromDay = calendar.startOfDay(for: from)

        let diff = calendar.dateComponents([.day], from: startDay, to: fromDay).day ?? 0
        var dayIndex = diff >= 0 ? diff % cycle : (cycle + (diff % cycle)) % cycle

        var dayCursor = fromDay

        while results.count < limit {
            if dayIndex < onDays, let dt = date(bySetting: time, on: dayCursor) {
                if dt >= from { results.append(dt) }
            }
            dayIndex = (dayIndex + 1) % cycle
            dayCursor = calendar.date(byAdding: .day, value: 1, to: dayCursor)!
        }
        return results
    }
}
