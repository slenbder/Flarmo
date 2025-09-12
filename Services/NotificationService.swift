//
//  NotificationService.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation
import UserNotifications

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        registerCategories() // важно: экшены будут доступны уже на первом уведомлении
    }
    
    // MARK: - Permissions
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Ошибка запроса разрешения: \(error)")
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
            title: "Отложить на 10 мин",
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
                print("[NotificationService] Removed legacy pending: \(legacy.count)")
            } else {
                print("[NotificationService] No legacy pending found")
            }
            completion?()
        }
    }
    
    func listScheduledNotifications() {
        center.getPendingNotificationRequests { requests in
            print("📋 Текущее количество уведомлений: \(requests.count)")
            for req in requests {
                print("— \(req.identifier): \(req.content.body)")
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
                print("❌ Ошибка тестового уведомления: \(error)")
            } else {
                print("✅ Тестовое уведомление запланировано (через 10 секунд)")
            }
        }
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
            // Клонируем контент и ставим пуш на +10 минут
            let newContent = (req.content.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()
            newContent.title = req.content.title
            newContent.body = req.content.body
            newContent.sound = .default
            newContent.categoryIdentifier = "ALARM_ACTIONS"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
            let newId = req.identifier + "_snooze_" + String(Int(Date().timeIntervalSince1970))
            let newReq = UNNotificationRequest(identifier: newId, content: newContent, trigger: trigger)
            center.add(newReq) { error in
                if let error = error {
                    print("❌ Snooze add error: \(error)")
                } else {
                    print("⏰ Snoozed +10m → id=\(newId)")
                }
            }

        case "ALARM_STOP":
            // Удаляем будущие pending для исходного id
            center.removePendingNotificationRequests(withIdentifiers: [req.identifier])
            print("🛑 Stopped pending id=\(req.identifier)")

        default:
            break
        }

        // лог открытия уведомления оставляем как есть
        print("👉 Пользователь открыл уведомление: \(req.identifier)")
        completionHandler()
    }
}
