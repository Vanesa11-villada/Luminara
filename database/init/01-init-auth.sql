-- =========================================================
-- INIT AUTH (db_auth) - Identidad / Roles / Direcciones
-- =========================================================
USE db_auth;

CREATE TABLE rol (
  id     TINYINT UNSIGNED PRIMARY KEY, -- 1=Cliente, 2=Trabajador, 3=Administrador
  nombre VARCHAR(40) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE usuario (
  id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nombre         VARCHAR(120) NOT NULL,
  apellido       VARCHAR(120),
  email          VARCHAR(160) NOT NULL,
  password_hash  VARCHAR(255) NOT NULL,
  rol_id         TINYINT UNSIGNED NOT NULL,
  activo         BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_usuario_email (email),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (rol_id) REFERENCES rol(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_usuario_activo (activo),
  INDEX idx_usuario_rol_activo (rol_id, activo)
) ENGINE=InnoDB;

CREATE TABLE usuario_direccion (
  id                BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  usuario_id        BIGINT UNSIGNED NOT NULL,
  etiqueta          VARCHAR(80),
  direccion         VARCHAR(240) NOT NULL,
  ciudad            VARCHAR(120),
  region            VARCHAR(120),
  pais              VARCHAR(120),
  telefono          VARCHAR(40),
  es_predeterminada BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_ud_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  INDEX idx_ud_usuario (usuario_id, es_predeterminada)
) ENGINE=InnoDB;

-- =========================================================
-- SEMILLAS (AUTH)
-- =========================================================
START TRANSACTION;

INSERT INTO rol (id, nombre) VALUES
 (1,'Cliente'), (2,'Trabajador'), (3,'Administrador')
ON DUPLICATE KEY UPDATE nombre=VALUES(nombre);

-- 🔒 Semilla con IDs explícitos para facilitar snapshot inicial reproducible en Core
INSERT INTO usuario (id, nombre, apellido, email, password_hash, rol_id)
VALUES
 (1,'Ana','García','ana@correo.com','$2a$10$abcdefghijklmnopqrstuv',1),
 (2,'Carlos','Torres','carlos@correo.com','$2a$10$abcdefghijklmnopqrstuv',2),
 (3,'Admin','Root','admin@correo.com','$2a$10$abcdefghijklmnopqrstuv',3)
ON DUPLICATE KEY UPDATE
  nombre=VALUES(nombre),
  apellido=VALUES(apellido),
  rol_id=VALUES(rol_id),
  activo=TRUE;

INSERT INTO usuario_direccion (usuario_id, etiqueta, direccion, ciudad, region, pais, telefono, es_predeterminada)
VALUES
 (1,'casa','Calle 10 #20-30','Bogotá','Cundinamarca','Colombia','3001112233', TRUE)
ON DUPLICATE KEY UPDATE direccion=VALUES(direccion);

COMMIT;

-- Función: Auth queda como fuente de verdad del usuario (incluye password_hash).
