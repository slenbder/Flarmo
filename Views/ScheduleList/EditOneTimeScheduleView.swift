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
    @FocusState private var nameFocused: Bool

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
            Section {
                EmptyView()
            }
            .listRowBackground(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { if nameFocused { nameFocused = false } }

            Section("Основное") {
                TextField("Название", text: $vm.name)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { print("[UI] onSubmit name field"); nameFocused = false }
                ColorPickerRow(selectedId: $vm.colorId)
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { if nameFocused { nameFocused = false } })
                Toggle("Активно", isOn: $vm.isActive)
                    .simultaneousGesture(TapGesture().onEnded { if nameFocused { nameFocused = false } })
            }

            Section("Дата и время") {
                DatePicker("Дата и время", selection: $vm.date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .onTapGesture { print("[UI] datePicker tapped"); nameFocused = false }
                    .onChange(of: vm.date) { _ in print("[UI] date changed to \(vm.date)"); nameFocused = false }
            }
            
            Section {
                EmptyView()
            }
            .listRowBackground(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if nameFocused { nameFocused = false }
            }

            Section {
                Button {
                    print("[UI] Save tapped (canSave=\(vm.canSave))")
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
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Готово") { nameFocused = false }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var title: String {
        if case .edit = sourceKind { return "Править" }
        return "Разовый"
    }
}
