//
//  ScheduleListViewModel.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/5/25.
//

import Foundation
import Combine

@MainActor
final class ScheduleListViewModel: ObservableObject {
    @Published private(set) var items: [Schedule] = []
    private let repo: ScheduleRepository

    init(repo: ScheduleRepository) {
        self.repo = repo
        reload()
    }

    func reload() {
        items = repo.getAll().sorted(by: { (a, b) in
            // Сначала активные с ближайшим срабатыванием, потом неактивные/прошедшие
            let na = a.nextFireDate() ?? .distantFuture
            let nb = b.nextFireDate() ?? .distantFuture
            if na == nb {
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            return na < nb
        })
    }

    func delete(at offsets: IndexSet) {
        for idx in offsets {
            let s = items[idx]
            repo.delete(id: s.id)
        }
        reload()
    }
}
