//
//  ScheduleListView.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import SwiftUI

struct ScheduleListView: View {
    private let repo: ScheduleRepository
    private let planner: NotificationPlanning
    @StateObject private var vm: ScheduleListViewModel
    @State private var path: [Route] = []

    init(repo: ScheduleRepository, planner: NotificationPlanning) {
        self.repo = repo
        self.planner = planner
        _vm = StateObject(wrappedValue: ScheduleListViewModel(repo: repo))
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(vm.items, id: \.id) { schedule in
                    NavigationLink(value: Route.edit(schedule)) {
                        ScheduleRow(schedule: schedule)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let idx = vm.items.firstIndex(where: { $0.id == schedule.id }) {
                                vm.delete(at: IndexSet(integer: idx))
                                planner.planAll(schedules: repo.getAll())
                            }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Расписания")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { path.append(.createOneTime) }) {
                            HStack(spacing: 8) {
                                Image("Once").renderingMode(.original)
                                Text("Разовый будильник")
                            }
                        }
                        Button(action: { path.append(.createShiftPattern) }) {
                            HStack(spacing: 8) {
                                Image("Shift").renderingMode(.original)
                                Text("Сменный график")
                            }
                        }
                        Button(action: { path.append(.createFloatingPattern) }) {
                            HStack(spacing: 8) {
                                Image("Wave").renderingMode(.original)
                                Text("Плавающий график")
                            }
                        }
                    } label: {
                        Label("Добавить", systemImage: "plus")
                    }
                    .accessibilityLabel("Добавить будильник")
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .createOneTime:
                    EditOneTimeScheduleView(repo: repo, source: .create) {
                        vm.reload()
                        planner.planAll(schedules: repo.getAll())
                    }
                case .createShiftPattern:
                    Text("Сменный график — скоро")
                case .createFloatingPattern:
                    Text("Плавающий график — скоро")
                case .edit(let schedule):
                    if case .oneTime = schedule.type {
                        EditOneTimeScheduleView(repo: repo, source: .edit(schedule)) {
                            vm.reload()
                            planner.planAll(schedules: repo.getAll())
                        }
                    } else {
                        // Пока редактируем только .oneTime. Остальные — чтение.
                        ReadonlyScheduleView(schedule: schedule)
                    }
                }
            }
        }
    }

    enum Route: Equatable, Hashable {
        case createOneTime
        case createShiftPattern
        case createFloatingPattern
        case edit(Schedule)

        static func == (lhs: Route, rhs: Route) -> Bool {
            switch (lhs, rhs) {
            case (.createOneTime, .createOneTime):
                return true
            case (.createShiftPattern, .createShiftPattern):
                return true
            case (.createFloatingPattern, .createFloatingPattern):
                return true
            case let (.edit(a), .edit(b)):
                return a.id == b.id
            default:
                return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .createOneTime:
                hasher.combine(0)
            case .createShiftPattern:
                hasher.combine(1)
            case .createFloatingPattern:
                hasher.combine(2)
            case .edit(let s):
                hasher.combine(3)
                hasher.combine(s.id)
            }
        }
    }
}

private struct ScheduleRow: View {
    let schedule: Schedule
    private var next: Date? { schedule.nextFireDate() }

    private static var cal: Calendar = {
        var c = Calendar.current
        c.timeZone = .current
        return c
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.timeZone = .current
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let ruFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.timeZone = .current
        f.dateFormat = "dd.MM.yyyy 'в' HH:mm"
        return f
    }()

    private func relativeLabel(for date: Date) -> String? {
        let cal = Self.cal
        let startOfToday = cal.startOfDay(for: Date())
        let startOfThat = cal.startOfDay(for: date)
        guard let days = cal.dateComponents([.day], from: startOfToday, to: startOfThat).day else { return nil }
        let time = Self.timeFormatter.string(from: date)
        switch days {
        case 0: return "Сегодня в \(time)"
        case 1: return "Завтра в \(time)"
        case 2: return "Послезавтра в \(time)"
        default: return nil
        }
    }

    private var nextLabel: String {
        if let d = next {
            if let rel = relativeLabel(for: d) { return rel }
            return Self.ruFormatter.string(from: d)
        }
        return schedule.nextFireLabel()
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(schedule.colorId))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name.isEmpty ? "Без названия" : schedule.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(nextLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}
