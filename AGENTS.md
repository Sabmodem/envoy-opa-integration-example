# Agent Instructions

## Quick Start
```bash
./startup.sh
```

## Key Facts

**Ports:**
- Envoy API Gateway: `8080` (API), `9901` (Admin)
- OPA: `8181` (HTTP), `9191` (gRPC)
- Test Service: `8081`

**Valid token:** `valid-token-123`

**Routes:**
- `/health` - No auth required
- `/api/service1/*` - Requires auth

**Debug commands:**
```bash
docker logs envoy-gateway
docker logs opa-server
curl http://localhost:9901/config_dump
curl http://localhost:9901/stats
```

## Modifying OPA Policies
Edit `opa/policies/authz.rego`. Valid tokens defined in:
```rego
token == "valid-token-123"
```

## Adding Services
1. Add cluster to `envoy/envoy.yaml` under `clusters`
2. Add route under `routes`
3. `docker-compose restart envoy`

## Testing
Run `./startup.sh` for built-in test suite, or use:
```bash
curl -H "Authorization: Bearer valid-token-123" http://localhost:8080/api/service1/
curl http://localhost:8080/health
curl -H "Authorization: Bearer invalid-token" http://localhost:8080/api/service1/  # expects 403
```
