#!/bin/bash
set -euo pipefail

# Windows JDK in Git Bash format
export JAVA_HOME="/c/jdk-17"
export PATH="$JAVA_HOME/bin:$PATH"

# ============================================================
# CI/CD: сборка, push и деплой backend / frontend (Podman + Docker Hub)
# ============================================================

REGISTRY="docker.io/barsukforever5"
BACKEND_IMAGE="react-backend-image"
FRONTEND_IMAGE="react-frontend-image"

NAMESPACE="dev-1"
BACKEND_DEPLOYMENT="react-backend-app"
FRONTEND_DEPLOYMENT="react-frontend-app"
BACKEND_CONTAINER="react-backend-container"
FRONTEND_CONTAINER="react-frontend-container"

BACKEND_VER_FILE=".version.backend"
FRONTEND_VER_FILE=".version.frontend"

FRONTEND_URL="https://react.barsukforever.dev/"

# --- Флаги ---
SKIP_BUILD=false
SKIP_PUSH=false
SKIP_DEPLOY=false
BACKEND_ONLY=false
FRONTEND_ONLY=false
BACKEND_VERSION=""
FRONTEND_VERSION=""

log_info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_ok()    { echo -e "\033[1;32m[OK]\033[0m   $*"; }
log_warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERR]\033[0m  $*"; }

usage() {
  cat <<EOF
Использование: $0 [OPTIONS]

ОПЦИИ:
  -v, --version X        Общая версия (vX) для обоих
      --backend-version X
      --frontend-version X
  --backend-only         Только backend
  --frontend-only        Только frontend
  --skip-build           Пропустить mvn/npm сборку и podman build
  --skip-push            Пропустить podman push
  --skip-deploy          Пропустить вывод deploy-команд
  -h, --help             Справка

ПРИМЕРЫ:
  $0                           # собрать оба сервиса
  $0 -v 6                      # оба сервиса с версией v6
  $0 --backend-only            # только backend
  $0 --frontend-only --skip-deploy
  $0 --skip-build --skip-push  # только вывод deploy-команд
EOF
}

next_version() {
  local f="$1"
  if [[ -f "$f" ]]; then
    local cur
    cur=$(<"$f" tr -d '[:space:]')
    cur="${cur#v}"
    [[ "$cur" =~ ^[0-9]+$ ]] && echo "$((cur + 1))" || echo "1"
  else
    echo "1"
  fi
}

# --- Разбор аргументов ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--version)
      BACKEND_VERSION="v${2#v}"
      FRONTEND_VERSION="v${2#v}"
      shift 2
      ;;
    --backend-version)
      BACKEND_VERSION="v${2#v}"
      BACKEND_ONLY=true
      shift 2
      ;;
    --frontend-version)
      FRONTEND_VERSION="v${2#v}"
      FRONTEND_ONLY=true
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=true; shift
      ;;
    --skip-push)
      SKIP_PUSH=true; shift
      ;;
    --skip-deploy)
      SKIP_DEPLOY=true; shift
      ;;
    --backend-only)
      BACKEND_ONLY=true; shift
      ;;
    --frontend-only)
      FRONTEND_ONLY=true; shift
      ;;
    -h|--help)
      usage; exit 0
      ;;
    *)
      log_error "Неизвестный аргумент: $1"; usage; exit 1
      ;;
  esac
done

if [[ "$BACKEND_ONLY" == true && "$FRONTEND_ONLY" == true ]]; then
  log_error "--backend-only и --frontend-only нельзя вместе"; exit 1
fi

# --- Вычисление версий ---
if [[ -z "$BACKEND_VERSION" ]]; then
  BACKEND_VERSION="v$(next_version "$BACKEND_VER_FILE")"
  log_info "Backend версия (auto): $BACKEND_VERSION"
else
  log_info "Backend версия (manual): $BACKEND_VERSION"
fi

if [[ -z "$FRONTEND_VERSION" ]]; then
  FRONTEND_VERSION="v$(next_version "$FRONTEND_VER_FILE")"
  log_info "Frontend версия (auto): $FRONTEND_VERSION"
