//
//  InMemoryScheduleRepository.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

final class InMemoryScheduleRepository: ScheduleRepository {
    private var store: [UUID: Schedule] = [:]
    private let queue = DispatchQueue(label: "InMemoryScheduleRepository.queue", qos: .utility)
    private let fileURL: URL

    init(seed: [Schedule] = []) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("schedules.json")
        self.load()
        seed.forEach { store[$0.id] = $0 }
        self.persist()
    }

    func getAll() -> [Schedule] { queue.sync { Array(store.values) } }
    func upsert(_ schedule: Schedule) { queue.sync { store[schedule.id] = schedule; persist() } }
    func delete(id: UUID) { queue.sync { store.removeValue(forKey: id); persist() } }
}

// MARK: - Persistence
private extension InMemoryScheduleRepository {
    func load() {
        print("💾 Loading schedules from: \(fileURL.path)")
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let decoded = try JSONDecoder().decode([ScheduleDTO].self, from: data)
            self.store = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0.model) })
            print("💾 Loaded \(store.count) schedules from disk")
        } catch {
            print("❌ Failed to load schedules: \(error)")
        }
    }

    func persist() {
        do {
            let arr = store.values.map { ScheduleDTO($0) }
            print("💾 Persisting \(arr.count) schedules to: \(fileURL.path)")
            let data = try JSONEncoder().encode(arr)
            let tmpURL = fileURL.appendingPathExtension("tmp")
            try data.write(to: tmpURL, options: .atomic)
            try? FileManager.default.replaceItemAt(fileURL, withItemAt: tmpURL)
            print("💾 Persist successful")
        } catch {
            print("❌ Failed to persist schedules: \(error)")
        }
    }
}

// MARK: - DTO layer to avoid forcing Codable on domain models
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
