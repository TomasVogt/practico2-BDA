-- =====================================================================
-- Data Mart: Ventas de BMW (2010-2024)
-- Paso 3 - HEFESTO - Modelo Lógico (Esquema en Estrella)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS dw_bmw_ventas
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE dw_bmw_ventas;

-- ---------------------------------------------------------------------
-- Tablas de Dimensiones
-- ---------------------------------------------------------------------

CREATE TABLE Dim_Tiempo (
    id_tiempo   INT AUTO_INCREMENT PRIMARY KEY,
    anio        SMALLINT NOT NULL,
    CONSTRAINT uq_dim_tiempo_anio UNIQUE (anio)
) ENGINE = InnoDB;

CREATE TABLE Dim_Producto (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    modelo      VARCHAR(50) NOT NULL,
    CONSTRAINT uq_dim_producto_modelo UNIQUE (modelo)
) ENGINE = InnoDB;

CREATE TABLE Dim_Region (
    id_region      INT AUTO_INCREMENT PRIMARY KEY,
    nombre_region  VARCHAR(50) NOT NULL,
    CONSTRAINT uq_dim_region_nombre UNIQUE (nombre_region)
) ENGINE = InnoDB;

CREATE TABLE Dim_Combustible (
    id_combustible    INT AUTO_INCREMENT PRIMARY KEY,
    tipo_combustible  VARCHAR(30) NOT NULL,
    CONSTRAINT uq_dim_combustible_tipo UNIQUE (tipo_combustible)
) ENGINE = InnoDB;

CREATE TABLE Dim_Color (
    id_color      INT AUTO_INCREMENT PRIMARY KEY,
    nombre_color  VARCHAR(30) NOT NULL,
    CONSTRAINT uq_dim_color_nombre UNIQUE (nombre_color)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Tabla de Hechos
-- ---------------------------------------------------------------------

CREATE TABLE Hecho_Ventas (
    id_tiempo       INT NOT NULL,
    id_producto     INT NOT NULL,
    id_region       INT NOT NULL,
    id_combustible  INT NOT NULL,
    id_color        INT NOT NULL,
    volumen_ventas  INT NOT NULL,
    precio_usd      DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (id_tiempo, id_producto, id_region, id_combustible, id_color),

    CONSTRAINT fk_hv_tiempo
        FOREIGN KEY (id_tiempo) REFERENCES Dim_Tiempo (id_tiempo),
    CONSTRAINT fk_hv_producto
        FOREIGN KEY (id_producto) REFERENCES Dim_Producto (id_producto),
    CONSTRAINT fk_hv_region
        FOREIGN KEY (id_region) REFERENCES Dim_Region (id_region),
    CONSTRAINT fk_hv_combustible
        FOREIGN KEY (id_combustible) REFERENCES Dim_Combustible (id_combustible),
    CONSTRAINT fk_hv_color
        FOREIGN KEY (id_color) REFERENCES Dim_Color (id_color)
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Índices adicionales sobre la tabla de hechos
-- (útiles para consultas de BI que filtran o agrupan por una sola
-- dimensión sin recorrer toda la clave compuesta)
-- ---------------------------------------------------------------------

CREATE INDEX idx_hv_tiempo       ON Hecho_Ventas (id_tiempo);
CREATE INDEX idx_hv_producto     ON Hecho_Ventas (id_producto);
CREATE INDEX idx_hv_region       ON Hecho_Ventas (id_region);
CREATE INDEX idx_hv_combustible  ON Hecho_Ventas (id_combustible);
CREATE INDEX idx_hv_color        ON Hecho_Ventas (id_color);
