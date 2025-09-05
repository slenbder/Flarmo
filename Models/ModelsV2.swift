//
//  ModelsV2.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

// MARK: - V2 Models

public struct Schedule: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var colorId: String?
    public var toneId: String?
    public var type: ScheduleType
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        colorId: String? = nil,
        toneId: String? = nil,
        type: ScheduleType,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.colorId = colorId
        self.toneId = toneId
        self.type = type
        self.isActive = isActive
    }
}

public enum ScheduleType: Codable, Equatable {
    case oneTime(date: Date)
    case shiftPattern(startDate: Date, onDays: Int, offDays: Int, time: TimeOfDay)
    case weekdays(days: Set<Weekday>, time: TimeOfDay)
    case customDates([Date])
}

public struct TimeOfDay: Codable, Equatable {
    public var hour: Int
    public var minute: Int
    public init(_ hour: Int, _ minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}

public enum Weekday: Int, Codable, CaseIterable {
    case monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7, sunday = 1
}
