//
//  AppBootstrap.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

final class AppBootstrap {
    private let repo = UserDefaultsSchedulesRepositoryV2()
    private lazy var migrator = MigrationV1toV2(repo: repo)
    private lazy var notifier = NotificationSchedulerV2()

    func start() {
        print("[AppBootstrap] Starting app bootstrap")
        migrator.runIfNeeded()
        let all = repo.fetchAll()
        print("[AppBootstrap] Loaded \(all.count) schedules from repo")
        notifier.reschedule(for: all)
    }
}
