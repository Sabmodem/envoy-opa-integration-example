package envoy.authz

# ПОЛИТИКА С ПРОВЕРКОЙ ТОКЕНА
default allow = false

# Разрешаем доступ если есть правильный токен
allow if {
    # Получаем заголовок Authorization
    auth_header := input.attributes.request.http.headers.authorization
    
    # Проверяем что это Bearer токен
    startswith(auth_header, "Bearer ")
    
    # Извлекаем токен
    token := substring(auth_header, 7, -1)
    
    # Разрешенные токены
    token == "valid-token-123"
}

# Можно добавить отладочную информацию
debug_info := {
    "path": input.attributes.request.http.path,
    "method": input.attributes.request.http.method,
    "auth_header": input.attributes.request.http.headers.authorization
}
