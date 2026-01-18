-- =========================================================
-- INIT CORE (db_core) - Negocio / Pedidos / Inventario
-- =========================================================
USE db_core;

-- =========================================================
-- PROYECCIÓN DE USUARIO (SNAPSHOT) DESDE AUTH
-- =========================================================
CREATE TABLE usuario_snapshot (
  usuario_id BIGINT UNSIGNED PRIMARY KEY,
  nombre     VARCHAR(120) NOT NULL,
  apellido   VARCHAR(120),
  email      VARCHAR(160) NOT NULL,
  rol_id     TINYINT UNSIGNED NOT NULL,
  activo     BOOLEAN NOT NULL,
  telefono   VARCHAR(40),
  ciudad     VARCHAR(120),
  region     VARCHAR(120),
  pais       VARCHAR(120),
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_usnap_email (email),
  INDEX idx_usnap_rol_activo (rol_id, activo)
) ENGINE=InnoDB;

-- Carga inicial del snapshot desde db_auth (sin FK cross-db)
INSERT INTO usuario_snapshot (usuario_id, nombre, apellido, email, rol_id, activo, telefono, ciudad, region, pais)
SELECT
  u.id,
  u.nombre,
  u.apellido,
  u.email,
  u.rol_id,
  u.activo,
  ud.telefono,
  ud.ciudad,
  ud.region,
  ud.pais
FROM db_auth.usuario u
LEFT JOIN db_auth.usuario_direccion ud
  ON ud.usuario_id = u.id AND ud.es_predeterminada = TRUE
ON DUPLICATE KEY UPDATE
  nombre=VALUES(nombre),
  apellido=VALUES(apellido),
  rol_id=VALUES(rol_id),
  activo=VALUES(activo),
  telefono=VALUES(telefono),
  ciudad=VALUES(ciudad),
  region=VALUES(region),
  pais=VALUES(pais);

