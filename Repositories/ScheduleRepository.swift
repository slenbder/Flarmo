//
//  ScheduleRepository.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

protocol ScheduleRepository {
    func getAll() -> [Schedule]
    func upsert(_ schedule: Schedule)
    func delete(id: UUID)

    /// Получить расписание по id (nil, если не найдено)
    func getById(_ id: UUID) -> Schedule?

    /// Обновить дату для разового расписания
    func updateOneTimeSchedule(id: UUID, newDate: Date)

    /// Включить/выключить расписание
    func setActive(_ isActive: Bool, id: UUID)
}
