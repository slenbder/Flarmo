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
    
    // Срабатывает, когда уведомление приходит, а приложение активно
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Будильник сработал: \(notification.request.content.body)")
        completionHandler([.banner, .sound, .list])
    }
    
    // Срабатывает, когда пользователь открыл уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👉 Пользователь открыл уведомление: \(response.notification.request.identifier)")
        completionHandler()
    }
}
