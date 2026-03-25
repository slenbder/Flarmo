//
//  EditOneTimeScheduleViewModel.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation
import OSLog

@MainActor
final class EditOneTimeScheduleViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Schedule)
    }

    @Published var name: String = ""
    @Published var colorId: Int = 0
    @Published var date: Date = Date().addingTimeInterval(60 * 15) // через 15 минут
    @Published var isActive: Bool = true

    private let repo: ScheduleRepository
    private let mode: Mode

    init(repo: ScheduleRepository, mode: Mode) {
        self.repo = repo
        self.mode = mode

        if case .edit(let s) = mode {
            name = s.name
            colorId = s.colorId
            if case .oneTime(let dt) = s.type { date = dt }
            isActive = s.isActive
        }
    }

    var canSave: Bool {
        // Разовый будильник можно сохранить даже в прошлом — но он будет «Неактивно».
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() {
        if isActive && date < Date() {
            Logger.ui.debug("Saving active one-time schedule in the past — will be marked as inactive")
        }
        let schedule: Schedule
        switch mode {
        case .create:
            schedule = Schedule(
                id: UUID(),
                name: name,
                colorId: colorId,
                toneId: nil,
                type: .oneTime(date: date),
                isActive: isActive
            )
        case .edit(let existing):
            schedule = existing.updating(
                name: name,
                colorId: colorId,
                type: .oneTime(date: date),
                isActive: isActive
            )
        }
        repo.upsert(schedule)
        if let next = schedule.nextFireDate() {
            Logger.ui.info("Saved & scheduled: \(schedule.name.isEmpty ? "Будильник" : schedule.name) at \(next)")
        } else {
            Logger.ui.info("Saved (inactive or past): \(schedule.name.isEmpty ? "Будильник" : schedule.name)")
        }
        Logger.ui.debug("Repo now has \(self.repo.getAll().count) schedules")
    }

    func deleteIfEditing() {
        if case .edit(let s) = mode {
            repo.delete(id: s.id)
            Logger.ui.info("Deleted schedule: \(s.name.isEmpty ? s.id.uuidString : s.name)")
            Logger.ui.debug("Repo now has \(self.repo.getAll().count) schedules")
        }
    }
}

