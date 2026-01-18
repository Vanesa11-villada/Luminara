# Diccionario de Datos — Luminara

## Esquemas

### db_auth (Go / Auth)
Contiene identidad y seguridad.
Tablas:
- rol
- usuario
- usuario_direccion

**Source of truth del usuario**.

### db_core (Java / Core)
Contiene negocio y operación.
Incluye:
- catálogo (aroma, forma, tamano)
- producto, producto_imagen
- insumo, proveedor, inventario_mov, insumo_proveedor
- receta, receta_item
- pedido, pedido_item, pedido_reserva_insumo
- factura, factura_item
- fidelizacion_cuenta, fidelizacion_mov
- anuncio
- vistas, triggers, procedimientos

## Relación Usuario ↔ Pedido (Trazabilidad)

- db_auth.usuario.id = identificador global del usuario.
- db_core.usuario_snapshot.usuario_id = proyección local para operar.
- db_core.pedido.usuario_id referencia a usuario_snapshot.

### Diagrama lógico

db_auth.usuario (source of truth)
        |
        | (sincronización / snapshot)
        v
db_core.usuario_snapshot
        |
        v
db_core.pedido

## Regla de arquitectura

- No hay FK entre db_auth y db_core.
- Core no contiene credenciales.
- Core opera sin depender runtime de Auth.
