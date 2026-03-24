//
//  EditShiftPatternViewModel.swift
//  Flarmo
//

import Foundation

@MainActor
final class EditShiftPatternViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Schedule)
    }

    @Published var name: String = ""
    @Published var colorId: Int = 0
    @Published var startDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var onDays: Int = 2
    @Published var offDays: Int = 2
    @Published var time: Date = {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 7
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @Published var isActive: Bool = true

    private let repo: ScheduleRepository
    private let mode: Mode

    init(repo: ScheduleRepository, mode: Mode) {
        self.repo = repo
        self.mode = mode

        if case .edit(let s) = mode {
            name = s.name
            colorId = s.colorId
            isActive = s.isActive
            if case .shiftPattern(let sd, let on, let off, let tod) = s.type {
                startDate = sd
                onDays = on
                offDays = off
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = tod.hour
                comps.minute = tod.minute
                if let t = Calendar.current.date(from: comps) {
                    time = t
                }
            }
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && onDays > 0 && offDays >= 0
    }

    func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let tod = TimeOfDay(comps.hour ?? 7, comps.minute ?? 0)
        let scheduleType = ScheduleType.shiftPattern(startDate: startDate, onDays: onDays, offDays: offDays, time: tod)

        let schedule: Schedule
        switch mode {
        case .create:
            schedule = Schedule(
                id: UUID(),
                name: name,
                colorId: colorId,
                toneId: nil,
                type: scheduleType,
                isActive: isActive
            )
        case .edit(let existing):
            schedule = existing.updating(
                name: name,
                colorId: colorId,
                type: scheduleType,
                isActive: isActive
            )
        }
        repo.upsert(schedule)
        print("✅ Saved shift pattern: \(schedule.name.isEmpty ? "Сменный" : schedule.name) (\(onDays)×\(offDays) с \(startDate))")
        print("💾 Repo now has \(repo.getAll().count) schedules")
    }

    func deleteIfEditing() {
        if case .edit(let s) = mode {
            repo.delete(id: s.id)
            print("🗑 Deleted schedule: \(s.name.isEmpty ? s.id.uuidString : s.name)")
            print("💾 Repo now has \(repo.getAll().count) schedules")
        }
    }
}
