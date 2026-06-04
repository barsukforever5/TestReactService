# Build & Deploy Pipeline

## Файлы

- `build.sh` — скрипт сборки (Git Bash)
- `.version.backend` — версия backend
- `.version.frontend` — версия frontend

## Принцип: только то, что изменилось

```
./build.sh
  │
  ├── git diff -w --name-only HEAD   # игнорирует CRLF
  ├── frontend/src/App.jsx changed?  → собираем только frontend
  ├── src/ или pom.xml changed?      → собираем только backend
  └── оба изменились?               → собираем оба
```

## Stages

```
Stage 1: Build
  backend:  mvn → podman build
  frontend: npm ci + npm run build → podman build

Stage 2: Push
  podman push docker.io/barsukforever5/react-xxx-image:vN

Stage 3: Deploy (вывод команд)
  ssh makanin@146.103.121.31 "kubectl set image deployment/..."
```

## Флаги

```bash
./build.sh                    # авто-детект
./build.sh --frontend-only  # форсировать frontend
./build.sh --backend-only     # форсировать backend
./build.sh --both             # оба, даже если нет изменений
./build.sh -v 6               # фиксированная версия v6
./build.sh --skip-build       # пропустить сборку
./build.sh --skip-push        # пропустить push
./build.sh --skip-deploy      # пропустить deploy-команды
```

## Deploy формат

```bash
# backend:
kubectl set image deployment/react-backend-app \
  react-backend=docker.io/barsukforever5/react-backend-image:vN \
  -n dev-1

# frontend:
kubectl set image deployment/react-frontend-app \
  react-frontend=docker.io/barsukforever5/react-frontend-image:vN \
  -n dev-1
```

## Подготовка

```bash
# Залогиниться в Docker Hub через Podman (в Git Bash)
podman login docker.io -u barsukforever5
```

## Проверка

```bash
# На сервере или по копии из вывода скрипта:
ssh makanin@146.103.121.31 "kubectl get pods -n dev-1"
```
