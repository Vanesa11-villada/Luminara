# Diccionario de Datos — Luminara (Fase 1)

## Visión general
Luminara separa la persistencia en dos esquemas:
- **db_auth**: identidad y seguridad (servicio Go)
- **db_core**: negocio y operación (servicio Java)

No existen claves foráneas entre esquemas. La relación usuario–pedido se garantiza en Core mediante la proyección **usuario_snapshot**.

---

## Esquema: db_auth (Auth / Go)

### rol
Catálogo de roles del sistema.
- **PK:** id
- **Único:** nombre

Relación:
- `usuario.rol_id -> rol.id`

### usuario
Fuente de verdad del usuario (incluye credenciales).
- **PK:** id
- **Único:** email
- Campos clave: nombre, apellido, email, password_hash, rol_id, activo

Relaciones:
- `usuario.rol_id -> rol.id`
- `usuario_direccion.usuario_id -> usuario.id`

### usuario_direccion
Direcciones del usuario (envíos).
- **PK:** id
- **FK:** usuario_id -> usuario.id

---

## Esquema: db_core (Core / Java)

### usuario_snapshot
Proyección local del usuario necesaria para operar sin dependencia runtime de Auth.
- **PK:** usuario_id
- **Único:** email (opcional según implementación)
- Campos clave: nombre, email, rol_id, activo, ciudad/país, actualizado_en

Origen:
- Sincronizado desde `db_auth.usuario` (en init) y en fases futuras por eventos/endpoint interno.

### pedido
Representa el ciclo de vida del pedido.
- **PK:** id
- **Único:** numero
- **FK local:** `pedido.usuario_id -> usuario_snapshot.usuario_id` (si no es invitado)

Regla:
- En Core no existe FK hacia `db_auth.usuario`. La trazabilidad se mantiene por snapshot.

---

## Relación lógica Usuario ↔ Pedido (Trazabilidad)

**Source of truth:**
- `db_auth.usuario.id` es el identificador global del usuario.

**Proyección en Core:**
- `db_core.usuario_snapshot.usuario_id` replica el mismo id.

**Uso en negocio:**
- `db_core.pedido.usuario_id` referencia `usuario_snapshot`.

Flujo conceptual:
db_auth.usuario  → (sincronización) →  db_core.usuario_snapshot  →  db_core.pedido

---

## Decisión arquitectónica
Se usa `usuario_snapshot` para:
- evitar FK cross-schema (no soportadas)
- evitar dependencia runtime de Auth
- mantener integridad y reportes en Core
