//
//  FlarmoApp.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import SwiftUI

@main
struct FlarmoApp: App {
    init() {
        
        AppBootstrap().start()
        
        // Делаем сервис делегатом центра уведомлений
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
        // Запрашиваем разрешение
        NotificationService.shared.requestPermission { granted in
            print("Разрешение на уведомления: \(granted)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
