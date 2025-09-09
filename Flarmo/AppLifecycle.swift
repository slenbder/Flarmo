//
//  AppLifecycle.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/9/25.
//

import SwiftUI
import Combine

final class AppLifecycle: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let planner: NotificationPlanning
    private let schedulesProvider: () -> [Schedule]

    init(planner: NotificationPlanning, schedulesProvider: @escaping () -> [Schedule]) {
        self.planner = planner
        self.schedulesProvider = schedulesProvider
        setupSignals()
    }

    func scenePhaseDidBecomeActive() {
        planner.planAll(schedules: schedulesProvider())
    }

    private func setupSignals() {
        // Смена календарных суток
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                guard let self else { return }
                self.planner.planAll(schedules: self.schedulesProvider())
            }.store(in: &cancellables)

        // Существенные изменения времени (включая переходы лето/зима)
        NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.planner.planAll(schedules: self.schedulesProvider())
            }.store(in: &cancellables)

        // Смена часового пояса
        NotificationCenter.default.publisher(for: NSNotification.Name.NSSystemTimeZoneDidChange)
            .sink { [weak self] _ in
                guard let self else { return }
                self.planner.planAll(schedules: self.schedulesProvider())
            }.store(in: &cancellables)
    }
}
