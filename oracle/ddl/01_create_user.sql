-- ============================================================
-- Mini BOP - Fase 1
-- Script 01 - Create User / Schema
-- Execute como SYS, SYSTEM ou usuário DBA.
-- Ajuste a senha conforme sua preferência.
-- ============================================================

ALTER SESSION SET CONTAINER = XEPDB1;

CREATE USER mini_bop IDENTIFIED BY mini_bop
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp
  QUOTA UNLIMITED ON users;

GRANT CREATE SESSION TO mini_bop;
GRANT CREATE TABLE TO mini_bop;
GRANT CREATE VIEW TO mini_bop;
GRANT CREATE SEQUENCE TO mini_bop;
GRANT CREATE PROCEDURE TO mini_bop;
GRANT CREATE TRIGGER TO mini_bop;
GRANT CREATE JOB TO mini_bop;

-- Para laboratório local. Em ambiente real, evitar privilégios amplos.
GRANT UNLIMITED TABLESPACE TO mini_bop;

PROMPT User MINI_BOP created successfully.
