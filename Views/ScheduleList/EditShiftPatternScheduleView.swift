//
//  EditShiftPatternScheduleView.swift
//  Flarmo
//

import SwiftUI

struct EditShiftPatternScheduleView: View {
    enum Source {
        case create
        case edit(Schedule)
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: EditShiftPatternViewModel
    let onSaved: () -> Void
    private let sourceKind: Source
    @FocusState private var nameFocused: Bool

    init(repo: ScheduleRepository, source: Source, onSaved: @escaping () -> Void) {
        switch source {
        case .create:
            _vm = StateObject(wrappedValue: EditShiftPatternViewModel(repo: repo, mode: .create))
        case .edit(let schedule):
            _vm = StateObject(wrappedValue: EditShiftPatternViewModel(repo: repo, mode: .edit(schedule)))
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
                    .onSubmit { nameFocused = false }
                ColorPickerRow(selectedId: $vm.colorId)
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { if nameFocused { nameFocused = false } })
                Toggle("Активно", isOn: $vm.isActive)
                    .simultaneousGesture(TapGesture().onEnded { if nameFocused { nameFocused = false } })
            }

            Section("График") {
                HStack(spacing: 0) {
                    Text("Работа")
                        .frame(maxWidth: .infinity)
                    Picker("Работа", selection: $vm.onDays) {
                        ForEach(1...14, id: \.self) { n in
                            Text("\(n) д.").tag(n)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    Divider()

                    Text("Отдых")
                        .frame(maxWidth: .infinity)
                    Picker("Отдых", selection: $vm.offDays) {
                        ForEach(1...14, id: \.self) { n in
                            Text("\(n) д.").tag(n)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .frame(height: 120)
            }

            Section("Стартовая дата") {
                DatePicker("Начало цикла", selection: $vm.startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    .onChange(of: vm.startDate) { nameFocused = false }
            }

            Section("Время срабатывания") {
                DatePicker("Время", selection: $vm.time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    .onChange(of: vm.time) { nameFocused = false }
            }

            Section {
                EmptyView()
            }
            .listRowBackground(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { if nameFocused { nameFocused = false } }

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
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { nameFocused = false }
            }
        }
    }

    private var title: String {
        if case .edit = sourceKind { return "Править" }
        return "Сменный график"
    }
}
