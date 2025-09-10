//
//  AppBootstrap.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

//
//  AppBootstrap.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation

final class AppBootstrap {
    private let repo: ScheduleRepository
    private let migrator: MigrationRunning
    private let notifier: NotificationsScheduling

    /// DI-friendly bootstrap: один репозиторий и один планировщик во всём приложении
    init(
        repo: ScheduleRepository,
        migrator: MigrationRunning? = nil,
        notifier: NotificationsScheduling = DefaultNotificationsScheduler()
    ) {
        self.repo = repo
        self.migrator = migrator ?? MigrationV1toV2(repo: repo)
        self.notifier = notifier
    }

    func start() {
        print("[AppBootstrap] Starting app bootstrap")
        // Регистрируем категории уведомлений один раз при старте
        NotificationCategoriesRegistrar.register()

        // Миграции данных
        migrator.runIfNeeded()

        // Диагностика текущего состояния
        let all = repo.getAll()
        print("[AppBootstrap] Loaded \(all.count) schedules from repo")

        // Перепланируем локальные уведомления (пока no-op реализация)
        notifier.rescheduleAllIfNeeded()
    }

    /// Хук для пересборки уведомлений при возврате приложения на передний план
    func sceneBecameActive() {
        notifier.rescheduleAllIfNeeded()
    }
}
