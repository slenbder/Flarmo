//
//  Schedule+NextFireDate.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

extension Schedule {
    /// Возвращает дату следующего срабатывания или nil, если неактивно/в прошлом.
    func nextFireDate(from now: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard isActive else { return nil }
        switch type {
        case .oneTime(let dateTime):
            return dateTime > now ? dateTime : nil

        case .weekdays(_, _),
             .shiftPattern(_, _, _, _),
             .customDates(_):
            // Будет реализовано позже (этапы D/E).
            return nil
        }
    }

    /// Короткая подпись «Следующее срабатывание»
    func nextFireLabel(now: Date = Date(), calendar: Calendar = .current, locale: Locale = .current) -> String {
        guard let d = nextFireDate(from: now, calendar: calendar) else {
            return "Неактивно"
        }

        let isToday = calendar.isDate(d, inSameDayAs: now)
        let df = DateFormatter()
        df.locale = locale
        if isToday {
            df.dateStyle = .none
            df.timeStyle = .short
            return "Сегодня, \(df.string(from: d))"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(d, inSameDayAs: tomorrow) {
            df.dateStyle = .none
            df.timeStyle = .short
            return "Завтра, \(df.string(from: d))"
        } else {
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: d)
        }
    }
}
