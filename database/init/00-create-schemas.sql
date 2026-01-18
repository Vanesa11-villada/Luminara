-- =========================================================
-- CREACIÓN DE ESQUEMAS (AUTH + CORE)
-- =========================================================
SET NAMES utf8mb4;
SET time_zone = '+00:00';

DROP DATABASE IF EXISTS db_auth;
CREATE DATABASE db_auth
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

DROP DATABASE IF EXISTS db_core;
CREATE DATABASE db_core
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Función: crear las 2 bases y fijar configuración global (charset/timezone).
-- No crea tablas.