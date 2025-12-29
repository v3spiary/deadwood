# Builder Platform

Немного наскальных рукописей, что к чему.

## На чем разворачивал

|  Характеристика  |   Значение  |
| --- | --- |
|  Количество нод   |  1   |
| CPU | 4 |
| RAM | 32 Гб |
| Disk | 100 Гб |
| GPU | 1x Tesla T4 |

> [!NOTE]
> На тачке кстати был предустановлен докер и 535 драйвер, если че их установки в плейбуках нет.

## Технологический стек

- Фронтэнд: `Vue.js` + `Shadcn/vue`
- Бэкэнд: `Django` (API на `DRF`, веб-сокеты на `Django Channels`)
- `Celery worker` (асинхронные операции) и `beat` (по таймеру) предусмотрены, но пока не пригодились
- Реляционная СУБД `Postgres`
- `Redis` для веб-сокетов
- LLM запускается на ollama, модель `evilfreelancer/o1_gigachat:20b` вроде норм себя на демо показала.

Это основное. Там еще мониторинг Grafana, Prometheus, Loki, экспортеры, интегрировано на полшишки. Трейсы не было времени. 

> [!NOTE]
> Пытался интегрировать WAF. В `docker-compose.yml` закоментирован сервис ModSecurity, для http работает, стандартные паттерны блочит, но сокеты через этот контейнер не проксируются (опция там специальная есть). Если разберетесь как подружить с сокетами - мне потом расскажите, а то мне тоже интересно.

Ansible плейбуки рабочие. CI/CD тоже.

> [!CAUTION]
> Из проблем безопасности есть вопиющая: захардкоженные креды в initdb.py, в docker-compose.yml. Избавиться от этого в первую очередь.

> [!WARNING]
> И тесты напишите заодно.

## CI/CD

- `.github/workflows/ci-frontend.yml`: собирает бандл фронта, пакует в докер образ и пушит в хранилище, использовалось Selectel.

- `.github/workflows/ci-backend.yml`: собирает образ бэкэнда.

- `.github/workflows/ci-worker.yml`: собирает образ асинхронного воркера/beat 

- `.github/workflows/cd-slow.yml`: нужен если раскатываем на пустом сервере, запускает все плейбуки чтобы настроить сервак с нуля.

- `.github/workflows/cd-fast.yml`: этот запускается на уже настроенном серваке, если надо просто догрузить обновления на прод.

> [!NOTE]
> По триггерам в двух словах: настраивал точечный CI/CD процесс только для измененного компонента (коммит затронул фронт - пересобрали обновили фронт, бэк - бэк, плейбук - прогнали его заново)

### Секреты в CI/CD

- `NEW_USERNAME`: пользователь, под которым логинитесь
- `SERVER_IP`: хост
- `SSH_PRIVATE_KEY`: приватный ssh ключ
- `USER_PASSWORD`: планировался sudo-пароль, но пока в работу не пошел.

По инфраструктуре вроде все. Код описывать в падлу, смотрите сами. 

## Архитектура

### Уровень 1

