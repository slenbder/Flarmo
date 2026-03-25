//
//  Schedule+NextFireDate.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation
import OSLog

extension Schedule {
    /// Возвращает дату следующего срабатывания или nil, если неактивно/в прошлом.
    func nextFireDate(from now: Date = Date(), calendar: Calendar = .current) -> Date? {
        Logger.recurrence.debug("nextFireDate called for schedule=\(self.id)")
        guard isActive else { return nil }
        let date: Date?
        switch type {
        case .oneTime(let dateTime):
            date = dateTime > now ? dateTime : nil

        case .shiftPattern, .customDates:
            date = RecurrenceCalculator()
                .nextOccurrences(for: self, from: now, limit: 1, until: nil)
                .first
        }
        Logger.recurrence.info("nextFireDate result: \(date?.description ?? "nil")")
        return date
    }

    /// Короткая подпись «Следующее срабатывание»
    func nextFireLabel(now: Date = Date(), calendar: Calendar = .current) -> String {
        guard let d = nextFireDate(from: now, calendar: calendar) else {
            return "Неактивно"
        }

        let isToday = calendar.isDate(d, inSameDayAs: now)
        if isToday {
            return "Сегодня, \(Self.timeFormatter.string(from: d))"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(d, inSameDayAs: tomorrow) {
            return "Завтра, \(Self.timeFormatter.string(from: d))"
        } else {
            return Self.dateTimeFormatter.string(from: d)
        }
    }
}

private extension Schedule {
    static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.timeStyle = .short
        df.dateStyle = .none
        return df
    }()

    static let dateTimeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = .current
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
}
