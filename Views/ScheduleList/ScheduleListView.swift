//
//  ScheduleListView.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import SwiftUI

struct ScheduleListView: View {
    private let repo: ScheduleRepository
    @StateObject private var vm: ScheduleListViewModel
    @State private var path: [Route] = []

    init(repo: ScheduleRepository) {
        self.repo = repo
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
                    Button {
                        path.append(Route.createOneTime)
                    } label: {
                        Label("Добавить", systemImage: "plus")
                    }
                    .accessibilityLabel("Добавить разовый будильник")
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .createOneTime:
                    EditOneTimeScheduleView(repo: repo, source: .create) {
                        vm.reload()
                    }
                case .edit(let schedule):
                    if case .oneTime = schedule.type {
                        EditOneTimeScheduleView(repo: repo, source: .edit(schedule)) {
                            vm.reload()
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
        case edit(Schedule)

        static func == (lhs: Route, rhs: Route) -> Bool {
            switch (lhs, rhs) {
            case (.createOneTime, .createOneTime):
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
            case .edit(let s):
                hasher.combine(1)
                hasher.combine(s.id)
            }
        }
    }
}

private struct ScheduleRow: View {
    let schedule: Schedule

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(schedule.colorId))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name.isEmpty ? "Без названия" : schedule.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(schedule.nextFireLabel())
                    .font(.subheadline)
                    .foregroundStyle(schedule.nextFireDate() == nil ? .secondary : .secondary)
            }

            Spacer()

            if schedule.nextFireDate() == nil {
                Text("⏸")
                    .accessibilityLabel("Неактивно")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
