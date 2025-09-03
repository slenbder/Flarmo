//
//  EditAlarmView.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import SwiftUI

struct EditAlarmView: View {
    @Binding var alarm: Alarm
    var onSave: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Редактировать будильник")
                .font(.headline)
            
            DatePicker("Время", selection: $alarm.time, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
            
            TextField("Метка", text: $alarm.label)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Сохранить") {
                onSave?()
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
}
