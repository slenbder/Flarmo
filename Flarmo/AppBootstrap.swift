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

    /// DI-friendly bootstrap so мы не плодим разные репозитории в разных местах
    init(repo: ScheduleRepository,
         migrator: MigrationRunning? = nil) {
        self.repo = repo
        if let migrator = migrator {
            self.migrator = migrator
        } else {
            self.migrator = MigrationV1toV2(repo: repo)
        }
    }

    func start() {
        print("[AppBootstrap] Starting app bootstrap")
        migrator.runIfNeeded()
        let all = repo.getAll()
        print("[AppBootstrap] Loaded \(all.count) schedules from repo")
    }
}
