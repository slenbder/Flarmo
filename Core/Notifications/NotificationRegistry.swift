//
//  NotificationRegistry.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/9/25.
//

import Foundation

protocol NotificationRegistry {
    /// Зарегистрированные нами идентификаторы pending-уведомлений
    var ids: Set<String> { get }
    /// Полная замена всех ID (например, после полного пересчёта)
    func replaceAll(with ids: Set<String>)
    /// Добавить множество ID
    func add(_ ids: Set<String>)
    /// Удалить множество ID
    func remove(_ ids: Set<String>)
    /// Самоисцеление: привести локальное состояние к системному снапшоту
    func reloadFromSystemSnapshot(_ systemIDs: Set<String>)
}

final class DefaultsNotificationRegistry: NotificationRegistry {
    private let defaults: UserDefaults
    private let key: String
    private let queue = DispatchQueue(label: "notification-registry.queue", qos: .utility)
    private var cached: Set<String>

    init(defaults: UserDefaults = .standard, key: String = "notification_registry_ids") {
        self.defaults = defaults
        self.key = key
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.cached = Set(decoded)
        } else {
            self.cached = []
        }
    }

    var ids: Set<String> {
        queue.sync { cached }
    }

    func replaceAll(with ids: Set<String>) {
        queue.sync {
            cached = ids
            persistLocked()
        }
    }

    func add(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        queue.sync {
            cached.formUnion(ids)
            persistLocked()
        }
    }

    func remove(_ ids: Set<String>) {
        guard !ids.isEmpty else { return }
        queue.sync {
            cached.subtract(ids)
            persistLocked()
        }
    }

    func reloadFromSystemSnapshot(_ systemIDs: Set<String>) {
        queue.sync {
            // Оставляем только то, что реально есть в системе
            cached = cached.intersection(systemIDs)
            persistLocked()
        }
    }

    private func persistLocked() {
        let array = Array(cached)
        if let data = try? JSONEncoder().encode(array) {
            defaults.set(data, forKey: key)
        }
    }
}
