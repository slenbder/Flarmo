//
//  FileScheduleRepository.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

final class FileScheduleRepository: ScheduleRepository {
    private let queue = DispatchQueue(label: "FileScheduleRepository.queue", qos: .utility)
    private var store: [UUID: Schedule] = [:]
    private let url: URL

    init(filename: String = "schedules.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent(filename)
        load()
    }

    func getAll() -> [Schedule] {
        return queue.sync { Array(store.values) }
    }

    func upsert(_ schedule: Schedule) {
        queue.sync {
            store[schedule.id] = schedule
            persist()
        }
    }

    func delete(id: UUID) {
        queue.sync {
            store.removeValue(forKey: id)
            persist()
        }
    }

    // MARK: - Persistence
    private func load() {
        queue.sync {
            guard let data = try? Data(contentsOf: url) else { return }
            do {
                let decoded = try JSONDecoder().decode([ScheduleDTO].self, from: data)
                self.store = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0.model) })
            } catch {
                print("❌ Failed to load schedules: \(error)")
            }
        }
    }

    private func persist() {
        do {
            let arr = store.values.map { ScheduleDTO($0) }
            let data = try JSONEncoder().encode(arr)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ Failed to persist schedules: \(error)")
        }
    }
}

// MARK: - DTO (Codable) слой, чтобы не трогать доменную модель
private struct ScheduleDTO: Codable {
    let id: UUID
    let name: String
    let colorId: Int
    let toneId: String?
    let isActive: Bool
    let type: ScheduleTypeDTO

    init(_ m: Schedule) {
        self.id = m.id
        self.name = m.name
        self.colorId = m.colorId
        self.toneId = m.toneId
        self.isActive = m.isActive
        self.type = .init(m.type)
    }

    var model: Schedule {
        Schedule(id: id, name: name, colorId: colorId, toneId: toneId, type: type.model, isActive: isActive)
    }
}

private enum ScheduleTypeDTO: Codable {
    case oneTime(Date)
    case shiftPattern(startDate: Date, onDays: Int, offDays: Int, hour: Int, minute: Int)
    case weekdays(days: [Int], hour: Int, minute: Int)
    case customDates([Date])

    init(_ t: ScheduleType) {
        switch t {
        case .oneTime(let d): self = .oneTime(d)
        case .shiftPattern(let start, let on, let off, let tod):
            self = .shiftPattern(startDate: start, onDays: on, offDays: off, hour: tod.hour, minute: tod.minute)
        case .weekdays(let days, let tod):
            self = .weekdays(days: days.map { $0.rawValue }, hour: tod.hour, minute: tod.minute)
        case .customDates(let arr): self = .customDates(arr)
        }
    }

    var model: ScheduleType {
        switch self {
        case .oneTime(let d): return .oneTime(date: d)
        case .shiftPattern(let start, let on, let off, let hour, let minute):
            return .shiftPattern(startDate: start, onDays: on, offDays: off, time: .init(hour, minute))
        case .weekdays(let days, let hour, let minute):
            let set = Set(days.compactMap { Weekday(rawValue: $0) })
            return .weekdays(days: set, time: .init(hour, minute))
        case .customDates(let arr): return .customDates(arr)
        }
    }
}
