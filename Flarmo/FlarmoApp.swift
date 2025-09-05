//
//  FlarmoApp.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import SwiftUI
import UserNotifications

@main
struct FlarmoApp: App {
    // private let appRepo: ScheduleRepository = InMemoryScheduleRepository()
    private let appRepo: ScheduleRepository = FileScheduleRepository()  // ← вот так
    @Environment(\.scenePhase) private var scenePhase
    private let bootstrap: AppBootstrap

    init() {
        self.bootstrap = AppBootstrap(repo: appRepo)
        NotificationSchedulerV2.registerCategories()
        bootstrap.start()
    }

    var body: some Scene {
        WindowGroup {
            ScheduleListView(repo: appRepo)
                .onAppear {
                    NotificationService.shared.requestPermission { granted in
                        print("Разрешение на уведомления: \(granted)")
                    }
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                bootstrap.sceneBecameActive()
            }
        }
    }
}
