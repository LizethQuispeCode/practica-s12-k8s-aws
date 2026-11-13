# Práctica S12 AP9: Despliegue Cloud, Seguridad y Troubleshooting

Despliegue en Kubernetes (k3s sobre EC2 en AWS) de un backend Python y una base de datos Redis, con hardening de seguridad, sondas de salud y resolución de 3 fallas.

## Estructura
- k8s/00-namespace.yaml: namespace practica-s12
- k8s/01-security-configmap.yaml: configuración y código de la app
- k8s/02-db-secret.yaml: Secret con la contraseña (Base64)
- k8s/03-app-deployment.yaml: Deployments db y backend, y el Service db-service
- k8s/04-app-service.yaml: Service NodePort 30080
- docs/troubleshooting-log.md: bitácora de errores y soluciones

## Despliegue
Ejecutar: kubectl apply -f k8s/

## Acceso
http://IP-PUBLICA-EC2:30080/ (requiere abrir el puerto 30080 en el Security Group).