-- =========================================================
-- 1) CATÁLOGOS
-- =========================================================
CREATE TABLE aroma (
  id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE forma (
  id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE tamano (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre      VARCHAR(60) NOT NULL UNIQUE,
  descripcion VARCHAR(120)
) ENGINE=InnoDB;

-- =========================================================
-- 2) PRODUCTOS Y GALERÍA
-- =========================================================
CREATE TABLE producto (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre         VARCHAR(160) NOT NULL,
  descripcion    TEXT,
  precio         DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
  aroma_id       BIGINT UNSIGNED,
  forma_id       BIGINT UNSIGNED,
  tamano_id      BIGINT UNSIGNED,
  activo         BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_producto_aroma  FOREIGN KEY (aroma_id)  REFERENCES aroma(id)  ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_producto_forma  FOREIGN KEY (forma_id)  REFERENCES forma(id)  ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_producto_tamano FOREIGN KEY (tamano_id) REFERENCES tamano(id) ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_producto_activo (activo),
  INDEX idx_producto_busqueda (nombre),
  INDEX idx_producto_filtros (aroma_id, forma_id, tamano_id),
  INDEX idx_producto_precio (precio)
) ENGINE=InnoDB;

CREATE TABLE producto_imagen (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  producto_id  BIGINT UNSIGNED NOT NULL,
  url          VARCHAR(400) NOT NULL,
  texto_alt    VARCHAR(160),
  orden        INT UNSIGNED NOT NULL DEFAULT 1,
  CONSTRAINT fk_img_producto FOREIGN KEY (producto_id) REFERENCES producto(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_img_producto (producto_id, orden)
) ENGINE=InnoDB;

-- =========================================================
-- 3) INSUMOS/PROVEEDORES/INVENTARIO
-- =========================================================
CREATE TABLE insumo (
  id               BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre           VARCHAR(120) NOT NULL UNIQUE,
  unidad           VARCHAR(32)  NOT NULL,
  stock_disponible DECIMAL(12,3) NOT NULL DEFAULT 0 CHECK (stock_disponible >= 0),
  stock_minimo     DECIMAL(12,3) NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
  creado_en        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_insumo_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE proveedor (
  id        BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre    VARCHAR(160) NOT NULL,
  email     VARCHAR(160),
  telefono  VARCHAR(40),
  direccion VARCHAR(240),
  activo    BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE KEY uq_proveedor_email (email)
) ENGINE=InnoDB;

CREATE TABLE insumo_proveedor (
  insumo_id      BIGINT UNSIGNED NOT NULL,
  proveedor_id   BIGINT UNSIGNED NOT NULL,
  costo_unitario DECIMAL(10,2),
  PRIMARY KEY (insumo_id, proveedor_id),
  CONSTRAINT fk_insprov_ins FOREIGN KEY (insumo_id) REFERENCES insumo(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_insprov_prov FOREIGN KEY (proveedor_id) REFERENCES proveedor(id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE inventario_mov (
  id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  insumo_id  BIGINT UNSIGNED NOT NULL,
  tipo       ENUM('RESERVA','CONSUMO','AJUSTE_POS','AJUSTE_NEG','COMPRA') NOT NULL,
  cantidad   DECIMAL(12,3) NOT NULL CHECK (cantidad > 0),
  referencia VARCHAR(80),
  creado_en  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_invmov_ins FOREIGN KEY (insumo_id) REFERENCES insumo(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_invmov_insumo_fecha (insumo_id, creado_en),
  INDEX idx_invmov_tipo (tipo)
) ENGINE=InnoDB;

-- =========================================================
-- 4) RECETAS (BOM)
-- =========================================================
CREATE TABLE receta (
  id          BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  producto_id BIGINT UNSIGNED NOT NULL,
  version     INT UNSIGNED NOT NULL DEFAULT 1,
  activa      BOOLEAN NOT NULL DEFAULT TRUE,
  notas       VARCHAR(240),
  creado_en   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_receta_producto_version (producto_id, version),
  CONSTRAINT fk_receta_producto FOREIGN KEY (producto_id) REFERENCES producto(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_receta_activa (producto_id, activa)
) ENGINE=InnoDB;

CREATE TABLE receta_item (
  receta_id BIGINT UNSIGNED NOT NULL,
  insumo_id BIGINT UNSIGNED NOT NULL,
  cantidad  DECIMAL(12,3) NOT NULL CHECK (cantidad > 0),
  PRIMARY KEY (receta_id, insumo_id),
  CONSTRAINT fk_recitem_receta FOREIGN KEY (receta_id) REFERENCES receta(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_recitem_insumo FOREIGN KEY (insumo_id) REFERENCES insumo(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================================================
-- 6) PEDIDOS / DETALLE / RESERVAS / FACTURACIÓN
-- (usuario_id y anulado_por ahora referencian usuario_snapshot)
-- =========================================================
CREATE TABLE pedido (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  numero            VARCHAR(40) NOT NULL UNIQUE,
  usuario_id        BIGINT UNSIGNED NULL,          -- NULL si invitado
  receta_id         BIGINT UNSIGNED NULL,
  invitado_nombre   VARCHAR(120),
  invitado_apellido VARCHAR(120),
  invitado_email    VARCHAR(160),
  invitado_telefono VARCHAR(40),
  envio_direccion   VARCHAR(240) NOT NULL,
  envio_ciudad      VARCHAR(120),
  envio_region      VARCHAR(120),
  envio_pais        VARCHAR(120),
  estado            ENUM('Borrador','En producción','Listo','Pendiente de entrega','Entregado','Anulado')
                   NOT NULL DEFAULT 'Borrador',
  anulado           BOOLEAN NOT NULL DEFAULT FALSE,
  motivo_anulacion  VARCHAR(240),
  anulado_en        DATETIME NULL,
  anulado_por       BIGINT UNSIGNED NULL,          -- usuario lógico (snapshot)
  subtotal          DECIMAL(12,2) NOT NULL DEFAULT 0,
  total             DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_neto        DECIMAL(12,2) NOT NULL DEFAULT 0,
  puntos_ganados    INT NOT NULL DEFAULT 0,
  puntos_redimidos  INT NOT NULL DEFAULT 0,
  creado_en         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_pedido_usuario_snap FOREIGN KEY (usuario_id) REFERENCES usuario_snapshot(usuario_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_pedido_receta FOREIGN KEY (receta_id) REFERENCES receta(id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_pedido_anul_por_snap FOREIGN KEY (anulado_por) REFERENCES usuario_snapshot(usuario_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_pedido_estado (estado),
  INDEX idx_pedido_fechas (creado_en),
  INDEX idx_pedido_usuario (usuario_id)
) ENGINE=InnoDB;

CREATE TABLE pedido_item (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  pedido_id    BIGINT UNSIGNED NOT NULL,
  producto_id  BIGINT UNSIGNED NOT NULL,
  cantidad     INT UNSIGNED NOT NULL CHECK (cantidad > 0),
  precio_unit  DECIMAL(10,2) NOT NULL CHECK (precio_unit >= 0),
  total_linea  DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_pitem_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_pitem_producto FOREIGN KEY (producto_id) REFERENCES producto(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_pitem_pedido (pedido_id),
  INDEX idx_pitem_producto (producto_id)
) ENGINE=InnoDB;

CREATE TABLE pedido_reserva_insumo (
  pedido_id BIGINT UNSIGNED NOT NULL,
  insumo_id BIGINT UNSIGNED NOT NULL,
  cantidad  DECIMAL(12,3) NOT NULL CHECK (cantidad > 0),
  PRIMARY KEY (pedido_id, insumo_id),
  CONSTRAINT fk_preserva_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_preserva_insumo FOREIGN KEY (insumo_id) REFERENCES insumo(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE factura (
  id              BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  numero          VARCHAR(40) NOT NULL UNIQUE,
  pedido_id       BIGINT UNSIGNED NOT NULL,
  fecha_emision   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  subtotal        DECIMAL(12,2) NOT NULL,
  total           DECIMAL(12,2) NOT NULL,
  anulada         BOOLEAN NOT NULL DEFAULT FALSE,
  cliente_nombre  VARCHAR(160) NOT NULL,
  cliente_email   VARCHAR(160) NOT NULL,
  envio_direccion VARCHAR(240) NOT NULL,
  CONSTRAINT fk_factura_pedido FOREIGN KEY (pedido_id) REFERENCES pedido(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_factura_fecha (fecha_emision)
) ENGINE=InnoDB;

CREATE TABLE factura_item (
  id           BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  factura_id   BIGINT UNSIGNED NOT NULL,
  producto_id  BIGINT UNSIGNED NOT NULL,
  descripcion  VARCHAR(200) NOT NULL,
  cantidad     INT UNSIGNED NOT NULL CHECK (cantidad > 0),
  precio_unit  DECIMAL(10,2) NOT NULL CHECK (precio_unit >= 0),
  total_linea  DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_fitem_factura FOREIGN KEY (factura_id) REFERENCES factura(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_fitem_producto FOREIGN KEY (producto_id) REFERENCES producto(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_fitem_factura (factura_id),
  INDEX idx_fitem_producto (producto_id)
) ENGINE=InnoDB;

-- =========================================================
-- 7) FIDELIZACIÓN Y ANUNCIOS (usan snapshot, NO auth)
-- =========================================================
CREATE TABLE fidelizacion_cuenta (
  usuario_id     BIGINT UNSIGNED PRIMARY KEY,
  puntos_saldo   INT NOT NULL DEFAULT 0,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_fid_cta_user_snap FOREIGN KEY (usuario_id) REFERENCES usuario_snapshot(usuario_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE fidelizacion_mov (
  id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  tipo       ENUM('GANADO','REDIMIDO','AJUSTE_POS','AJUSTE_NEG') NOT NULL,
  puntos     INT NOT NULL,
  referencia VARCHAR(80),
  creado_en  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_fid_mov_user_snap FOREIGN KEY (usuario_id) REFERENCES usuario_snapshot(usuario_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_fid_mov_user_fecha (usuario_id, creado_en),
  INDEX idx_fid_mov_tipo (tipo)
) ENGINE=InnoDB;

CREATE TABLE anuncio (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  titulo         VARCHAR(120) NOT NULL,
  contenido      TEXT NOT NULL,
  ubicacion      ENUM('HOME','CATALOGO','LOGIN','GLOBAL') NOT NULL DEFAULT 'GLOBAL',
  visible        BOOLEAN NOT NULL DEFAULT TRUE,
  inicia_en      DATETIME NULL,
  finaliza_en    DATETIME NULL,
  creado_por     BIGINT UNSIGNED NULL, -- snapshot
  creado_en      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_anuncio_admin_snap FOREIGN KEY (creado_por) REFERENCES usuario_snapshot(usuario_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_anuncio_visibilidad (visible, ubicacion),
  INDEX idx_anuncio_vigencia (inicia_en, finaliza_en)
) ENGINE=InnoDB;

-- =========================================================
-- 8) VISTAS / TRIGGERS / PROCEDIMIENTOS
-- (sin cambios de lógica; todo opera dentro de db_core)
-- =========================================================
CREATE OR REPLACE VIEW v_insumo_disponible AS
SELECT i.id,
       i.nombre,
       i.unidad,
       i.stock_disponible
         - COALESCE((
             SELECT SUM(pri.cantidad)
             FROM pedido_reserva_insumo pri
             JOIN pedido p ON p.id = pri.pedido_id
             WHERE pri.insumo_id = i.id
               AND p.estado IN ('En producción','Listo','Pendiente de entrega')
           ), 0) AS stock_disponible_real,
       i.stock_minimo
FROM insumo i;

CREATE OR REPLACE VIEW v_pedidos_activos AS
SELECT *
FROM pedido
WHERE anulado = FALSE AND estado <> 'Anulado';

DROP TRIGGER IF EXISTS trg_insumo_no_negativo;
DELIMITER $$
CREATE TRIGGER trg_insumo_no_negativo
BEFORE UPDATE ON insumo
FOR EACH ROW
BEGIN
  IF NEW.stock_disponible < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock no puede ser negativo';
  END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_pedido_no_delete;
DELIMITER $$
CREATE TRIGGER trg_pedido_no_delete
BEFORE DELETE ON pedido
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No se permite eliminar pedidos. Use sp_anular_pedido.';
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_anular_pedido;
DELIMITER $$
CREATE PROCEDURE sp_anular_pedido(
  IN p_numero  VARCHAR(40),
  IN p_usuario BIGINT UNSIGNED,
  IN p_motivo  VARCHAR(240)
)
BEGIN
  DECLARE v_pedido_id BIGINT UNSIGNED;
  DECLARE v_estado    VARCHAR(30);
  DECLARE v_receta_id BIGINT UNSIGNED;

  SELECT id, estado, receta_id
    INTO v_pedido_id, v_estado, v_receta_id
  FROM pedido
  WHERE numero = p_numero
  LIMIT 1;

  IF v_pedido_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido no existe';
  END IF;

  IF (SELECT anulado FROM pedido WHERE id = v_pedido_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido ya estaba anulado';
  END IF;

  IF v_estado IN ('Listo','Pendiente de entrega','Entregado') THEN
    INSERT INTO inventario_mov (insumo_id, tipo, cantidad, referencia)
    SELECT pri.insumo_id, 'AJUSTE_POS', pri.cantidad, p_numero
    FROM pedido_reserva_insumo pri
    WHERE pri.pedido_id = v_pedido_id;

    UPDATE insumo i
    JOIN (
      SELECT insumo_id, SUM(cantidad) AS qty
      FROM pedido_reserva_insumo
      WHERE pedido_id = v_pedido_id
      GROUP BY insumo_id
    ) x ON x.insumo_id = i.id
    SET i.stock_disponible = i.stock_disponible + x.qty;
  END IF;

  DELETE FROM pedido_reserva_insumo WHERE pedido_id = v_pedido_id;

  UPDATE pedido
  SET estado = 'Anulado',
      anulado = TRUE,
      motivo_anulacion = p_motivo,
      anulado_en = NOW(),
      anulado_por = p_usuario
  WHERE id = v_pedido_id;

  UPDATE factura SET anulada = TRUE WHERE pedido_id = v_pedido_id;
END$$
DELIMITER ;

-- =========================================================
-- 9) ÍNDICES DASHBOARD
-- =========================================================
CREATE INDEX idx_dashboard_ventas ON pedido (estado, creado_en);
CREATE INDEX idx_dashboard_productos_mas_vendidos ON pedido_item (producto_id, cantidad);

-- =========================================================
-- 10) SEMILLAS (CORE)
-- =========================================================
START TRANSACTION;

INSERT INTO aroma (nombre) VALUES ('Lavanda'),('Vainilla'),('Cítricos')
ON DUPLICATE KEY UPDATE nombre=VALUES(nombre);

INSERT INTO forma (nombre) VALUES ('Cilíndrica'),('Corazón'),('Esfera')
ON DUPLICATE KEY UPDATE nombre=VALUES(nombre);

INSERT INTO tamano (nombre, descripcion) VALUES
 ('Pequeña','100g'),('Mediana','200g'),('Grande','300g')
ON DUPLICATE KEY UPDATE descripcion=VALUES(descripcion);

INSERT INTO insumo (nombre, unidad, stock_disponible, stock_minimo)
VALUES ('Cera de soja','g',5000,500),('Pabilo #2','unidad',200,20),('Esencia Lavanda','ml',1000,100)
ON DUPLICATE KEY UPDATE stock_disponible=VALUES(stock_disponible);

INSERT INTO proveedor (nombre, email, telefono, direccion)
VALUES ('Proveedora S.A.S','contacto@proveedora.com','3010000000','Cra 50 # 70-20')
ON DUPLICATE KEY UPDATE telefono=VALUES(telefono);

INSERT INTO insumo_proveedor (insumo_id, proveedor_id, costo_unitario)
SELECT i.id, p.id, 10.00
FROM insumo i, proveedor p
WHERE i.nombre='Cera de soja' AND p.nombre='Proveedora S.A.S'
ON DUPLICATE KEY UPDATE costo_unitario=VALUES(costo_unitario);

INSERT INTO producto (nombre, descripcion, precio, aroma_id, forma_id, tamano_id)
SELECT 'Vela Romántica','Vela de cera de soja con aroma a lavanda', 25.00,
       (SELECT id FROM aroma  WHERE nombre='Lavanda'),
       (SELECT id FROM forma  WHERE nombre='Corazón'),
       (SELECT id FROM tamano WHERE nombre='Mediana')
ON DUPLICATE KEY UPDATE precio=VALUES(precio);

INSERT INTO producto_imagen (producto_id, url, texto_alt, orden)
SELECT p.id, 'https://ejemplo.com/img/vela-romantica-1.jpg','Vela Romántica 1',1
FROM producto p WHERE p.nombre='Vela Romántica'
ON DUPLICATE KEY UPDATE texto_alt=VALUES(texto_alt);

INSERT INTO receta (producto_id, version, activa, notas)
SELECT p.id, 1, TRUE, 'Receta base v1'
FROM producto p WHERE p.nombre='Vela Romántica'
ON DUPLICATE KEY UPDATE notas=VALUES(notas);

INSERT INTO receta_item (receta_id, insumo_id, cantidad)
SELECT r.id, i.id, CASE i.nombre
  WHEN 'Cera de soja'    THEN 200.0
  WHEN 'Pabilo #2'       THEN 1.0
  WHEN 'Esencia Lavanda' THEN 10.0
  ELSE 0 END
FROM receta r
JOIN producto p ON p.id=r.producto_id AND p.nombre='Vela Romántica'
JOIN insumo i ON i.nombre IN ('Cera de soja','Pabilo #2','Esencia Lavanda')
ON DUPLICATE KEY UPDATE cantidad=VALUES(cantidad);

-- Fidelización para Ana (usuario_id=1 proviene de auth seed y ya está en snapshot)
INSERT INTO fidelizacion_cuenta (usuario_id, puntos_saldo)
VALUES (1, 0)
ON DUPLICATE KEY UPDATE puntos_saldo=puntos_saldo;

-- Anuncio demo creado por Admin (usuario_id=3 en snapshot)
INSERT INTO anuncio (titulo, contenido, ubicacion, visible, creado_por)
VALUES ('Bienvenidos a Luminara','Envíos gratis por compras > $100.000','HOME',TRUE, 3);

COMMIT;
