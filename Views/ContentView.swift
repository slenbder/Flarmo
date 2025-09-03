//
//  ContentView.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AlarmViewModel()

    // Редактирование существующего будильника
    @State private var isEditingExisting = false
    @State private var editingAlarm = Alarm(time: Date())

    // Создание нового
    @State private var showCreateSheet = false
    @State private var newAlarm = Alarm(time: Date())
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.alarms) { alarm in
                    HStack {
                        Text(alarm.label.isEmpty ? "Будильник" : alarm.label)
                        Spacer()
                        HStack {
                            Text(alarm.time, style: .time)
                            Toggle("", isOn: Binding(
                                get: { alarm.isActive },
                                set: { _ in viewModel.toggleAlarm(alarm) }
                            ))
                            .labelsHidden()
                        }
                    }
                    .contentShape(Rectangle()) // вся строка кликабельна
                    .onTapGesture {
                        editingAlarm = alarm
                        isEditingExisting = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            if let idx = viewModel.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                viewModel.removeAlarm(at: idx) // отмена уведомления внутри VM
                            }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
                // Оставляем .onDelete для режима редактирования списка (EditMode) / множественного удаления
                .onDelete { indexSet in
                    indexSet.forEach { viewModel.removeAlarm(at: $0) }
                }
            }
            .navigationTitle("Flarmo")
            .toolbar {
                Button("Добавить") {
                    newAlarm = Alarm(time: Date())
                    showCreateSheet = true
                }
            }
            // Создание нового
            .sheet(isPresented: $showCreateSheet) {
                EditAlarmView(alarm: $newAlarm) {
                    viewModel.addAlarm(newAlarm)
                    showCreateSheet = false
                }
            }
            // Редактирование существующего
            .sheet(isPresented: $isEditingExisting) {
                EditAlarmView(alarm: $editingAlarm) {
                    viewModel.updateAlarm(editingAlarm, autoActivate: true)
                    isEditingExisting = false
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
