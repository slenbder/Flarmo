//
//  RecurrenceCalculator.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/7/25.
//

import Foundation

public struct RecurrenceCalculator {
    public struct Config {
        public let calendar: Calendar
        public init(calendar: Calendar = Calendar.current) {
            var cal = calendar
            // Фиксируем таймзону календаря для детерминированных вычислений.
            if cal.timeZone != TimeZone.current {
                cal.timeZone = TimeZone.current
            }
            self.calendar = cal
        }
    }

    private let cfg: Config

    public init(config: Config = .init()) {
        self.cfg = config
    }

    /// Возвращает ближайшие возникновения для заданного расписания.
    ///
    /// - Parameters:
    ///   - schedule: расписание
    ///   - start: нижняя граница (включительно)
    ///   - limit: максимум элементов в выдаче (>0)
    ///   - until: верхняя граница (включительно). Если nil — без верхней границы
    ///
    /// - Note: и `from`, и `until` — включительные.
    public func nextOccurrences(for schedule: Schedule,
                                from start: Date,
                                limit: Int,
                                until: Date?) -> [Date] {
        guard limit > 0 else { return [] }

        switch schedule.type {
        case .oneTime(let date):
            return handleOneTime(date: date, from: start, limit: limit, until: until)

        case .weekdays(let days, let time):
            return handleWeekdays(days: days, time: time, from: start, limit: limit, until: until)

        case .shiftPattern(let startDate, let onDays, let offDays, let time):
            return handleShiftPattern(startDate: startDate, onDays: onDays, offDays: offDays, time: time,
                                      from: start, limit: limit, until: until)

        case .customDates(let dates):
            return handleCustom(dates: dates, from: start, limit: limit, until: until)
        }
    }
}

// MARK: - Private helpers
private extension RecurrenceCalculator {

    func isInRange(_ date: Date, from: Date, until: Date?) -> Bool {
        if let until { return date >= from && date <= until }
        return date >= from
    }

    func combine(day: Date, time: TimeOfDay) -> Date? {
        var comps = cfg.calendar.dateComponents([.year, .month, .day], from: day)
        comps.hour = time.hour
        comps.minute = time.minute
        comps.second = 0
        return cfg.calendar.date(from: comps)
    }

    func nextDay(from day: Date, adding days: Int = 1) -> Date {
        cfg.calendar.date(byAdding: .day, value: days, to: day)!
    }

    func startOfDay(_ date: Date) -> Date {
        cfg.calendar.startOfDay(for: date)
    }

    func weekdayIndex(_ date: Date) -> Int {
        // Calendar: 1 = Sun ... 7 = Sat
        cfg.calendar.component(.weekday, from: date)
    }

    // MARK: One-time
    func handleOneTime(date: Date, from: Date, limit: Int, until: Date?) -> [Date] {
        guard limit > 0, isInRange(date, from: from, until: until) else { return [] }
        return [date]
    }

    // MARK: Weekdays
    func handleWeekdays(days: Set<Weekday>, time: TimeOfDay, from: Date, limit: Int, until: Date?) -> [Date] {
        guard !days.isEmpty else { return [] }
        var result: [Date] = []
        var cursorDay = startOfDay(from)

        while result.count < limit {
            // Ранний выход по until (если день целиком уже за границей)
            if let until, startOfDay(cursorDay) > until { break }

            let wk = weekdayIndex(cursorDay)
            // Т.к. Weekday.rawValue совпадает с индексом Calendar, просто сверяем rawValue.
            if days.contains(where: { $0.rawValue == wk }),
               let candidate = combine(day: cursorDay, time: time),
               isInRange(candidate, from: from, until: until) {
                result.append(candidate)
            }

            cursorDay = nextDay(from: cursorDay)
        }

        return result
    }

    // MARK: Shift pattern
    func handleShiftPattern(startDate: Date,
                            onDays: Int,
                            offDays: Int,
                            time: TimeOfDay,
                            from: Date,
                            limit: Int,
                            until: Date?) -> [Date] {
        guard onDays > 0, offDays >= 0 else { return [] }
        let cycle = onDays + offDays
        guard cycle > 0 else { return [] }

        var result: [Date] = []
        var cursorDay = max(startOfDay(from), startOfDay(startDate))

        while result.count < limit {
            if let until, startOfDay(cursorDay) > until { break }

            let daysFromStart = cfg.calendar.dateComponents([.day],
                                                            from: startOfDay(startDate),
                                                            to: startOfDay(cursorDay)).day ?? 0
            let mod = ((daysFromStart % cycle) + cycle) % cycle
            if mod < onDays {
                if let candidate = combine(day: cursorDay, time: time),
                   isInRange(candidate, from: from, until: until) {
                    result.append(candidate)
                }
            }

            cursorDay = nextDay(from: cursorDay)
        }

        return result
    }

    // MARK: Custom dates
    func handleCustom(dates: [Date], from: Date, limit: Int, until: Date?) -> [Date] {
        let filtered = dates
            .filter { isInRange($0, from: from, until: until) }
            .sorted()

        return filtered.count <= limit ? filtered : Array(filtered.prefix(limit))
    }
}
