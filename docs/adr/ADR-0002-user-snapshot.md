# ADR-0002 – Usuario Snapshot en Core

## Decisión
Core mantiene una proyección del usuario (`usuario_snapshot`)
para operar sin dependencia runtime de Auth.

## Motivación
- Evitar FK cross-database
- Eliminar latencia
- Permitir operación autónoma

## Consecuencias
- Consistencia eventual
- Mayor resiliencia
- Base preparada para eventos
