//
//  EditOneTimeScheduleViewModel.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

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
    private let scheduler: NotificationsScheduling

    init(repo: ScheduleRepository, mode: Mode, scheduler: NotificationsScheduling = DefaultNotificationsScheduler()) {
        self.repo = repo
        self.mode = mode
        self.scheduler = scheduler

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
            print("⚠️ Warning: saving active one-time schedule in the past — will be marked as inactive")
        }
        var schedule: Schedule
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
        // Reschedule notifications to reflect the latest state
        let all = repo.getAll()
        scheduler.rescheduleAllIfNeeded()
        if let next = schedule.nextFireDate() {
            print("✅ Saved & scheduled: \(schedule.name.isEmpty ? "Будильник" : schedule.name) at \(next)")
        } else {
            print("⏸ Saved (inactive or past): \(schedule.name.isEmpty ? "Будильник" : schedule.name)")
        }
        print("💾 Repo now has \(all.count) schedules")
    }

    func deleteIfEditing() {
        if case .edit(let s) = mode {
            repo.delete(id: s.id)
            // Reschedule after deletion
            let all = repo.getAll()
            scheduler.rescheduleAllIfNeeded()
            print("🗑 Deleted schedule: \(s.name.isEmpty ? s.id.uuidString : s.name)")
            print("💾 Repo now has \(all.count) schedules")
        }
    }
}
