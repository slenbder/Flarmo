//
//  EditOneTimeScheduleView.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import SwiftUI

struct EditOneTimeScheduleView: View {
    enum Source {
        case create
        case edit(Schedule)
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: EditOneTimeScheduleViewModel
    let onSaved: () -> Void
    private let sourceKind: Source

    init(repo: ScheduleRepository, source: Source, onSaved: @escaping () -> Void) {
        switch source {
        case .create:
            _vm = StateObject(wrappedValue: EditOneTimeScheduleViewModel(repo: repo, mode: .create))
        case .edit(let schedule):
            _vm = StateObject(wrappedValue: EditOneTimeScheduleViewModel(repo: repo, mode: .edit(schedule)))
        }
        self.onSaved = onSaved
        self.sourceKind = source
    }

    var body: some View {
        Form {
            Section("Основное") {
                TextField("Название", text: $vm.name)
                ColorPickerRow(selectedId: $vm.colorId)
                Toggle("Активно", isOn: $vm.isActive)
            }

            Section("Дата и время") {
                DatePicker("Дата и время", selection: $vm.date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
            }

            Section {
                Button {
                    vm.save()
                    onSaved()
                    dismiss()
                } label: {
                    Text("Сохранить")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(!vm.canSave)
            }

            if case .edit = sourceKind {
                Section {
                    Button(role: .destructive) {
                        vm.deleteIfEditing()
                        onSaved()
                        dismiss()
                    } label: {
                        Text("Удалить расписание")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        if case .edit = sourceKind { return "Править" }
        return "Новый разовый"
    }
}
