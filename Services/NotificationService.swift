//
//  NotificationService.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation
import OSLog
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    private var repo: ScheduleRepository?
    private var planner: NotificationPlanning?
    private var namespacePrefix: String { "flarmo." }
    
    private override init() {
        super.init()
        center.delegate = self
        registerCategories() // важно: экшены будут доступны уже на первом уведомлении
    }
    
    func configure(repo: ScheduleRepository, planner: NotificationPlanning) {
        self.repo = repo
        self.planner = planner
    }
    
    // MARK: - Permissions
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Logger.notifications.error("Ошибка запроса разрешения: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Categories
    
    func registerCategories() {
        let snooze = UNNotificationAction(
            identifier: "ALARM_SNOOZE",
            title: "Отложить на 1 мин",
            options: []
        )
        let stop = UNNotificationAction(
            identifier: "ALARM_STOP",
            title: "Выключить",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "ALARM_ACTIONS",
            actions: [snooze, stop],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([category])
    }
    
    // MARK: - Debug / Test
    /// Удаляет старые pending-уведомления формата `sched_...` (до этапа E)
    func removeLegacyPending(completion: (() -> Void)? = nil) {
        center.getPendingNotificationRequests { [weak self] reqs in
            let legacy = reqs.map(\.identifier).filter { $0.hasPrefix("sched_") }
            if !legacy.isEmpty {
                self?.center.removePendingNotificationRequests(withIdentifiers: legacy)
                Logger.notifications.info("Removed legacy pending: \(legacy.count)")
            } else {
                Logger.notifications.debug("No legacy pending found")
            }
            completion?()
        }
    }
    
    func listScheduledNotifications() {
        center.getPendingNotificationRequests { requests in
            Logger.notifications.debug("Текущее количество уведомлений: \(requests.count)")
            for req in requests {
                Logger.notifications.debug("— \(req.identifier): \(req.content.body)")
            }
        }
    }
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Тестовый будильник"
        content.body = "Проверка срабатывания!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "test_alarm", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                Logger.notifications.error("Ошибка тестового уведомления: \(error)")
            } else {
                Logger.notifications.info("Тестовое уведомление запланировано (через 10 секунд)")
            }
        }
    }
    
    // MARK: - Helpers
    private func extractScheduleId(from requestId: String) -> UUID? {
        // ожидаем формат "flarmo.<uuid>.<...>"
        let parts = requestId.split(separator: ".")
        guard parts.count >= 3 else { return nil }
        return UUID(uuidString: String(parts[1]))
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Показывать уведомление даже при активном приложении (баннер + звук + в список)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    
    // Срабатывает, когда пользователь нажал кнопку в уведомлении
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let req = response.notification.request
        
        switch response.actionIdentifier {
        case "ALARM_SNOOZE":
            // Snooze = +60 секунд (для тестов)
            guard
                let repo = repo,
                let planner = planner,
                let scheduleId = extractScheduleId(from: req.identifier),
                let existing = repo.getById(scheduleId)
            else {
                completionHandler()
                return
            }
            
            let newDate = Date().addingTimeInterval(60) // тест: snooze на 1 минуту
            
            // Обновляем дату для разового расписания через специализированный метод репозитория
            repo.updateOneTimeSchedule(id: scheduleId, newDate: newDate)
            
            // Перепланируем только это расписание (если оно ещё существует)
            if let updated = repo.getById(scheduleId) {
                planner.plan(for: updated)
            } else {
                // На всякий случай — глобальный пересчёт
                planner.planAll(schedules: repo.getAll())
            }
            Logger.notifications.info("Snoozed +1m for schedule=\(existing.name.isEmpty ? existing.id.uuidString : existing.name)")
            completionHandler()
            
        case "ALARM_STOP":
            // Деактивируем запись и перепланируем
            guard
                let repo = repo,
                let planner = planner,
                let scheduleId = extractScheduleId(from: req.identifier)
            else {
                completionHandler()
                return
            }
            
            repo.setActive(false, id: scheduleId)
            if let updated = repo.getById(scheduleId) {
                planner.plan(for: updated)
            } else {
                planner.planAll(schedules: repo.getAll())
            }
            Logger.notifications.info("Stopped schedule=\(scheduleId)")
            completionHandler()
            
        default:
            completionHandler()
        }
        
    }
}

