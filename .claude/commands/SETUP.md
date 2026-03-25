# Как установить конфиг Claude Code для Flarmo

## Структура файлов

Положи файлы в корень проекта так:

```
Flarmo/
├── CLAUDE.md                    ← (ты уже положил)
├── .claude/
│   ├── settings.json            ← permissions (из этого архива)
│   └── commands/
│       ├── build.md             ← /build
│       ├── audit.md             ← /audit
│       ├── feature.md           ← /feature <описание>
│       ├── fix.md               ← /fix <описание бага>
│       ├── status.md            ← /status
│       └── refactor.md          ← /refactor <что рефакторить>
```

## Шаги

1. В корне Flarmo создай папку `.claude/commands/`:
   ```bash
   mkdir -p .claude/commands
   ```

2. Скопируй `settings.json` в `.claude/`
3. Скопируй все .md файлы из `commands/` в `.claude/commands/`

4. Зайди в Claude Code:
   ```bash
   claude
   ```

5. Проверь что команды подхватились — начни набирать `/` и увидишь список.

## Как пользоваться

| Команда | Что делает |
|---------|-----------|
| `/build` | Собирает проект, показывает ошибки |
| `/audit` | Полный аудит кода на проблемы |
| `/feature сменный график UI` | Планирует и реализует фичу |
| `/fix будильник не звонит` | Находит и чинит баг |
| `/status` | Обзор состояния проекта и git |
| `/refactor NotificationPlanner` | Рефакторинг компонента |

## Что разрешено Claude (permissions)

**Без спроса (allow):**
- Чтение любых файлов
- Запись и редактирование
- Сборка (xcodebuild, swift build)
- Git: status, diff, log, add, commit, branch, checkout, stash
- XcodeBuildMCP — все операции
- Утилиты: cat, find, grep, ls, head, tail, sed, sort, open

**Заблокировано (deny):**
- `rm -rf` — массовое удаление
- Удаление DerivedData
- `git push` — пуш только руками
- `git rebase`, `git reset --hard`, `git clean` — опасные git-операции
