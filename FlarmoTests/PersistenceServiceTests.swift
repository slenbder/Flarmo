//
//  PersistenceServiceTests.swift
//  Flarmo
//
//  Created by Кирилл Марьясов on 9/3/25.
//

import XCTest
@testable import Flarmo

final class PersistenceServiceTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var service: PersistenceService!

    override func setUp() {
        super.setUp()
        suiteName = "flarmo.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        XCTAssertNotNil(defaults, "Не удалось создать тестовый UserDefaults suite")
        service = PersistenceService(defaults: defaults)
        // Чистим на всякий
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        if let name = suiteName {
            defaults?.removePersistentDomain(forName: name)
        }
        suiteName = nil
        defaults = nil
        service = nil
        super.tearDown()
    }

    func testSaveAndLoad_SingleAlarm() {
        // given
        let date = Date().addingTimeInterval(90)
        let alarm = Alarm(time: date, label: "One", repeatPattern: RepeatPattern.none, isActive: true)

        // when
        service.saveAlarms([alarm])
        let loaded = service.loadAlarms()

        // then
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].label, "One")
        XCTAssertEqual(loaded[0].isActive, true)
        // Сравним время с точностью до минут (ISO8601 сохраняется точно, но на всякий)
        let cal = Calendar.current
        let a = cal.dateComponents([.year,.month,.day,.hour,.minute], from: alarm.time)
        let b = cal.dateComponents([.year,.month,.day,.hour,.minute], from: loaded[0].time)
        XCTAssertEqual(a, b)
    }

    func testSaveAndLoad_MultipleAlarms_WithDifferentPatterns() {
        // given
        let now = Date()
        let a1 = Alarm(time: now.addingTimeInterval(60),  label: "A1", repeatPattern: RepeatPattern.none,   isActive: true)
        let a2 = Alarm(time: now.addingTimeInterval(120), label: "A2", repeatPattern: .daily,  isActive: false)
        let a3 = Alarm(time: now.addingTimeInterval(180), label: "A3", repeatPattern: .weekly([2,3,6]), isActive: true)
        let a4 = Alarm(time: now.addingTimeInterval(240), label: "A4", repeatPattern: .custom([now.addingTimeInterval(3600)]), isActive: true)

        // when
        service.saveAlarms([a1,a2,a3,a4])
        let loaded = service.loadAlarms()

        // then
        XCTAssertEqual(loaded.count, 4)
        // Проверим по ключевым полям (id разные, это ок)
        XCTAssertEqual(loaded[1].label, "A2")
        XCTAssertEqual(loaded[1].isActive, false)
        // проверка, что repeatPattern декодится (частично)
        switch loaded[2].repeatPattern {
        case .weekly(let days)?:
            XCTAssertEqual(days, [2,3,6])
        default:
            XCTFail("ожидался weekly")
        }
    }

    func testOverwrite_SaveReplacesPreviousData() {
        // given
        let a1 = Alarm(time: Date().addingTimeInterval(60), label: "First")
        service.saveAlarms([a1])

        // when
        let a2 = Alarm(time: Date().addingTimeInterval(120), label: "Second")
        service.saveAlarms([a2])

        // then
        let loaded = service.loadAlarms()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].label, "Second")
    }

    func testLoad_WhenNoData_ReturnsEmptyArray() {
        // given
        // ничего не сохраняем

        // then
        let loaded = service.loadAlarms()
        XCTAssertEqual(loaded.count, 0)
    }

    func testLoad_WhenCorruptedData_ReturnsEmptyArray() {
        // given — кладём мусор под ключ
        let key = "flarmo.alarms.v1"
        defaults.set(Data([0xFF, 0x00, 0x01]), forKey: key)

        // when
        let loaded = service.loadAlarms()

        // then
        XCTAssertEqual(loaded.count, 0) // и не падаем
    }

    func testWipe_RemovesAllData() {
        // given
        let a = Alarm(time: Date().addingTimeInterval(60), label: "ToWipe")
        service.saveAlarms([a])

        // when
        service.wipe()

        // then
        let loaded = service.loadAlarms()
        XCTAssertTrue(loaded.isEmpty)
    }
}
