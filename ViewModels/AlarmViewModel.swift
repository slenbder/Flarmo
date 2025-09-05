//
//  AlarmViewModel.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation

class AlarmViewModel: ObservableObject {
    private let notifier: NotificationScheduling
    private let persistence: AlarmPersistence
    @Published var alarms: [Alarm] = [] {
        didSet {
            persistence.saveAlarms(alarms)
        }
    }

    init(notifier: NotificationScheduling = NotificationService.shared,
         persistence: AlarmPersistence = PersistenceService.shared) {
        self.notifier = notifier
        self.persistence = persistence
        let loaded = persistence.loadAlarms()
        self.alarms = loaded
        for alarm in loaded where alarm.isActive {
            notifier.updateNotification(for: alarm)
        }
    }
    
    func addAlarm(_ alarm: Alarm) {
        alarms.append(alarm)
        notifier.scheduleNotification(for: alarm)
    }

    func removeAlarm(at index: Int) {
        let alarm = alarms[index]
        notifier.cancelNotification(for: alarm)
        alarms.remove(at: index)
    }

    func toggleAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isActive.toggle()
        notifier.updateNotification(for: alarms[index])
    }
    
    func updateAlarm(_ updated: Alarm, autoActivate: Bool = true) {
        guard let index = alarms.firstIndex(where: { $0.id == updated.id }) else { return }

        var newAlarm = updated
        if autoActivate { newAlarm.isActive = true }      // редактирование → будильник становится активным

        let wasActive = alarms[index].isActive
        alarms[index] = newAlarm

        if newAlarm.isActive {
            if wasActive {
                notifier.updateNotification(for: newAlarm)
            } else {
                notifier.scheduleNotification(for: newAlarm)
            }
        } else {
            notifier.cancelNotification(for: newAlarm)
        }
    }
}
