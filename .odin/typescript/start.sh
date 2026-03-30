#!/usr/bin/env sh
set -e

echo "Starting typescript..."
echo "ODIN_APP_DIR: ${ODIN_APP_DIR}"
echo "ODIN_DEPLOYMENT_TYPE: ${ODIN_DEPLOYMENT_TYPE}"
echo "ODIN_SERVICE_NAME: ${ODIN_SERVICE_NAME}"

cd "${ODIN_APP_DIR}" || exit

# ── Node.js runtime defaults ────────────────────────────────────────
export NODE_ENV="${NODE_ENV:-production}"

# Memory tuning: 70% of available RAM for V8 old space
if [ -f /sys/fs/cgroup/memory.max ]; then
  TOTAL_MEM_KB=$(awk '{printf "%.0f", $1/1024}' /sys/fs/cgroup/memory.max 2>/dev/null || true)
elif [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
  TOTAL_MEM_KB=$(awk '{printf "%.0f", $1/1024}' /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || true)
else
  TOTAL_MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || true)
fi

if [ -n "${TOTAL_MEM_KB}" ] && [ "${TOTAL_MEM_KB}" -gt 0 ] 2>/dev/null; then
  MAX_OLD_SPACE=$(( TOTAL_MEM_KB * 70 / 100 / 1024 ))
  export NODE_OPTIONS="${NODE_OPTIONS:-} --max-old-space-size=${MAX_OLD_SPACE}"
fi

# ── Launch ───────────────────────────────────────────────────────────
case "${ODIN_DEPLOYMENT_TYPE}" in
  *container*|*k8s*)
    exec npm run dev
    ;;
  *)
    nohup npm run dev > /opt/logs/typescript.log 2>&1 &
    echo $! > "${ODIN_APP_DIR}/.app.pid"
    ;;
esac
