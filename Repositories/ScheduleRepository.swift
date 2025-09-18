//
//  ScheduleRepository.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation
import Combine

/// Типизированные события изменений в репозитории.
/// В перспективе позволяет обновлять UI точечно (по id), а не всегда полным reload.
enum RepositoryChange {
    case inserted(Set<UUID>)
    case updated(Set<UUID>)
    case deleted(Set<UUID>)
    /// Полная перестройка снимка (например, после миграции/импорта)
    case snapshot
}

protocol ScheduleRepository {
    // MARK: Query
    func getAll() -> [Schedule]
    func getById(_ id: UUID) -> Schedule?

    // MARK: Mutations
    func upsert(_ schedule: Schedule)
    func delete(id: UUID)
    func updateOneTimeSchedule(id: UUID, newDate: Date)
    func setActive(_ isActive: Bool, id: UUID)

    // MARK: Change stream
    /// Поток изменений в репозитории.
    /// Гарантии порядка доставки в рамках одной реализации репозитория соблюдаются.
    var changes: AnyPublisher<RepositoryChange, Never> { get }
}

