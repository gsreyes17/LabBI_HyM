-- Base de datos
USE [master];
GO
IF DB_ID(N'DWH_HM') IS NULL
    CREATE DATABASE [DWH_HM];
GO
USE [DWH_HM];
GO

-- Esquemas
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name=N'Sales')
    EXEC(N'CREATE SCHEMA [Sales]');
GO
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name=N'GENERICO')
    EXEC(N'CREATE SCHEMA [GENERICO]');
GO
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name=N'ERROR')
    EXEC(N'CREATE SCHEMA [ERROR]');
GO

-- Reconstrucción de tablas
DROP TABLE IF EXISTS [Sales].[FactSales];
DROP TABLE IF EXISTS [ERROR].[ErrorFactSales];
DROP TABLE IF EXISTS [Sales].[DimSalesChannel];
DROP TABLE IF EXISTS [Sales].[DimTemporada];
DROP TABLE IF EXISTS [Sales].[DimArticle];
DROP TABLE IF EXISTS [Sales].[DimCustomer];
DROP TABLE IF EXISTS [GENERICO].[DimFecha];
DROP TABLE IF EXISTS [dbo].[DIM_AUDIT];
GO

-- Auditoría
CREATE TABLE [dbo].[DIM_AUDIT](
    [AuditKey]                [int] IDENTITY(1,1) NOT NULL,
    [TableName]               [nvarchar](100) NULL DEFAULT ('Unknown'),
    [PkgName]                 [nvarchar](50) NOT NULL DEFAULT ('Unknown'),
    [PkgGUID]                 [uniqueidentifier] NULL,
    [ExecStartDT]             [datetime] NOT NULL DEFAULT (GETDATE()),
    [ExecStopDT]              [datetime] NULL,
    [ExecutionInstanceGUID]   [uniqueidentifier] NULL,
    [ExtractRowCnt]           [bigint] NULL,
    [TableInitialRowCnt]      [bigint] NULL,
    [TableFinalRowCnt]        [bigint] NULL,
    [SuccessfulProcessingInd] [nchar](1) NOT NULL DEFAULT ('N'),
    CONSTRAINT [PK_DIM_AUDIT] PRIMARY KEY CLUSTERED ([AuditKey] ASC)
);
GO

-- Tablas de dimensiones
CREATE TABLE [GENERICO].[DimFecha](
    [FechaKey]          [int] NOT NULL,
    [Fecha]             [date] NOT NULL,
    [Dia_Semana]        [tinyint] NOT NULL,
    [Nombre_Dia_Semana] [nvarchar](20) NOT NULL,
    [Dia_Mes]           [tinyint] NOT NULL,
    [Dia_Anio]          [smallint] NOT NULL,
    [Nombre_Mes]        [nvarchar](20) NOT NULL,
    [Mes_Anio]          [tinyint] NOT NULL,
    [Semana_Anio]       [tinyint] NOT NULL,
    [Anio]              [smallint] NOT NULL,
    [Bimestre]          [tinyint] NOT NULL,
    [Trimestre]         [tinyint] NOT NULL,
    [Cuatrimestre]      [tinyint] NOT NULL,
    [Semestre]          [tinyint] NOT NULL,
    [Fin_Semana]        [tinyint] NOT NULL,
    CONSTRAINT [PK_DimFecha] PRIMARY KEY CLUSTERED ([FechaKey] ASC)
);
GO

CREATE TABLE [Sales].[DimCustomer](
    [CustomerKey]          [int] IDENTITY(1,1) NOT NULL,
    [CustomerID]           [varchar](100) NOT NULL,
    [FN]                   [float] NULL,
    [Active]               [float] NULL,
    [ClubMemberStatus]     [varchar](50) NOT NULL,
    [FashionNewsFrequency] [varchar](50) NOT NULL,
    [Age]                  [int] NULL,
    [PostalCode]           [varchar](100) NOT NULL,
    CONSTRAINT [PK_DimCustomer] PRIMARY KEY CLUSTERED ([CustomerKey] ASC)
);
GO

