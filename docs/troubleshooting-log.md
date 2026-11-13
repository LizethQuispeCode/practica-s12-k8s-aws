# Bitácora de Troubleshooting - practica-s12

Entorno: k3s sobre EC2 (AWS), namespace `practica-s12`. Las fallas se reprodujeron de forma intencional para documentar el diagnóstico.

## Falla A: CrashLoopBackOff por variable de entorno incorrecta
- **Síntoma:** pods `backend` en `CrashLoopBackOff`.
- **Diagnóstico:** `kubectl logs <pod>` mostró `ERROR: faltan variables de entorno: DB_HOST`. `kubectl get configmap app-config -o yaml` mostró la clave `DB_HOSTNAME`, pero la aplicación espera `DB_HOST`.
- **Solución:** renombrar la clave a `DB_HOST` en `k8s/01-security-configmap.yaml`, aplicar y ejecutar `kubectl rollout restart deployment backend`.

## Falla C: reinicios constantes por livenessProbe
- **Síntoma:** el pod nuevo quedaba en `0/1` y sumaba reinicios.
- **Diagnóstico:** `kubectl describe pod` mostró `Liveness probe failed: HTTP probe failed with statuscode: 404` y `Container backend failed liveness probe, will be restarted`. La sonda apuntaba a `/healthz` y la aplicación responde en `/health`.
- **Solución:** cambiar `path: /healthz` por `path: /health` en `k8s/03-app-deployment.yaml`.

## Falla B: el backend no llega al puerto de la base de datos
- **Síntoma:** `Readiness probe failed: statuscode: 503` y `ConnectionRefusedError: [Errno 111]` al conectar a `db-service:6379`.
- **Diagnóstico:** `kubectl describe svc db-service` mostró `TargetPort: 6380/TCP` y `Endpoints: 10.42.0.10:6380`, mientras que Redis escucha en el puerto 6379.
- **Solución:** corregir `targetPort: 6379` en el Service `db-service` y aplicar.

## Resultado
Todos los pods en `1/1 Running` con 0 reinicios, `endpoints/db-service` en `:6379`, `/health` y `/ready` responden 200 y la app responde por el NodePort 30080.

## Hardening de seguridad
- `runAsNonRoot: true`, `runAsUser: 10001` a nivel de Pod y de contenedor.
- `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false` y `capabilities: drop ALL`.
- Contraseña de la base de datos en un Secret (Base64) inyectada con `secretKeyRef`.
- Verificación: `kubectl exec <pod> -- id` devuelve `uid=10001`, y escribir en `/` o `/app` da `Read-only file system`.
