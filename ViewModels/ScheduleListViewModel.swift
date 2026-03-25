//
//  ScheduleListViewModel.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation
import Combine
import OSLog

@MainActor
final class ScheduleListViewModel: ObservableObject {
    @Published private(set) var items: [Schedule] = []
    private let repo: ScheduleRepository
    private var cancellables: Set<AnyCancellable> = []

    init(repo: ScheduleRepository) {
        self.repo = repo
        setupBindings()
        reload()
    }

    func reload() {
        let all = repo.getAll()
        let before = items.count
        items = all.sorted(by: { (a, b) in
            // Сначала активные с ближайшим срабатыванием, потом неактивные/прошедшие
            let na = a.nextFireDate() ?? .distantFuture
            let nb = b.nextFireDate() ?? .distantFuture
            if na == nb {
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            return na < nb
        })
        let after = items.count
        Logger.ui.debug("reload() items: before=\(before) after=\(after)")
        if !items.isEmpty {
            let summary = items.prefix(3).map { s -> String in
                let nextStr = s.nextFireDate().map { "\($0)" } ?? "nil"
                return "\(s.name.isEmpty ? s.id.uuidString : s.name)[\(s.id)] next=\(nextStr)"
            }.joined(separator: " | ")
            Logger.ui.debug("top items: \(summary)\(self.items.count > 3 ? " ..." : "")")
        }
    }

    func delete(at offsets: IndexSet) {
        for idx in offsets {
            let s = items[idx]
            Logger.ui.info("delete request id=\(s.id) name=\(s.name)")
            repo.delete(id: s.id)
        }
        // Локально обновим сразу; событие из репозитория тоже придёт
        reload()
    }

    private func setupBindings() {
        repo.changes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                switch change {
                case .inserted(let ids):
                    Logger.ui.debug("repo change: inserted ids=\(Array(ids))")
                case .updated(let ids):
                    Logger.ui.debug("repo change: updated ids=\(Array(ids))")
                case .deleted(let ids):
                    Logger.ui.debug("repo change: deleted ids=\(Array(ids))")
                case .snapshot:
                    Logger.ui.debug("repo change: snapshot")
                }
                self?.reload()
            }
            .store(in: &cancellables)
    }
}

