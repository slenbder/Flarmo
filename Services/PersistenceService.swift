//
//  PersistenceService.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation

protocol AlarmPersistence: AnyObject {
    func saveAlarms(_ alarms: [Alarm])
    func loadAlarms() -> [Alarm]
}

final class PersistenceService: AlarmPersistence {
    static let shared = PersistenceService()

    private let key = "flarmo.alarms.v1"
    private let defaults: UserDefaults

    /// Designated initializer with injectable UserDefaults (useful for tests).
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()

    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    func saveAlarms(_ alarms: [Alarm]) {
        do {
            let data = try encoder.encode(alarms)
            defaults.set(data, forKey: key)
        } catch {
            print("❌ Ошибка сохранения будильников: \(error)")
        }
    }

    func loadAlarms() -> [Alarm] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            let alarms = try decoder.decode([Alarm].self, from: data)
            return alarms
        } catch {
            print("❌ Ошибка загрузки будильников: \(error)")
            return []
        }
    }

    // Пригодится для сброса/отладки
    func wipe() {
        defaults.removeObject(forKey: key)
    }
}
