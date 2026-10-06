# Own

[English version](README.md)

Плагин для Claude Code: помогает практикующим разработчикам сохранять владение архитектурой и кодом, когда код пишет Claude.

## Зачем

Когда большую часть кода пишет Claude, решения размываются: дизайн «улучшают» мимоходом, а через неделю никто не может сказать, почему код устроен именно так. Own держит вас у руля с помощью трёх механизмов:

- **ADR, которые Claude обязан соблюдать.** Вы фиксируете решения в Architecture Decision Records. В начале сессии Claude получает индекс Accepted ADR и правило: если задача противоречит Accepted ADR, нужно остановиться и сказать об этом до того, как писать код.
- **Критик с чистым контекстом.** Критик читает только ваш документ и код. Обсуждение он не видел, поэтому согласиться с вами его не уговоришь.
- **Explain-back.** Перед коммитом нетривиальной логики вы сами объясняете изменение, а Claude сверяет объяснение с кодом.

## Установка

Каждую команду вводите отдельно:

```
/plugin marketplace add Tvist1988/own
/plugin install own@own
```

Если появится диалог настроек, просто нажмите Enter: значения по умолчанию рабочие.

Обновления: у сторонних marketplace автообновление по умолчанию выключено. Чтобы включить, откройте `/plugin` → **Marketplaces** → `own` → включите автообновление. Вручную: `claude plugin update own@own` в терминале или `/plugin` → вкладка **Installed** → плагин → **Update now**.

## Компоненты

| Команда | Что делает |
|---|---|
| `/own:adr-init` | Создаёт каталог ADR с индексом в README. Перед изменением `CLAUDE.md` спрашивает. |
| `/own:adr-new <название>` | Создаёт пустой каркас ADR со следующим номером. Содержимое никогда не заполняет. |
| `/own:critique [путь]` | Запускает критика в изолированном контексте и ждёт вердикта: Blocking / Risks / Questions. Без пути берёт последний Proposed ADR. |
| `/own:explain-back [base-ref]` | Спрашивает, что изменилось, как идут данные и что будет при отказе, затем сверяет каждое утверждение с кодом, с `file:line`. |
| `/output-style own:architect` | Опциональный режим: проектируете вы, Claude критикует и реализует. |
| Хук SessionStart | Добавляет в контекст Claude индекс ADR и правила работы с ними. Если в проекте нет каталога ADR, ничего не делает. |

Каждая команда срабатывает только по вашему вызову. Сам Claude скиллы и критика не запускает.

## Рабочий цикл

1. В задаче есть архитектурный выбор → `/own:adr-new Webhook idempotency`.
2. ADR пишете сами: контекст, решение, альтернативы, последствия.
3. `/own:critique docs/adr/0001-webhook-idempotency.md`.
4. Закрываете каждый пункт Blocking и записываете, как именно, в **Review notes**.
5. Ставите `Status: Accepted`.
6. Реализация. С этого момента Claude сверяет новые задачи с этим ADR.
7. Перед коммитом нетривиальной логики → `/own:explain-back` (или `/own:explain-back main` для всей ветки).

Для рутинных задач (CRUD, маппинг, переименования, тесты по согласованному контракту) ничего из этого не нужно. ADR пишут только для решений, которые дорого откатывать.

## Стиль ответов Architect

Включить: `/output-style own:architect`, выключить: `/output-style default`.

В этом режиме на архитектурных задачах (границы модулей, интерфейсы, модель данных, транзакции, конкурентность, обработка отказов, интеграции) Claude сначала спрашивает ваш подход, потом критикует его и пишет код только после вашего «го». Рутину делает сразу. Фраза «просто сделай» отключает вопросы для конкретной задачи.

Включайте, когда хотите потренировать проектирование или когда решение важное. Не включайте на день рутины, прототипов и одноразового кода: там вопросы только тормозят.

## Настройки

Меняются в `/config` или в `/plugin` → **Installed** → `own` → **Configure options**.

| Настройка | По умолчанию | Что значит |
|---|---|---|
| `adr_dir` | `docs/adr` | Каталог ADR относительно корня проекта. |
| `inject_adr_context` | `true` | Добавлять индекс ADR и правила в контекст в начале сессии. |

## Приватность

Без сети, телеметрии и внешних сервисов. В рантайме ничего, кроме POSIX `sh` и стандартных утилит.

Хук добавляет в контекст Claude следующее, и только если каталог ADR существует: по строке на каждый Accepted или Proposed ADR (`- 0001 Webhook idempotency [Accepted]`, не больше 60 строк, около 5 КБ) и четыре правила:

```
This project records architecture decisions as ADRs in docs/adr/ (relative to the project root).
Rules:
- Before changing code in an area covered by an Accepted ADR, read that ADR.
- If a task would contradict an Accepted ADR, stop and name the ADR and the conflict before writing code. Never work around an ADR silently.
- Proposed ADRs are drafts under discussion, not constraints.
- ADRs are written by the user. Do not create or edit ADR content unless the user explicitly asks.
```

## Ограничения

Всё это инструкции для модели, а не гарантии. Обычно Claude им следует, но конфликт с ADR может пропустить. Если нужны жёсткие границы модулей, проверяйте их линтерами в CI: `depguard`, `go-arch-lint`, `dependency-cruiser` и т. п.

## Удаление

```
/plugin uninstall own@own
/plugin marketplace remove own
```

Файлы ADR остаются в проекте.

## Разработка

```
sh tests/hook_test.sh
shellcheck hooks/*.sh tests/*.sh skills/*/*.sh
claude plugin validate . --strict
claude --plugin-dir .
```

## Лицензия

MIT
