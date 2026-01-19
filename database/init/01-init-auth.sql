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
  documento_tipo   ENUM('CC','TI','CE','NIT','PAS') NOT NULL DEFAULT 'CC',
  documento_numero VARCHAR(20) NOT NULL,
  UNIQUE KEY uq_usuario_documento (documento_tipo, documento_numero),
  password_hash  VARCHAR(255) NOT NULL,
  rol_id         TINYINT UNSIGNED NOT NULL,
  activo         BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_login_at   DATETIME NULL,
  inactivated_at  DATETIME NULL,
  inactivated_reason VARCHAR(80) NULL,
  UNIQUE KEY uq_usuario_email (email),
  UNIQUE KEY uq_usuario_documento (documento_tipo, documento_numero),
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

-- ============================================================================
-- TOKENS DE SESIÓN (REFRESH) - para renovar access tokens sin re-login
-- ============================================================================
CREATE TABLE refresh_token (
  id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL, -- SHA-256 en hex
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_refresh_user FOREIGN KEY (usuario_id) REFERENCES usuario(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE KEY uq_refresh_token_hash (token_hash),
  INDEX idx_refresh_user (usuario_id),
  INDEX idx_refresh_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TOKENS DE RESET PASSWORD - un solo uso, expiración corta
-- ============================================================================
CREATE TABLE password_reset_token (
  id         BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL, -- SHA-256 en hex
  expires_at DATETIME NOT NULL,
  used_at    DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reset_user FOREIGN KEY (usuario_id) REFERENCES usuario(id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE KEY uq_reset_token_hash (token_hash),
  INDEX idx_reset_user (usuario_id),
  INDEX idx_reset_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- SEMILLAS (AUTH)
-- =========================================================
START TRANSACTION;

INSERT INTO usuario_direccion (usuario_id, etiqueta, direccion, ciudad, region, pais, telefono, es_predeterminada)
SELECT id, 'casa',
       'Cra 70 # 44-20 (Barrio: Laureles - Estadio)',
       'Medellín','Antioquia','Colombia','3001234567', TRUE
FROM usuario
WHERE documento_tipo='CC' AND documento_numero='1035123456'
ON DUPLICATE KEY UPDATE direccion=VALUES(direccion), ciudad=VALUES(ciudad), region=VALUES(region), pais=VALUES(pais), telefono=VALUES(telefono), es_predeterminada=VALUES(es_predeterminada);

INSERT INTO usuario_direccion (usuario_id, etiqueta, direccion, ciudad, region, pais, telefono, es_predeterminada)
SELECT id, 'casa',
       'Calle 50 # 45-12 (Barrio: El Centro)',
       'Bello','Antioquia','Colombia','3012345678', TRUE
FROM usuario
WHERE documento_tipo='CC' AND documento_numero='1017123456'
ON DUPLICATE KEY UPDATE direccion=VALUES(direccion), ciudad=VALUES(ciudad), region=VALUES(region), pais=VALUES(pais), telefono=VALUES(telefono), es_predeterminada=VALUES(es_predeterminada);

INSERT INTO usuario_direccion (usuario_id, etiqueta, direccion, ciudad, region, pais, telefono, es_predeterminada)
SELECT id, 'casa',
       'Calle 65 # 78-10 (Barrio: Robledo)',
       'Medellín','Antioquia','Colombia','3105556677', TRUE
FROM usuario
WHERE documento_tipo='CC' AND documento_numero='1000123456'
ON DUPLICATE KEY UPDATE direccion=VALUES(direccion), ciudad=VALUES(ciudad), region=VALUES(region), pais=VALUES(pais), telefono=VALUES(telefono), es_predeterminada=VALUES(es_predeterminada);

INSERT INTO usuario_direccion (usuario_id, etiqueta, direccion, ciudad, region, pais, telefono, es_predeterminada)
SELECT id, 'casa',
       'Cra 43A # 1A Sur-29 (Barrio: El Poblado)',
       'Medellín','Antioquia','Colombia','3112223344', TRUE
FROM usuario
WHERE documento_tipo='CC' AND documento_numero='1098123456'
ON DUPLICATE KEY UPDATE direccion=VALUES(direccion), ciudad=VALUES(ciudad), region=VALUES(region), pais=VALUES(pais), telefono=VALUES(telefono), es_predeterminada=VALUES(es_predeterminada);

INSERT INTO usuario_direccion (usuario_id, etiqueta, direccion, ciudad, region, pais, telefono, es_predeterminada)
SELECT id, 'trabajo',
       'Cra 48 # 20-55 (Barrio: Manila - El Poblado)',
       'Medellín','Antioquia','Colombia','3128889900', TRUE
FROM usuario
WHERE documento_tipo='CC' AND documento_numero='1022123456'
ON DUPLICATE KEY UPDATE direccion=VALUES(direccion), ciudad=VALUES(ciudad), region=VALUES(region), pais=VALUES(pais), telefono=VALUES(telefono), es_predeterminada=VALUES(es_predeterminada);

INSERT INTO usuario_direccion (usuario_id, etiqueta, direccion, ciudad, region, pais, telefono, es_predeterminada)
SELECT id, 'casa',
       'Diagonal 55 # 38-90 (Barrio: Niquía)',
       'Bello','Antioquia','Colombia','3134445566', TRUE
FROM usuario
WHERE documento_tipo='CC' AND documento_numero='1031123456'
ON DUPLICATE KEY UPDATE direccion=VALUES(direccion), ciudad=VALUES(ciudad), region=VALUES(region), pais=VALUES(pais), telefono=VALUES(telefono), es_predeterminada=VALUES(es_predeterminada);

COMMIT;

-- Función: Auth queda como fuente de verdad del usuario (incluye password_hash).