CREATE TABLE [Sales].[DimArticle](
    [ArticleKey]                [int] IDENTITY(1,1) NOT NULL,
    [ArticleID]                 [varchar](20) NOT NULL,
    [ProductCode]               [varchar](20) NOT NULL,
    [ProdName]                  [nvarchar](255) NOT NULL,
    [ProductTypeName]           [nvarchar](100) NOT NULL,
    [ProductGroupName]          [nvarchar](100) NOT NULL,
    [GraphicalAppearanceName]   [nvarchar](100) NOT NULL,
    [ColourGroupName]           [nvarchar](100) NOT NULL,
    [PerceivedColourValueName]  [nvarchar](100) NOT NULL,
    [PerceivedColourMasterName] [nvarchar](100) NOT NULL,
    [DepartmentNo]              [int] NULL,
    [DepartmentName]            [nvarchar](100) NOT NULL,
    [IndexCode]                 [varchar](10) NOT NULL,
    [IndexName]                 [nvarchar](100) NOT NULL,
    [IndexGroupName]            [nvarchar](100) NOT NULL,
    [SectionNo]                 [int] NULL,
    [SectionName]               [nvarchar](100) NOT NULL,
    [GarmentGroupName]          [nvarchar](100) NOT NULL,
    [DetailDesc]                [nvarchar](MAX) NULL,
    CONSTRAINT [PK_DimArticle] PRIMARY KEY CLUSTERED ([ArticleKey] ASC)
);
GO

CREATE TABLE [Sales].[DimTemporada](
    [TemporadaKey] [int] IDENTITY(1,1) NOT NULL,
    [TemporadaID]  [int] NOT NULL,
    [Temporada]    [nvarchar](20) NOT NULL,
    [FechaInicio]  [date] NOT NULL,
    [FechaFin]     [date] NOT NULL,
    CONSTRAINT [PK_DimTemporada] PRIMARY KEY CLUSTERED ([TemporadaKey] ASC)
);
GO

CREATE TABLE [Sales].[DimSalesChannel](
    [SalesChannelKey]  [int] IDENTITY(1,1) NOT NULL,
    [SalesChannelID]   [int] NOT NULL,
    [SalesChannelName] [varchar](50) NOT NULL,
    CONSTRAINT [PK_DimSalesChannel] PRIMARY KEY CLUSTERED ([SalesChannelKey] ASC)
);
GO

-- Tabla de hechos: claves foráneas y precio, sin PK propia
CREATE TABLE [Sales].[FactSales](
    [FechaKey]        [int] NOT NULL,
    [CustomerKey]     [int] NOT NULL,
    [ArticleKey]      [int] NOT NULL,
    [TemporadaKey]    [int] NOT NULL,
    [SalesChannelKey] [int] NOT NULL,
    [Price]           [decimal](18, 4) NOT NULL
);
GO

-- Rechazos de ventas
CREATE TABLE [ERROR].[ErrorFactSales](
    [t_dat]            NVARCHAR(500) NULL,
    [customer_id]      NVARCHAR(500) NULL,
    [article_id]       NVARCHAR(500) NULL,
    [price]            NVARCHAR(500) NULL,
    [sales_channel_id] NVARCHAR(500) NULL,
    [TemporadaID]      NVARCHAR(500) NULL,
    [FechaKey]         INT NULL,
    [CustomerKey]      INT NULL,
    [ArticleKey]       INT NULL,
    [TemporadaKey]     INT NULL,
    [SalesChannelKey]  INT NULL
);
GO

-- Claves foráneas
ALTER TABLE [Sales].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimFecha]
FOREIGN KEY([FechaKey]) REFERENCES [GENERICO].[DimFecha] ([FechaKey]);
GO

ALTER TABLE [Sales].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimCustomer]
FOREIGN KEY([CustomerKey]) REFERENCES [Sales].[DimCustomer] ([CustomerKey]);
GO

ALTER TABLE [Sales].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimArticle]
FOREIGN KEY([ArticleKey]) REFERENCES [Sales].[DimArticle] ([ArticleKey]);
GO

