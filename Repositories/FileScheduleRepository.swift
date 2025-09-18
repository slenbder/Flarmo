//
//  FileScheduleRepository.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation
import Combine

final class FileScheduleRepository: ScheduleRepository {
    private let queue = DispatchQueue(label: "FileScheduleRepository.queue", qos: .utility)
    private var store: [UUID: Schedule] = [:]
    private let url: URL

    // Change stream
    private let subject = PassthroughSubject<RepositoryChange, Never>()
    var changes: AnyPublisher<RepositoryChange, Never> { subject.eraseToAnyPublisher() }

    init(filename: String = "schedules.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent(filename)
        load()
        print("[Repo:File] Initialized with \(store.count) items at \(url.lastPathComponent)")
    }

    func getAll() -> [Schedule] {
        return queue.sync { Array(store.values) }
    }

    func getById(_ id: UUID) -> Schedule? {
        return queue.sync { store[id] }
    }

    func upsert(_ schedule: Schedule) {
        var wasInserted = false
        queue.sync {
            let existed = store[schedule.id] != nil
            store[schedule.id] = schedule
            persist()
            wasInserted = !existed
        }
        if wasInserted {
            print("[Repo:File] insert id=\(schedule.id) name=\(schedule.name)")
            subject.send(.inserted([schedule.id]))
            print("[Repo:File] change -> inserted ids={\(schedule.id)}")
        } else {
            print("[Repo:File] update id=\(schedule.id) name=\(schedule.name)")
            subject.send(.updated([schedule.id]))
            print("[Repo:File] change -> updated ids={\(schedule.id)}")
        }
    }

    func delete(id: UUID) {
        var didRemove = false
        var removedName: String?
        queue.sync {
            if let removed = store.removeValue(forKey: id) {
                removedName = removed.name
                persist()
                didRemove = true
            }
        }
        if didRemove {
            print("[Repo:File] delete id=\(id) name=\(removedName ?? "")")
            subject.send(.deleted([id]))
            print("[Repo:File] change -> deleted ids={\(id)}")
        } else {
            print("[Repo:File] delete skipped (not found) id=\(id)")
        }
    }

    func updateOneTimeSchedule(id: UUID, newDate: Date) {
        var changed = false
        var oldDate: Date?
        var name: String = ""
        queue.sync {
            guard let existing = store[id] else { return }
            name = existing.name
            switch existing.type {
            case .oneTime(let prev):
                oldDate = prev
                let updated = Schedule(
                    id: existing.id,
                    name: existing.name,
                    colorId: existing.colorId,
                    toneId: existing.toneId,
                    type: .oneTime(date: newDate),
                    isActive: existing.isActive
                )
                store[id] = updated
                persist()
                changed = true
            default:
                return
            }
        }
        if changed {
            print("[Repo:File] updateOneTime id=\(id) name=\(name) \(oldDate.map { "from=\($0)" } ?? "from=?") -> to=\(newDate)")
            subject.send(.updated([id]))
            print("[Repo:File] change -> updated ids={\(id)}")
        } else {
            print("[Repo:File] updateOneTime skipped (not found or not oneTime) id=\(id)")
        }
    }

    func setActive(_ isActive: Bool, id: UUID) {
        var changed = false
        var name: String = ""
        queue.sync {
            guard let existing = store[id] else { return }
            name = existing.name
            let updated = Schedule(
                id: existing.id,
                name: existing.name,
                colorId: existing.colorId,
                toneId: existing.toneId,
                type: existing.type,
                isActive: isActive
            )
            store[id] = updated
            persist()
            changed = true
        }
        if changed {
            print("[Repo:File] setActive id=\(id) name=\(name) -> \(isActive)")
            subject.send(.updated([id]))
            print("[Repo:File] change -> updated ids={\(id)}")
        } else {
            print("[Repo:File] setActive skipped (not found) id=\(id)")
        }
    }

    // MARK: - Persistence
    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        do {
            let decoded = try JSONDecoder().decode([ScheduleDTO].self, from: data)
            self.store = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0.model) })
            print("[Repo:File] Loaded \(store.count) items from disk")
        } catch {
            print("❌ [Repo:File] Failed to load schedules: \(error)")
        }
    }

    private func persist() {
        do {
            let arr = store.values.map { ScheduleDTO($0) }
            let data = try JSONEncoder().encode(arr)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ [Repo:File] Failed to persist schedules: \(error)")
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

