//
//  SchedulesRepository.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

protocol SchedulesRepository {
    func fetchAll() -> [Schedule]
    func saveAll(_ items: [Schedule])
    func upsert(_ item: Schedule)
    func delete(id: UUID)
}

final class UserDefaultsSchedulesRepositoryV2: SchedulesRepository {
    private let defaults: UserDefaults
    private let key = "schedules.v2"
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func fetchAll() -> [Schedule] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do { return try JSONDecoder().decode([Schedule].self, from: data) }
        catch { return [] }
    }

    func saveAll(_ items: [Schedule]) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.withoutEscapingSlashes]
        let data = try? enc.encode(items)
        defaults.set(data, forKey: key)
    }

    func upsert(_ item: Schedule) {
        var all = fetchAll()
        if let idx = all.firstIndex(where: { $0.id == item.id }) {
            all[idx] = item
        } else {
            all.append(item)
        }
        saveAll(all)
    }

    func delete(id: UUID) {
        var all = fetchAll()
        all.removeAll { $0.id == id }
        saveAll(all)
    }
}
