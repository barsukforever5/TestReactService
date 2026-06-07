# TestReactService Helm Chart

Helm chart для деплоя **TestReactService** в Kubernetes — 1-to-1 match с серверной конфигурацией из `k8s/from_server/`.

## Архитектура

```
                    [ Ingress (Traefik) ]
                     /api        / (root)
                       |            |
       [react-backend-service:80] [react-frontend-service:80]
                |                        |
          [Tomcat:8080]           [Nginx:80]
       (Spring Boot API)         (React SPA)
```

- Ingress маршрутизирует `/api/*` напрямую на backend service (порт 80 → 8080)
- Ingress маршрутизирует `/` на frontend service (порт 80 → 80)
- TLS через Traefik + Letsencrypt (не нужен свой Secret)
- Nginx-конфиг зашит в Docker образ frontend — ConfigMap не используется

## Требования

- Kubernetes 1.24+
- Helm 3.12+
- Traefik Ingress Controller (настроен с certresolver `letsencrypt`)
- ArangoDB в namespace `arango` (или иной, указанный в Dockerfile образа)

## Установка

### Базовая установка

```bash
helm install test-react-service ./k8s/helm \
  --set ingress.host=react.barsukforever.dev
```

### С реальными образами (как на сервере)

```bash
helm install test-react-service ./k8s/helm \
  --set backend.image.tag=v13 \
  --set frontend.image.tag=v1 \
  --set ingress.host=react.barsukforever.dev \
  --set ingress.annotations."traefik.ingress.kubernetes.io/router.tls.certresolver"=letsencrypt
```

### Обновление

```bash
helm upgrade test-react-service ./k8s/helm
```

### Удаление

```bash
helm uninstall test-react-service
```

## Проверка статуса

```bash
kubectl get deployment
kubectl get svc
kubectl get ingress
kubectl get pods
```

## Настройка Values

| Параметр | Описание | По умолчанию |
|----------|----------|------------|
| `replicaCount.backend` | Реплики backend | `1` |
| `replicaCount.frontend` | Реплики frontend | `1` |
| `backend.image.repository` | Образ backend | `docker.io/barsukforever5/react-backend-image` |
| `backend.image.tag` | Тег backend | `latest` |
| `backend.service.port` | Порт backend Service | `80` |
| `backend.service.targetPort` | Порт Tomcat контейнера | `8080` |
| `backend.probes.enabled` | Включить readiness/liveness | `false` |
| `frontend.image.repository` | Образ frontend | `docker.io/barsukforever5/react-frontend-image` |
| `frontend.image.tag` | Тег frontend | `latest` |
| `ingress.enabled` | Включить Ingress | `true` |
| `ingress.host` | Хост Ingress | `test-react-service.local` |
| `ingress.className` | Ингресс-контроллер | `traefik` |
| `ingress.annotations` | Аннотации Traefik | letsencrypt, web, websecure |

## Пример custom-values.yaml

```yaml
replicaCount:
  backend: 2
  frontend: 2

backend:
  image:
    tag: v13
  probes:
    enabled: true
  env:
    - name: ARANGODB_HOST
      value: "arangodb.arango.svc.cluster.local"

frontend:
  image:
    tag: v1

ingress:
  host: react.barsukforever.dev
```

## Соответствие с серверными манифестами

| Серверный YAML | Helm шаблон | Статус |
|----------------|-------------|--------|
| `react-backend-deployment.yaml` | `templates/backend-deployment.yaml` | ✅ match |
| `react-backend-service.yaml` | `templates/backend-service.yaml` | ✅ match (port 80→8080) |
| `react-frontend-deployment.yaml` | `templates/frontend-deployment.yaml` | ✅ match |
| `react-frontend-service.yaml` | `templates/frontend-service.yaml` | ✅ match |
| `react-ingress.yaml` | `templates/ingress.yaml` | ✅ match (Traefik /api + /) |