ALTER TABLE [Sales].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimTemporada]
FOREIGN KEY([TemporadaKey]) REFERENCES [Sales].[DimTemporada] ([TemporadaKey]);
GO

ALTER TABLE [Sales].[FactSales] WITH CHECK ADD CONSTRAINT [FK_FactSales_DimSalesChannel]
FOREIGN KEY([SalesChannelKey]) REFERENCES [Sales].[DimSalesChannel] ([SalesChannelKey]);
GO

-- Índices de claves de negocio
CREATE UNIQUE INDEX UX_DimCustomer_CustomerID ON Sales.DimCustomer(CustomerID);
CREATE UNIQUE INDEX UX_DimArticle_ArticleID ON Sales.DimArticle(ArticleID);
CREATE UNIQUE INDEX UX_DimTemporada_TemporadaID ON Sales.DimTemporada(TemporadaID);
CREATE UNIQUE INDEX UX_DimSalesChannel_SalesChannelID ON Sales.DimSalesChannel(SalesChannelID);
GO

-- Comodines y canales de venta
INSERT INTO [GENERICO].[DimFecha] (
    [FechaKey], [Fecha], [Dia_Semana], [Nombre_Dia_Semana], [Dia_Mes], [Dia_Anio],
    [Nombre_Mes], [Mes_Anio], [Semana_Anio], [Anio], [Bimestre], [Trimestre],
    [Cuatrimestre], [Semestre], [Fin_Semana]
)
VALUES (-1, '1900-01-01', 0, 'Sin Fecha', 0, 0, 'Sin Fecha', 0, 0, 0, 0, 0, 0, 0, 0);
GO

SET IDENTITY_INSERT [Sales].[DimTemporada] ON;
INSERT INTO [Sales].[DimTemporada] ([TemporadaKey], [TemporadaID], [Temporada], [FechaInicio], [FechaFin])
VALUES (-1, -1, 'Sin Temporada', '1900-01-01', '1900-01-01');
SET IDENTITY_INSERT [Sales].[DimTemporada] OFF;
GO

SET IDENTITY_INSERT [Sales].[DimCustomer] ON;
INSERT INTO [Sales].[DimCustomer] ([CustomerKey], [CustomerID], [FN], [Active], [ClubMemberStatus], [FashionNewsFrequency], [Age], [PostalCode])
VALUES (-1, 'Unknown', -1, -1, 'Sin Datos', 'Sin Datos', -1, 'Sin Datos');
SET IDENTITY_INSERT [Sales].[DimCustomer] OFF;
GO

SET IDENTITY_INSERT [Sales].[DimArticle] ON;
INSERT INTO [Sales].[DimArticle] (
    [ArticleKey], [ArticleID], [ProductCode], [ProdName], [ProductTypeName],
    [ProductGroupName], [GraphicalAppearanceName], [ColourGroupName],
    [PerceivedColourValueName], [PerceivedColourMasterName], [DepartmentNo],
    [DepartmentName], [IndexCode], [IndexName], [IndexGroupName],
    [SectionNo], [SectionName], [GarmentGroupName], [DetailDesc]
)
VALUES (-1, 'Unknown', 'Unknown', 'Sin Datos', 'Sin Datos', 'Sin Datos', 'Sin Datos', 'Sin Datos', 'Sin Datos', 'Sin Datos', -1, 'Sin Datos', 'U', 'Sin Datos', 'Sin Datos', -1, 'Sin Datos', 'Sin Datos', 'Sin Datos');
SET IDENTITY_INSERT [Sales].[DimArticle] OFF;
GO

SET IDENTITY_INSERT [Sales].[DimSalesChannel] ON;
INSERT INTO [Sales].[DimSalesChannel] ([SalesChannelKey], [SalesChannelID], [SalesChannelName])
VALUES
    (-1, -1, 'Sin Datos'),
    (1, 1, 'Tienda Física'),
    (2, 2, 'Tienda Online');
SET IDENTITY_INSERT [Sales].[DimSalesChannel] OFF;
GO
