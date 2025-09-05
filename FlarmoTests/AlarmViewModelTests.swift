//
//  AlarmViewModelTests.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import XCTest
@testable import Flarmo

// MARK: - Mocks

final class MockNotifier: NotificationScheduling {
    var scheduled: [UUID] = []
    var canceled: [UUID] = []
    var updated: [UUID] = []

    func scheduleNotification(for alarm: Alarm) { scheduled.append(alarm.id) }
    func cancelNotification(for alarm: Alarm) { canceled.append(alarm.id) }
    func updateNotification(for alarm: Alarm) { updated.append(alarm.id) }
}

final class MockPersistence: AlarmPersistence {
    var stored: [Alarm] = []
    var saveCalls = 0

    func saveAlarms(_ alarms: [Alarm]) {
        saveCalls += 1
        stored = alarms
    }
    func loadAlarms() -> [Alarm] { stored }
}

// MARK: - Tests

final class AlarmViewModelTests: XCTestCase {

    func testAddAlarm_AppendsAndSchedules() {
        let notifier = MockNotifier()
        let persistence = MockPersistence()
        let vm = AlarmViewModel(notifier: notifier, persistence: persistence)

        let alarm = Alarm(time: Date().addingTimeInterval(60), label: "Test")
        vm.addAlarm(alarm)

        XCTAssertEqual(vm.alarms.count, 1)
        XCTAssertEqual(notifier.scheduled, [alarm.id])
        XCTAssertEqual(persistence.stored.count, 1)   // didSet сработал
    }

    func testRemoveAlarm_RemovesAndCancels() {
        let notifier = MockNotifier()
        let persistence = MockPersistence()
        let alarm = Alarm(time: Date().addingTimeInterval(60), label: "ToRemove")
        persistence.stored = [alarm]

        let vm = AlarmViewModel(notifier: notifier, persistence: persistence)
        XCTAssertEqual(vm.alarms.count, 1)

        vm.removeAlarm(at: 0)

        XCTAssertEqual(vm.alarms.count, 0)
        XCTAssertEqual(notifier.canceled, [alarm.id])
    }

    func testToggleAlarm_UpdatesNotification() {
        let notifier = MockNotifier()
        let persistence = MockPersistence()
        let alarm = Alarm(time: Date().addingTimeInterval(60), isActive: false)
        persistence.stored = [alarm]

        let vm = AlarmViewModel(notifier: notifier, persistence: persistence)
        vm.toggleAlarm(alarm)

        // После toggle состояние меняется, и должен быть вызван update
        XCTAssertEqual(notifier.updated, [alarm.id])
    }

    func testInit_LoadsAndRestoresActiveNotifications() {
        let notifier = MockNotifier()
        let persistence = MockPersistence()
        let active = Alarm(time: Date().addingTimeInterval(60), label: "Active", repeatPattern: nil, isActive: true)
        let inactive = Alarm(time: Date().addingTimeInterval(60), label: "Inactive", repeatPattern: nil, isActive: false)
        persistence.stored = [active, inactive]

        let vm = AlarmViewModel(notifier: notifier, persistence: persistence)

        XCTAssertEqual(vm.alarms.count, 2)
        // Должны восстановиться уведомления только для активных
        XCTAssertEqual(notifier.updated, [active.id])
    }

    func testUpdateAlarm_ActivatesAndSchedulesWhenWasInactive() {
        let notifier = MockNotifier()
        let persistence = MockPersistence()
        var a = Alarm(time: Date().addingTimeInterval(60), label: "Old", repeatPattern: nil, isActive: false)
        persistence.stored = [a]
        let vm = AlarmViewModel(notifier: notifier, persistence: persistence)

        a.label = "New"
        vm.updateAlarm(a, autoActivate: true)

        XCTAssertEqual(vm.alarms.first?.label, "New")
        XCTAssertTrue(vm.alarms.first?.isActive ?? false)
        XCTAssertEqual(notifier.scheduled, [a.id]) // т.к. раньше был неактивен
    }
}
