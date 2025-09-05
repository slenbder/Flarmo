//
//  MigrationV1toV2.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

// V1 модель (для чтения при миграции)
private struct AlarmV1: Codable {
    let id: String           // UUID().uuidString
    let date: Date           // точное время с датой
    let label: String?
    let toneId: String?
    let isEnabled: Bool
}

protocol MigrationRunning {
    func runIfNeeded()
}

final class MigrationV1toV2: MigrationRunning {
    private let defaults: UserDefaults
    private let repo: ScheduleRepository

    private let v1Key = "alarms"
    private let didFlag = "migration.v1toV2.done"

    init(defaults: UserDefaults = .standard,
         repo: ScheduleRepository) {
        self.defaults = defaults
        self.repo = repo
    }

    func runIfNeeded() {
        // already done?
        guard defaults.bool(forKey: didFlag) == false else {
            print("[Migration] Already done, skipping")
            return
        }

        // read v1 data
        guard let data = defaults.data(forKey: v1Key) else {
            print("[Migration] No v1 data found, marking as done")
            defaults.set(true, forKey: didFlag)
            return
        }

        // decode v1 alarms
        let decoder = JSONDecoder()
        guard let alarms = try? decoder.decode([AlarmV1].self, from: data) else {
            print("[Migration] Failed to decode v1 alarms, marking as done")
            defaults.set(true, forKey: didFlag)
            return
        }

        print("[Migration] Migrating \(alarms.count) alarms from v1 → v2")

        let migrated: [Schedule] = alarms.map { a in
            Schedule(
                name: a.label ?? "Alarm",
                colorId: defaultColorId(for: a),
                toneId: a.toneId,
                type: .oneTime(date: a.date),
                isActive: a.isEnabled
            )
        }

        // upsert migrated directly into v2 repo
        for s in migrated { repo.upsert(s) }
        let total = repo.getAll().count
        print("[Migration] Completed, now \(total) schedules stored in v2")

        // set done flag
        defaults.set(true, forKey: didFlag)
    }
    /// Provides a deterministic default color for migrated alarms.
    /// Spreads colors across a 10-color palette using a stable hash of the v1 id.
    private func defaultColorId(for alarm: AlarmV1) -> Int {
        return abs(alarm.id.hashValue) % 10
    }
}
