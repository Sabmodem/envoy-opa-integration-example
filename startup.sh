#!/bin/bash

# startup.sh - Скрипт для запуска и тестирования системы

echo "🚀 Запуск Envoy + OPA системы..."

# Создаем сеть если не существует
docker network create microservices-network 2>/dev/null || echo "Сеть microservices-network уже существует"

# Запускаем систему
echo "📦 Запуск контейнеров..."
docker-compose up -d

# Ждем запуска всех сервисов
echo "⏳ Ожидание запуска сервисов..."
sleep 10

# Проверяем статус контейнеров
echo "📊 Статус контейнеров:"
docker-compose ps

# Функция для тестирования
test_endpoint() {
    local url=$1
    local description=$2
    local auth_header=$3
    
    echo ""
    echo "🧪 Тестируем: $description"
    echo "URL: $url"
    
    if [ -n "$auth_header" ]; then
        echo "Auth: $auth_header"
        response=$(curl -s -w "HTTP_CODE:%{http_code}" -H "$auth_header" "$url")
    else
        echo "Auth: None"
        response=$(curl -s -w "HTTP_CODE:%{http_code}" "$url")
    fi
    
    http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_CODE:[0-9]*$//')
    
    echo "Ответ: HTTP $http_code"
    if [ ${#body} -lt 200 ]; then
        echo "Тело ответа: $body"
    else
        echo "Тело ответа: ${body:0:200}..."
    fi
}

echo ""
echo "🔍 Начинаем тестирование..."

# Проверяем admin интерфейс Envoy
echo ""
echo "📊 Админ интерфейс Envoy: http://localhost:9901"

# Тестируем различные сценарии
test_endpoint "http://localhost:8080/health" "Health check (без авторизации)"
test_endpoint "http://localhost:8080/api/service1/" "Service 1 без токена"
test_endpoint "http://localhost:8080/api/service1/" "Service 1 с valid токеном" "Authorization: Bearer valid-token-123"
test_endpoint "http://localhost:8080/api/service1/" "Service 1 с invalid токеном" "Authorization: Bearer invalid-token"

echo ""
echo "✅ Тестирование завершено!"
echo ""
echo "📝 Полезные команды:"
echo "  - Логи Envoy: docker logs envoy-gateway"
echo "  - Логи OPA: docker logs opa-server"
echo "  - Admin Envoy: http://localhost:9901"
echo "  - Остановить: docker-compose down"
echo ""
echo "🔧 Для отладки:"
echo "  - Проверить конфигурацию: curl -s http://localhost:9901/config_dump"
echo "  - Статистика: curl -s http://localhost:9901/stats"
echo ""
echo "🔑 Валидные токены для тестирования:"
echo "  - valid-token-123"