```mermaid
graph TB
    %% Стили для разных типов компонентов
    classDef waf fill:#ff9999,stroke:#333,stroke-width:2px
    classDef frontend fill:#99ccff,stroke:#333
    classDef backend fill:#99ff99,stroke:#333
    classDef database fill:#ffcc99,stroke:#333
    classDef cache fill:#ff99cc,stroke:#333
    classDef ai fill:#cc99ff,stroke:#333
    classDef monitoring fill:#ffff99,stroke:#333
    classDef user fill:#ccccff,stroke:#333
    
    %% Пользователь
    User[Клиент / Пользователь]:::user
    
    %% WAF/Прокси слой
    WAF[WAF OWASP ModSecurity<br/>Nginx + ModSecurity<br/>Порт: 80]:::waf
    
    %% Frontend слой
    Frontend[Frontend Vue.js + Shadcn/vue<br/>Nginx для статики<br/>Порт: 80]:::frontend
    
    %% Backend слой
    Backend[Backend Django<br/>DRF API + Channels WebSockets<br/>Порт: 8000]:::backend
    
    %% Базы данных и кеш
    DB[(PostgreSQL 17<br/>Хранилище данных)]:::database
    Redis[(Redis 7.0<br/>Кеш + WebSockets pub/sub)]:::cache
    
    %% AI слой
    Ollama[Ollama LLM<br/>Модель: evilfreelancer/o1_gigachat:20b<br/>Порт: 11434]:::ai
    
    %% Мониторинг стек (раскомментировать при использовании)
    Prometheus[Prometheus<br/>Сбор метрик<br/>Порт: 9090]:::monitoring
    Loki[Loki<br/>Сбор логов<br/>Порт: 3100]:::monitoring
    Tempo[Tempo<br/>Трассировка<br/>Порты: 3200, 4318]:::monitoring
    Grafana[Grafana 11.0.0<br/>Визуализация<br/>Порт: 3000]:::monitoring
    Promtail[Promtail<br/>Агент сбора логов]:::monitoring
    
    %% Зависимости и связи
    User -->|HTTP/WS запросы| WAF
    WAF -->|Проксирование| Frontend
    
    Frontend -->|API запросы<br/>/api/v1/| Backend
    Frontend -->|WebSocket<br/>/ws/| Backend
    
    Backend -->|Чтение/запись данных| DB
    Backend -->|WebSockets pub/sub<br/>Кеширование| Redis
    Backend -->|LLM запросы| Ollama
    
    %% Мониторинг связи
    Backend -.->|Метрики| Prometheus
    Backend -.->|Трассировки OTEL| Tempo
    Backend -.->|Логи в volume| global_logs
    
    Promtail -->|Чтение логов| global_logs
    Promtail -->|Отправка логов| Loki
    
    Prometheus -->|Запрос метрик| Grafana
    Loki -->|Запрос логов| Grafana
    Tempo -->|Запрос трассировок| Grafana
    
    %% Docker инфраструктура
    subgraph "Docker Compose Stack"
        subgraph "Сетевой слой"
            hm_net[Сеть: hm_net]
        end
        
        subgraph "Volumes"
            postgres_data[Volume: postgres_data]
            redis_data[Volume: redis_data]
            ollama_data[Volume: ollama_data]
            global_logs[Volume: global_logs]
            prometheus_data[Volume: prometheus_data]
            loki_data[Volume: loki_data]
            grafana_data[Volume: grafana_data]
            tempo_data[Volume: tempo_data]
        end
        
        subgraph "Сервисы приложения"
            WAF
            Frontend
            Backend
            DB
            Redis
            Ollama
        end
        
        subgraph "Сервисы мониторинга"
            Prometheus
            Loki
            Tempo
            Grafana
            Promtail
        end
    end
    
    %% Отношения к volumes
    DB -->|Хранит данные| postgres_data
    Redis -->|Хранит данные| redis_data
    Ollama -->|Хранит модели| ollama_data
    Prometheus -->|Хранит метрики| prometheus_data
    Loki -->|Хранит логи| loki_data
    Grafana -->|Хранит дашборды| grafana_data
    Tempo -->|Хранит трейсы| tempo_data
    
    %% Зависимости (depends_on)
    WAF -->|depends_on: healthy| Frontend
    Frontend -->|depends_on| Backend
    Backend -->|depends_on| DB
    Backend -->|depends_on| Redis
    
    %% Неиспользуемые сервисы (закомментированы)
    CeleryWorker[Celery Worker<br/>Асинхронные задачи]:::backend
    CeleryBeat[Celery Beat<br/>Планировщик]:::backend
    
    Backend -.->|При необходимости| CeleryWorker
    CeleryBeat -.->|При необходимости| CeleryWorker
    CeleryWorker -.->|Использует| Redis
    CeleryWorker -.->|Использует| DB
```

### Уровень 2

```mermaid
graph TB
    %% Стили
    classDef user fill:#ccccff,stroke:#333
    classDef client fill:#99ccff,stroke:#333
    classDef backend fill:#99ff99,stroke:#333
    classDef storage fill:#ffcc99,stroke:#333
    classDef ai fill:#cc99ff,stroke:#333
    classDef monitoring fill:#ffff99,stroke:#333
    
    %% Пользователи
    WebUser[Веб-пользователь]:::user
    MobileUser[Мобильный пользователь<br/>Android/iOS]:::user
    Admin[Администратор/DevOps]:::user
    
    %% Клиентские приложения
    WebApp[Веб-приложение<br/>Vue.js + Shadcn/vue]:::client
    MobileApp[Мобильные приложения<br/>Android & iOS]:::client
    
    %% Backend сервисы
    API[API сервер<br/>Django + DRF]:::backend
    WS[WebSocket сервер<br/>Django Channels]:::backend
    
    %% Внешние сервисы
    LLM[LLM сервис<br/>Ollama]:::ai
    
    %% Хранилища данных
    DB[Базы данных<br/>PostgreSQL + Redis]:::storage
    
    %% Мониторинг
    Monitoring[Мониторинг<br/>Grafana + Prometheus<br/>+ Loki + Tempo]:::monitoring
    
    %% Взаимодействия
    WebUser -->|HTTP/WebSocket| WebApp
    MobileUser -->|HTTP/WebSocket| MobileApp
    
    WebApp -->|API запросы| API
    WebApp -->|WebSocket| WS
    MobileApp -->|API запросы| API
    MobileApp -->|WebSocket| WS
    
    API -->|Запросы| LLM
    API -->|Чтение/запись| DB
    WS -->|Pub/Sub| DB
    
    %% Мониторинг и администрирование
    Admin -->|Конфигурация<br/>и управление| Monitoring
    API -.->|Метрики и логи| Monitoring
    WS -.->|Метрики и логи| Monitoring
    DB -.->|Метрики| Monitoring
    LLM -.->|Метрики| Monitoring
```
