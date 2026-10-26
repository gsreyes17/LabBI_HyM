USE [DWH_HM];
GO
-- Dimensiones de la comparación mensual
CREATE OR ALTER VIEW [Sales].[vw_DimCategory]
AS
SELECT CAST(-1 AS bigint) AS [CategoryID],
       CAST(N'Sin Datos' AS nvarchar(100)) AS [DepartmentName],
       CAST(N'Sin Datos' AS nvarchar(100)) AS [SectionName],
       CAST(N'Sin Datos' AS nvarchar(20)) AS [Temporada],
       -1 AS [TemporadaID]
UNION ALL
SELECT ROW_NUMBER() OVER (ORDER BY A.[DepartmentName], A.[SectionName], T.[TemporadaID]) AS [CategoryID],
       A.[DepartmentName], A.[SectionName], T.[Temporada], T.[TemporadaID]
FROM (
    SELECT DISTINCT [DepartmentName], [SectionName]
    FROM [Sales].[DimArticle]
    WHERE [ArticleKey] <> -1
) A
CROSS JOIN (
    SELECT DISTINCT [TemporadaID], [Temporada]
    FROM [Sales].[DimTemporada]
    WHERE [TemporadaKey] <> -1
) T;
GO

CREATE OR ALTER VIEW [Sales].[vw_DimMonth]
AS
SELECT CAST('-1' AS VARCHAR(6)) AS FechaKey,CONVERT(DATE,'19000101',112) AS Fecha,CAST(N'Sin Fecha' AS NVARCHAR(20)) AS Nombre_Mes,CAST(0 AS TINYINT) AS Mes_Anio,CAST(0 AS SMALLINT) AS Anio
UNION ALL
SELECT CAST([Anio] * 100 + [Mes_Anio] AS varchar(6)) AS [FechaKey],
       DATEFROMPARTS([Anio], [Mes_Anio], 1) AS [Fecha],
       MIN([Nombre_Mes]) AS [Nombre_Mes], [Mes_Anio], [Anio]
FROM [GENERICO].[DimFecha]
WHERE [FechaKey] <> -1
GROUP BY [Anio], [Mes_Anio];
GO

-- Metas de Stage con sus referencias de categoría y mes
CREATE OR ALTER VIEW [Sales].[vw_FactSalesGoals]
AS
WITH Convertidos AS (
    SELECT LTRIM(RTRIM(Escenario)) AS Escenario,
        LTRIM(RTRIM(department_name)) AS DepartmentName,
        LTRIM(RTRIM(section_name)) AS SectionName,
        TRY_CONVERT(INT,NULLIF(LTRIM(RTRIM(TemporadaID)),N'')) AS TemporadaID,
        LTRIM(RTRIM(AnioMes)) AS AnioMes,
        TRY_CONVERT(DECIMAL(18,4),NULLIF(LTRIM(RTRIM(Monto)),N'')) AS Monto
    FROM [STAGE_HM].[SALES].[StageGoalsHyM]
), Preparados AS (
    SELECT *,COUNT_BIG(*) OVER(PARTITION BY Escenario,DepartmentName,SectionName,
        TemporadaID,TRY_CONVERT(INT,AnioMes)) AS Copias
    FROM Convertidos
)
SELECT C.CategoryID,M.FechaKey AS MontKey,CONVERT(NVARCHAR(50),G.Escenario) AS Escenario,G.Monto AS SubTotal
FROM Preparados G
INNER JOIN Sales.vw_DimCategory C ON C.DepartmentName=G.DepartmentName
    AND C.SectionName=G.SectionName AND C.TemporadaID=G.TemporadaID
INNER JOIN Sales.vw_DimMonth M ON M.FechaKey=G.AnioMes
WHERE G.Copias=1 AND G.TemporadaID>0 AND G.Monto>=0
    AND LEN(G.Escenario) BETWEEN 1 AND 50
    AND LEN(G.DepartmentName) BETWEEN 1 AND 100
    AND LEN(G.SectionName) BETWEEN 1 AND 100
    AND LEN(G.AnioMes)=6;
GO

CREATE OR ALTER VIEW [Sales].[vw_FactSalesMonthCategory]
AS
SELECT ISNULL(C.[CategoryID], CAST(-1 AS bigint)) AS [CategoryID],
       V.[MontKey], V.[SubTotal]
FROM (
    SELECT LEFT(F.[FechaKey], 6) AS [MontKey],
           A.[DepartmentName], A.[SectionName], T.[TemporadaID],
           SUM(F.[Price]) AS [SubTotal]
    FROM [Sales].[FactSales] F
    INNER JOIN [Sales].[DimArticle] A ON A.[ArticleKey] = F.[ArticleKey]
    INNER JOIN [Sales].[DimTemporada] T ON T.[TemporadaKey] = F.[TemporadaKey]
    GROUP BY LEFT(F.[FechaKey], 6), A.[DepartmentName], A.[SectionName], T.[TemporadaID]
) V
LEFT JOIN [Sales].[vw_DimCategory] C
    ON C.[DepartmentName] = V.[DepartmentName]
   AND C.[SectionName] = V.[SectionName]
   AND C.[TemporadaID] = V.[TemporadaID];
GO
