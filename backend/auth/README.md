# Luminara Auth Service (Go)

Servicio de autenticación para Luminara.
Responsabilidad en esta fase:
- Conexión a MySQL (db_auth)
- Modelo de Usuario

## Requisitos
- Go instalado
- Docker Desktop
- Base de datos levantada con `docker compose` en la raíz del repo

## Variables de entorno
Por defecto (si no defines nada), el servicio asume:
- DB_HOST=localhost
- DB_PORT=3307
- DB_USER=root
- DB_PASS=rootpassword
- DB_NAME=db_auth
- APP_PORT=8085

Puedes exportarlas (PowerShell):
```powershell
$env:DB_HOST="localhost"
$env:DB_PORT="3307"
$env:DB_USER="root"
$env:DB_PASS="rootpassword"
$env:DB_NAME="db_auth"
$env:APP_PORT="8085"
