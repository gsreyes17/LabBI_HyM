-- Base de datos
USE [master];
GO
IF DB_ID(N'STAGE_HM') IS NULL
    CREATE DATABASE [STAGE_HM];
GO
USE [STAGE_HM];
GO

-- Esquemas
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name=N'SALES')
    EXEC(N'CREATE SCHEMA [SALES]');
GO
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name=N'GENERICO')
    EXEC(N'CREATE SCHEMA [GENERICO]');
GO

-- Reconstrucción de tablas
DROP TABLE IF EXISTS [SALES].[StageTransaction];
DROP TABLE IF EXISTS [SALES].[StageGoalsHyM];
DROP TABLE IF EXISTS [SALES].[StageTemporada];
DROP TABLE IF EXISTS [GENERICO].[StageDimFecha];
DROP TABLE IF EXISTS [SALES].[StageCustomers];
DROP TABLE IF EXISTS [SALES].[StageArticles];
GO

-- Tablas de origen: todos los atributos se reciben como texto
CREATE TABLE [SALES].[StageArticles](
    [article_id]                   NVARCHAR(500) NULL,
    [product_code]                 NVARCHAR(500) NULL,
    [prod_name]                    NVARCHAR(500) NULL,
    [product_type_no]              NVARCHAR(500) NULL,
    [product_type_name]            NVARCHAR(500) NULL,
    [product_group_name]           NVARCHAR(500) NULL,
    [graphical_appearance_no]      NVARCHAR(500) NULL,
    [graphical_appearance_name]    NVARCHAR(500) NULL,
    [colour_group_code]            NVARCHAR(500) NULL,
    [colour_group_name]            NVARCHAR(500) NULL,
    [perceived_colour_value_id]    NVARCHAR(500) NULL,
    [perceived_colour_value_name]  NVARCHAR(500) NULL,
    [perceived_colour_master_id]   NVARCHAR(500) NULL,
    [perceived_colour_master_name] NVARCHAR(500) NULL,
    [department_no]                NVARCHAR(500) NULL,
    [department_name]              NVARCHAR(500) NULL,
    [index_code]                   NVARCHAR(500) NULL,
    [index_name]                   NVARCHAR(500) NULL,
    [index_group_no]               NVARCHAR(500) NULL,
    [index_group_name]             NVARCHAR(500) NULL,
    [section_no]                   NVARCHAR(500) NULL,
    [section_name]                 NVARCHAR(500) NULL,
    [garment_group_no]             NVARCHAR(500) NULL,
    [garment_group_name]           NVARCHAR(500) NULL,
    [detail_desc]                  NVARCHAR(MAX) NULL
);
GO

CREATE TABLE [SALES].[StageCustomers](
    [customer_id]            NVARCHAR(500) NULL,
    [FN]                     NVARCHAR(500) NULL,
    [Active]                 NVARCHAR(500) NULL,
    [club_member_status]     NVARCHAR(500) NULL,
    [fashion_news_frequency] NVARCHAR(500) NULL,
    [age]                    NVARCHAR(500) NULL,
    [postal_code]            NVARCHAR(500) NULL
);
GO

CREATE TABLE [GENERICO].[StageDimFecha](
    [FechaKey]          NVARCHAR(500) NULL,
    [Fecha]             NVARCHAR(500) NULL,
    [Dia_Semana]        NVARCHAR(500) NULL,
    [Nombre_Dia_Semana] NVARCHAR(500) NULL,
    [Dia_Mes]           NVARCHAR(500) NULL,
    [Dia_Anio]          NVARCHAR(500) NULL,
    [Nombre_Mes]        NVARCHAR(500) NULL,
    [Mes_Anio]          NVARCHAR(500) NULL,
    [Semana_Anio]       NVARCHAR(500) NULL,
    [Anio]              NVARCHAR(500) NULL,
    [Bimestre]          NVARCHAR(500) NULL,
    [Trimestre]         NVARCHAR(500) NULL,
    [Cuatrimestre]      NVARCHAR(500) NULL,
    [Semestre]          NVARCHAR(500) NULL,
    [Fin_Semana]        NVARCHAR(500) NULL
);
GO

CREATE TABLE [SALES].[StageTemporada](
    [TemporadaID] NVARCHAR(500) NULL,
    [Temporada]   NVARCHAR(500) NULL,
    [FechaInicio] NVARCHAR(500) NULL,
    [FechaFin]    NVARCHAR(500) NULL
);
GO

CREATE TABLE [SALES].[StageGoalsHyM](
    [Escenario]       NVARCHAR(500) NULL,
    [Monto]           NVARCHAR(500) NULL,
    [department_name] NVARCHAR(500) NULL,
    [section_name]    NVARCHAR(500) NULL,
    [TemporadaID]     NVARCHAR(500) NULL,
    [AnioMes]         NVARCHAR(500) NULL
);
GO

CREATE TABLE [SALES].[StageTransaction](
    [t_dat]            NVARCHAR(500) NULL,
    [customer_id]      NVARCHAR(500) NULL,
    [article_id]       NVARCHAR(500) NULL,
    [price]            NVARCHAR(500) NULL,
    [sales_channel_id] NVARCHAR(500) NULL,
    [TemporadaID]      NVARCHAR(500) NULL
);
GO

-- Indice para leer ventas por fecha
CREATE NONCLUSTERED INDEX IX_StageTransaction_Fecha
ON SALES.StageTransaction(t_dat)
INCLUDE(customer_id,article_id,price,sales_channel_id,TemporadaID)
WITH(MAXDOP=2);
GO
