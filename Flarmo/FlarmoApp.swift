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
    private let registry = DefaultsNotificationRegistry()
    private let calculator = RecurrenceCalculator()
    private let planner: NotificationPlanner
    // private let appRepo: ScheduleRepository = InMemoryScheduleRepository()
    private let appRepo = FileScheduleRepository()  // ← вот так
    @Environment(\.scenePhase) private var scenePhase
    private let bootstrap: AppBootstrap
    @State private var lastPlanAllAt: Date = .distantPast

    init() {
        self.planner = NotificationPlanner(
            calculator: calculator,
            registry: registry,
            center: UNUserNotificationCenter.current(),
            nowProvider: Date.init
        )
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        self.bootstrap = AppBootstrap(repo: appRepo)
        NotificationCategoriesRegistrar.register()
        bootstrap.start()
    }

    var body: some Scene {
        WindowGroup {
            ScheduleListView(repo: appRepo, planner: planner)
                .onAppear {
                    NotificationService.shared.requestPermission { granted in
                        print("Разрешение на уведомления: \(granted)")
                        NotificationService.shared.removeLegacyPending {
                            // Первичный прогон планировщика после очистки легаси
                            planner.planAll(schedules: appRepo.getAll())
                            lastPlanAllAt = Date()
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                bootstrap.sceneBecameActive()
                let now = Date()
                if now.timeIntervalSince(lastPlanAllAt) > 2 {
                    planner.planAll(schedules: appRepo.getAll())
                    lastPlanAllAt = now
                }
            }
        }
    }
}
