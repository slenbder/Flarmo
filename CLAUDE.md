# Flarmo

## Что это
iOS-приложение для будильников и уведомлений по расписанию. Альтернатива стандартным Часам с поддержкой сменных графиков, недельных расписаний и произвольных дат. Целевая аудитория — люди с нестандартным рабочим графиком.

## Стек
- Swift, SwiftUI, iOS 15+
- Combine для реактивных потоков
- UserNotifications для локальных уведомлений
- JSON + FileManager для персистентности (FileScheduleRepository)
- Архитектура: MVVM + Repository Pattern

## Структура проекта
- **Модели:** ModelsV2.swift — Schedule, ScheduleType (oneTime, shiftPattern, customDates), TimeOfDay
- **Ядро:** RecurrenceCalculator, NotificationPlanner, NotificationRegistry, NotificationFactory, NotificationService
- **Репозиторий:** FileScheduleRepository — JSON в ApplicationSupport, thread-safe через DispatchQueue, Combine change stream
- **UI:** ScheduleListView (список), EditOneTimeScheduleView (разовый будильник), ReadonlyScheduleView (заглушка для остальных типов)
- **Инфра:** AppBootstrap, MigrationV1toV2, AppLifecycle

## Текущее состояние
- ✅ Полностью готово: ядро уведомлений, планировщик, персистентность, миграция V1→V2, UI для oneTime
- 🚧 Логика готова, UI нет: shiftPattern, customDates
- 🚧 Заглушки: выбор мелодии (toneId), snooze = 60сек (должно быть 5–10 мин)
- ❌ Тестов нет

## Команды сборки и тестирования
- Билд и тесты: через XcodeBuildMCP (mcp__xcodebuildmcp__)
- Формат проекта: .xcodeproj

## Правила
- Пиши на Swift, используй SwiftUI для всех новых View
- Следуй существующей MVVM-архитектуре: View + ViewModel на каждый экран
- ViewModel использует Combine для подписки на изменения репозитория
- Новые экраны редактирования должны быть аналогичны EditOneTimeScheduleView по паттерну
- Используй существующие компоненты: цветовой пикер, модели из ModelsV2
- Локализация: весь UI на русском языке
- Коммит-сообщения на английском, Conventional Commits (feat:, fix:, refactor:)
- После каждого изменения — собери проект и проверь ошибки
- НИКОГДА не удаляй DerivedData
- Не трогай .xcodeproj руками без крайней необходимости
- При force unwrap — обязательно обоснуй или замени на guard/if let
