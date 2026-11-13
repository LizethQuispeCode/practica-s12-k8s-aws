#!/usr/bin/env bash
# Diagnostico rapido del namespace practica-s12 (k3s sobre EC2).
# Uso: bash scripts/diagnostico.sh [namespace]
NS="${1:-practica-s12}"

titulo() { echo; echo "=== $1 ==="; }

titulo "Nodo"
kubectl get nodes -o wide

titulo "Pods"
kubectl get pods -n "$NS" -o wide

titulo "Deployments, Services y Endpoints"
kubectl get deployments,services,endpoints -n "$NS"

titulo "ConfigMaps y Secrets (solo nombres, sin mostrar valores)"
kubectl get configmap,secret -n "$NS"

titulo "Ultimos eventos del namespace"
kubectl get events -n "$NS" --sort-by=.lastTimestamp | tail -15

titulo "Pods que no estan Running y listos"
NO_LISTOS=$(kubectl get pods -n "$NS" --no-headers | awk '{split($2,a,"/"); if ($3!="Running" || a[1]!=a[2]) print $1}')
if [ -z "$NO_LISTOS" ]; then
  echo "Todos los pods estan Running y listos."
else
  for pod in $NO_LISTOS; do
    echo "--- eventos de $pod"
    kubectl describe pod "$pod" -n "$NS" | sed -n '/^Events:/,$p'
    echo "--- logs de $pod"
    kubectl logs "$pod" -n "$NS" --tail=20 2>&1
  done
fi

titulo "Puertos del Service de la base de datos"
kubectl describe svc db-service -n "$NS" | grep -E "Port|Endpoints"

titulo "Usuario con el que corre el backend (debe ser uid=10001)"
for pod in $(kubectl get pods -n "$NS" -l app=backend -o name); do
  echo "$pod:"
  kubectl exec "$pod" -n "$NS" -- id 2>&1 || true
done

titulo "Prueba de salud por el NodePort 30080"
for ruta in health ready ""; do
  printf "/%s -> " "$ruta"
  curl -s -m 3 -w ' [HTTP %{http_code}]\n' "http://localhost:30080/$ruta" || echo "sin respuesta"
done