else
  log_info "Frontend версия (manual): $FRONTEND_VERSION"
fi

BACKEND_FULL="$REGISTRY/$BACKEND_IMAGE:$BACKEND_VERSION"
FRONTEND_FULL="$REGISTRY/$FRONTEND_IMAGE:$FRONTEND_VERSION"

# --- Backend ---
backend_build() {
  log_info "=== BACKEND: maven build ==="
  mvn clean package -DskipTests
  log_info "=== BACKEND: podman build ==="
  podman build -t "$BACKEND_IMAGE:$BACKEND_VERSION" -f Dockerfile .
  podman tag "$BACKEND_IMAGE:$BACKEND_VERSION" "$BACKEND_FULL"
  log_ok  "Backend образ: $BACKEND_FULL"
}

backend_push() {
  log_info "Backend: podman push → $BACKEND_FULL"
  podman push "$BACKEND_FULL"
}

backend_deploy() {
  echo ""
  log_info "=== BACKEND DEPLOY COMMAND ==="
  echo "kubectl set image deployment/$BACKEND_DEPLOYMENT ${BACKEND_CONTAINER}=$BACKEND_FULL -n $NAMESPACE"
  log_ok "Backend deployment command ready: $BACKEND_DEPLOYMENT"
}

# --- Frontend ---
frontend_build() {
  log_info "=== FRONTEND: npm ci && npm run build ==="
  (cd frontend && npm ci && npm run build)
  log_info "=== FRONTEND: podman build ==="
  podman build -t "$FRONTEND_IMAGE:$FRONTEND_VERSION" -f frontend/Dockerfile ./frontend
  podman tag "$FRONTEND_IMAGE:$FRONTEND_VERSION" "$FRONTEND_FULL"
  log_ok  "Frontend образ: $FRONTEND_FULL"
}

frontend_push() {
  log_info "Frontend: podman push → $FRONTEND_FULL"
  podman push "$FRONTEND_FULL"
}

frontend_deploy() {
  echo ""
  log_info "=== FRONTEND DEPLOY COMMAND ==="
  echo "kubectl set image deployment/$FRONTEND_DEPLOYMENT ${FRONTEND_CONTAINER}=$FRONTEND_FULL -n $NAMESPACE"
  log_ok "Frontend deployment command ready: $FRONTEND_DEPLOYMENT"
}

# --- Main ---
main() {
  log_info "Backend  → $BACKEND_FULL"
  log_info "Frontend → $FRONTEND_FULL"

  if [[ "$SKIP_BUILD" == false ]]; then
    [[ "$FRONTEND_ONLY" == false ]] && backend_build
    [[ "$BACKEND_ONLY" == false ]]  && frontend_build
  else
    log_warn "Сборка пропущена (--skip-build)"
  fi

  if [[ "$SKIP_PUSH" == false ]]; then
    [[ "$FRONTEND_ONLY" == false ]] && backend_push
    [[ "$BACKEND_ONLY" == false ]]  && frontend_push
  else
    log_warn "Push пропущен (--skip-push)"
  fi

  if [[ "$SKIP_DEPLOY" == false ]]; then
    echo ""
    log_info "╔════════════════════════════════════════════════════╗"
    log_info "║  COPY-PASTE these commands on your K8s server     ║"
    log_info "╚════════════════════════════════════════════════════╝"
    [[ "$FRONTEND_ONLY" == false ]] && backend_deploy
    [[ "$BACKEND_ONLY" == false ]]  && frontend_deploy
    echo ""
    [[ "$BACKEND_ONLY" == false ]] && log_info "Check frontend: $FRONTEND_URL"
    echo ""
  else
    log_warn "Деплой пропущен (--skip-deploy)"
  fi

  # Сохраняем версии
  if [[ "$FRONTEND_ONLY" == false ]]; then
    echo "${BACKEND_VERSION#v}" > "$BACKEND_VER_FILE"
  fi
  if [[ "$BACKEND_ONLY" == false ]]; then
    echo "${FRONTEND_VERSION#v}" > "$FRONTEND_VER_FILE"
  fi

  log_ok "Пайплайн завершён!"
}

main
