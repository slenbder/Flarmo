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
}
