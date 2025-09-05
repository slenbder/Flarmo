//
//  NotificationService.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import Foundation
import UserNotifications

protocol NotificationScheduling: AnyObject {
    func scheduleNotification(for alarm: Alarm)
    func cancelNotification(for alarm: Alarm)
    func updateNotification(for alarm: Alarm)
}

class NotificationService: NSObject, UNUserNotificationCenterDelegate, NotificationScheduling {
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
    
    // MARK: - Scheduling
    
    func scheduleNotification(for alarm: Alarm) {
        guard alarm.isActive else {
            print("⏸ Будильник \(alarm.id) выключен, уведомление не ставим")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Будильник"
        content.body = alarm.label.isEmpty ? "Пора вставать!" : alarm.label
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ Ошибка планирования уведомления: \(error)")
            } else {
                print("✅ Уведомление запланировано на \(alarm.time.formattedDateTime())")
            }
        }
    }
    
    func cancelNotification(for alarm: Alarm) {
        center.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
        print("🗑 Уведомление отменено для \(alarm.id)")
    }
    
    func updateNotification(for alarm: Alarm) {
        cancelNotification(for: alarm)
        scheduleNotification(for: alarm)
    }
    
    // MARK: - Debug / Test
    
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
        completionHandler([.banner, .sound])
    }
    
    // Срабатывает, когда пользователь открыл уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👉 Пользователь открыл уведомление: \(response.notification.request.identifier)")
        completionHandler()
    }
}
