//
//  AlarmViewModel.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation

class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        NotificationService.shared.scheduleNotification(for: alarm)
    }

    func removeAlarm(at index: Int) {
        let alarm = alarms[index]
        NotificationService.shared.cancelNotification(for: alarm)
        alarms.remove(at: index)
    }

    func toggleAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].isActive.toggle()
            NotificationService.shared.updateNotification(for: alarms[index])
        }
    }
    
    func updateAlarm(_ updated: Alarm, autoActivate: Bool = true) {
        guard let index = alarms.firstIndex(where: { $0.id == updated.id }) else { return }

        var newAlarm = updated
        if autoActivate { newAlarm.isActive = true }      // редактирование → будильник становится активным

        let wasActive = alarms[index].isActive
        alarms[index] = newAlarm

        if newAlarm.isActive {
            if wasActive {
                NotificationService.shared.updateNotification(for: newAlarm)
            } else {
                NotificationService.shared.scheduleNotification(for: newAlarm)
            }
        } else {
            NotificationService.shared.cancelNotification(for: newAlarm)
        }
    }
}
