//
//  ReadonlyScheduleView.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import SwiftUI

struct ReadonlyScheduleView: View {
    let schedule: Schedule
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Название")
                    Spacer()
                    Text(schedule.name.isEmpty ? "Без названия" : schedule.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Цвет")
                    Spacer()
                    Circle().fill(Color(schedule.colorId)).frame(width: 16, height: 16)
                }
                HStack {
                    Text("Следующее")
                    Spacer()
                    Text(schedule.nextFireLabel())
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Text("Редактирование для этого типа будет добавлено позже.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Расписание")
    }
}
