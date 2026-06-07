# TestReactService Helm Chart

Helm chart для деплоя **TestReactService** в Kubernetes — включает:
- **Backend**: Spring Boot (Tomcat) приложение с REST API
- **Frontend**: React SPA, обслуживаемый Nginx

## Архитектура

```
     [ Ingress 80/443 ]
            |
     [ Frontend Service:80 ]
            |
     [ Nginx React + API Proxy ]
       |                    |
   index.html          /api/* → [ Backend Service:8080 ]
                                 |
                          [ Spring Boot + ArangoDB ]
```

Frontend Nginx делает проксирование API-запросов (`/api/*`) на backend.

## Требования

- Kubernetes 1.24+
- Helm 3.12+
- Ingress Controller (Nginx или аналог)
- ArangoDB в namespace `arango` (или настройте свой host)

## Установка

### 1. Сборка Docker образов

```bash
# Backend
docker build -t test-react-service-backend:latest .

# Frontend
cd frontend
docker build -t test-react-service-frontend:latest .
```

> При работе с registry, добавьте тег с адресом registry и настройте `imagePullSecrets`.

### 2. Установка Chart

```bash
# Базовая установка
helm install test-react-service ./k8s/helm

# С кастомными значениями
helm install test-react-service ./k8s/helm \
  --set backend.image.repository=my-registry/backend \
  --set backend.image.tag=v1.2.3 \
  --set frontend.ingress.host=myapp.example.com \
  --set backend.config.arangodb.password=secret
```

### 3. Проверка статуса

```bash
kubectl get pods
kubectl get svc
kubectl get ingress
```

### 4. Доступ к приложению

- **С Ingress**: `http://test-react-service.local` (добавьте хост в `/etc/hosts`)
- **Без Ingress** (port-forward):
  ```bash
  kubectl port-forward svc/test-react-service-frontend 8080:80
  # Открыть: http://localhost:8080
  ```

## Обновление

```bash
helm upgrade test-react-service ./k8s/helm
```

## Удаление

```bash
helm uninstall test-react-service
```

## Настройка Values

| Параметр | Описание | По умолчанию |
|----------|----------|------------|
| `replicaCount.backend` | Реплики backend | `1` |
| `replicaCount.frontend` | Реплики frontend | `1` |
| `backend.image.repository` | Образ backend | `test-react-service-backend` |
| `backend.image.tag` | Тег backend | `latest` |
| `frontend.image.repository` | Образ frontend | `test-react-service-frontend` |
| `frontend.image.tag` | Тег frontend | `latest` |
| `frontend.ingress.enabled` | Включить Ingress | `true` |
| `frontend.ingress.host` | Хост Ingress | `test-react-service.local` |
| `frontend.ingress.className` | Класс Ingress | `nginx` |
| `backend.config.arangodb.host` | Хост ArangoDB | `arangodb.arango.svc.cluster.local` |
| `backend.config.arangodb.port` | Порт ArangoDB | `8529` |
| `backend.config.arangodb.user` | Пользователь ArangoDB | `root` |
| `backend.config.arangodb.password` | Пароль ArangoDB | `root` |

## Пример custom-values.yaml

```yaml
replicaCount:
  backend: 2
  frontend: 2

backend:
  image:
    repository: my-registry/test-react-backend
    tag: v1.0.0
  config:
    arangodb:
      host: arangodb-cluster.endpoint
      password: supersecret

frontend:
  image:
    repository: my-registry/test-react-frontend
    tag: v1.0.0
  ingress:
    enabled: true
    host: myapp.example.com
    tls:
      - secretName: myapp-tls
        hosts:
          - myapp.example.com
```

Установка:
```bash
helm install test-react-service ./k8s/helm -f custom-values.yaml
```
