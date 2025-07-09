# Envoy + OPA Gateway Project

Микросервисная архитектура с централизованной авторизацией через Envoy и Open Policy Agent (OPA) с простой токен-based аутентификацией.

## Структура проекта

```
project/
├── docker-compose.yml          # Основной файл с Envoy + OPA
├── envoy/
│   └── envoy.yaml             # Конфигурация Envoy
├── opa/
│   ├── config.yaml            # Конфигурация OPA
│   └── policies/
│       └── authz.rego         # Политики авторизации
├── test-service/
│   ├── index.html             # Тестовый HTML
│   └── health                 # Health check
├── startup.sh                 # Скрипт запуска и тестирования
└── README.md                  # Этот файл
```

## Компоненты

- **Envoy** - API Gateway на порту 8080
- **OPA** - Сервер авторизации на порту 8181
- **Test Service** - Простой Nginx сервис для тестирования

## Маршрутизация

- `/health` - Health check (без авторизации)
- `/api/service1/*` - Сервис 1 (требует авторизации)

## Авторизация

Система использует простую токен-based авторизацию. Валидные токены настраиваются в политике OPA (`opa/policies/authz.rego`).

По умолчанию валидный токен: `valid-token-123`

## Быстрый старт

1. Сделайте скрипт исполняемым:
   ```bash
   chmod +x startup.sh
   ```

2. Запустите систему:
   ```bash
   ./startup.sh
   ```

3. Проверьте работу:
   - Admin Envoy: http://localhost:9901
   - Test Service: http://localhost:8080/api/service1/

## Тестирование

Примеры запросов:

```bash
# Без авторизации (должен работать)
curl http://localhost:8080/health

# С авторизацией (должен работать)
curl -H "Authorization: Bearer valid-token-123" http://localhost:8080/api/service1/

# Без токена (должен вернуть 403)
curl http://localhost:8080/api/service1/

# С неправильным токеном (должен вернуть 403)
curl -H "Authorization: Bearer invalid-token" http://localhost:8080/api/service1/
```

## Полезные команды

```bash
# Просмотр логов
docker logs envoy-gateway
docker logs opa-server

# Конфигурация Envoy
curl -s http://localhost:9901/config_dump | jq

# Статистика Envoy
curl -s http://localhost:9901/stats

# Остановка
docker-compose down
```

## Добавление новых сервисов

1. Добавьте кластер в `envoy/envoy.yaml`:
   ```yaml
   - name: my_new_service_cluster
     connect_timeout: 5s
     type: LOGICAL_DNS
     load_assignment:
       cluster_name: my_new_service_cluster
       endpoints:
       - lb_endpoints:
         - endpoint:
             address:
               socket_address:
                 address: my-new-service
                 port_value: 8080
   ```

2. Добавьте маршрут:
   ```yaml
   - match:
       prefix: "/api/my-new-service/"
     route:
       cluster: my_new_service_cluster
       prefix_rewrite: "/"
   ```

3. Перезапустите Envoy:
   ```bash
   docker-compose restart envoy
   ```

## Настройка политик OPA

Политики находятся в `opa/policies/authz.rego`. 

### Добавление новых токенов

Чтобы добавить новые валидные токены, отредактируйте файл `opa/policies/authz.rego`:

```rego
# Разрешенные токены
token == "valid-token-123"  # Существующий токен
token == "another-valid-token"  # Новый токен
```

### Более сложные правила авторизации

Для более сложных правил можно добавить проверку по путям, методам, пользователям и т.д.:

```rego
# Пример: разные токены для разных сервисов
allow if {
    token := get_token
    input.attributes.request.http.path == "/api/service1/"
    token == "service1-token"
}

allow if {
    token := get_token
    input.attributes.request.http.path == "/api/service2/"
    token == "service2-token"
}
```

## Переход на динамическое обнаружение сервисов

В будущем можно мигрировать на:
- Consul Connect для xDS интеграции
- Consul Template для генерации конфигурации
- Kubernetes Service Discovery

## Архитектура

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │───▶│    Envoy    │───▶│   Service   │
└─────────────┘     │  (Gateway)  │     └─────────────┘
                    └─────────────┘    
                          │
                          ▼
                   ┌───────────────┐
                   │     OPA       │
                   │(Authorization)│
                   └───────────────┘
```

1. **Клиент** отправляет запрос к Envoy Gateway
2. **Envoy** проверяет авторизацию через OPA
3. **OPA** проверяет токен согласно политикам
4. При успешной авторизации запрос проксируется к целевому сервису
