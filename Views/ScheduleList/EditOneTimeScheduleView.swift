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

    private var isPast: Bool {
        vm.date < Date()
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
                    .environment(\.locale, Locale(identifier: "ru_RU"))
                    .onChange(of: vm.date) { _ in print("[UI] date changed to \(vm.date)"); nameFocused = false }
            }
            
            if isPast {
                Section {
                    Label("Дата/время в прошлом. Выберите будущее время.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
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
                .disabled(!vm.canSave || isPast)
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
        .onAppear {
            // Нормализуем секунды до 0, чтобы исключить рассинхрон с триггерами
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: vm.date)
            if let normalized = Calendar.current.date(from: comps) {
                vm.date = normalized
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") { nameFocused = false }
            }
        }
    }

    private var title: String {
        if case .edit = sourceKind { return "Править" }
        return "Разовый"
    }
}
