USE [DWH_HM];
GO

-- Procedimientos almacenados de dimensiones
CREATE OR ALTER PROCEDURE [Sales].[sp_DimCustomer]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Conservar el comodín
        DELETE FROM Sales.DimCustomer WHERE CustomerKey<>-1;

        -- Preparar los atributos de Stage
        ;WITH Leidos AS (
            SELECT
                NULLIF(LTRIM(RTRIM([customer_id])),N'') AS [customer_id],
                NULLIF(LTRIM(RTRIM([FN])),N'') AS [FN],
                NULLIF(LTRIM(RTRIM([Active])),N'') AS [Active],
                NULLIF(LTRIM(RTRIM([club_member_status])),N'') AS [club_member_status],
                NULLIF(LTRIM(RTRIM([fashion_news_frequency])),N'') AS [fashion_news_frequency],
                NULLIF(LTRIM(RTRIM([age])),N'') AS [age],
                NULLIF(LTRIM(RTRIM([postal_code])),N'') AS [postal_code]
            FROM STAGE_HM.SALES.StageCustomers
        ), Convertidos AS (
            SELECT
                CASE WHEN LEN(s.[customer_id])<=100 AND s.[customer_id] NOT IN(N'Unknown',N'-1') THEN CONVERT(VARCHAR(100),s.[customer_id]) END AS [CustomerID],
                CASE WHEN TRY_CONVERT(FLOAT,s.[FN]) IN(0,1) THEN TRY_CONVERT(FLOAT,s.[FN]) ELSE -1 END AS [FN],
                CASE WHEN TRY_CONVERT(FLOAT,s.[Active]) IN(0,1) THEN TRY_CONVERT(FLOAT,s.[Active]) ELSE -1 END AS [Active],
                CASE WHEN LEN(s.[club_member_status])<=50 THEN UPPER(s.[club_member_status]) ELSE N'Sin Datos' END AS [ClubMemberStatus],
                CASE UPPER(s.[fashion_news_frequency]) WHEN N'NONE' THEN 'NONE' WHEN N'REGULARLY' THEN 'Regularly' WHEN N'MONTHLY' THEN 'Monthly' ELSE CASE WHEN LEN(s.[fashion_news_frequency])<=50 THEN CONVERT(VARCHAR(50),s.[fashion_news_frequency]) ELSE N'Sin Datos' END END AS [FashionNewsFrequency],
                CASE WHEN TRY_CONVERT(INT,s.[age])>=0 THEN TRY_CONVERT(INT,s.[age]) ELSE -1 END AS [Age],
                CASE WHEN LEN(s.[postal_code])<=100 THEN CONVERT(VARCHAR(100),s.[postal_code]) ELSE N'Sin Datos' END AS [PostalCode]
            FROM Leidos s
        )
        -- Consolidar copias de la misma información
        SELECT DISTINCT
            [CustomerID] COLLATE Latin1_General_100_BIN2 AS [CustomerID],
            [FN],
            [Active],
            [ClubMemberStatus] COLLATE Latin1_General_100_BIN2 AS [ClubMemberStatus],
            [FashionNewsFrequency] COLLATE Latin1_General_100_BIN2 AS [FashionNewsFrequency],
            [Age],
            [PostalCode] COLLATE Latin1_General_100_BIN2 AS [PostalCode]
        INTO #Preparados
        FROM Convertidos
        WHERE [CustomerID] IS NOT NULL;

        -- Cargar únicamente identificadores con una sola versión
        MERGE Sales.DimCustomer WITH(HOLDLOCK) AS T
        USING (
            SELECT P.*
            FROM #Preparados P
            WHERE P.[CustomerID] COLLATE DATABASE_DEFAULT IN (
                SELECT [CustomerID] COLLATE DATABASE_DEFAULT
                FROM #Preparados
                GROUP BY [CustomerID] COLLATE DATABASE_DEFAULT
                HAVING COUNT_BIG(*)=1
            )
        ) AS S
        ON T.[CustomerID]=S.[CustomerID] COLLATE DATABASE_DEFAULT
        WHEN NOT MATCHED BY TARGET THEN
            INSERT([CustomerID],[FN],[Active],[ClubMemberStatus],[FashionNewsFrequency],[Age],[PostalCode])
            VALUES(S.[CustomerID],S.[FN],S.[Active],S.[ClubMemberStatus],S.[FashionNewsFrequency],S.[Age],S.[PostalCode]);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Sales].[sp_DimArticle]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Conservar el comodín
        DELETE FROM Sales.DimArticle WHERE ArticleKey<>-1;

        -- Preparar los atributos de Stage
        ;WITH Leidos AS (
            SELECT
                NULLIF(LTRIM(RTRIM([article_id])),N'') AS [article_id],
                NULLIF(LTRIM(RTRIM([prod_name])),N'') AS [prod_name],
                NULLIF(LTRIM(RTRIM([product_type_name])),N'') AS [product_type_name],
                NULLIF(LTRIM(RTRIM([product_group_name])),N'') AS [product_group_name],
                NULLIF(LTRIM(RTRIM([graphical_appearance_name])),N'') AS [graphical_appearance_name],
                NULLIF(LTRIM(RTRIM([colour_group_name])),N'') AS [colour_group_name],
                NULLIF(LTRIM(RTRIM([perceived_colour_value_name])),N'') AS [perceived_colour_value_name],
                NULLIF(LTRIM(RTRIM([perceived_colour_master_name])),N'') AS [perceived_colour_master_name],
                NULLIF(LTRIM(RTRIM([department_no])),N'') AS [department_no],
                NULLIF(LTRIM(RTRIM([department_name])),N'') AS [department_name],
                NULLIF(LTRIM(RTRIM([index_code])),N'') AS [index_code],
                NULLIF(LTRIM(RTRIM([index_name])),N'') AS [index_name],
                NULLIF(LTRIM(RTRIM([index_group_name])),N'') AS [index_group_name],
                NULLIF(LTRIM(RTRIM([section_no])),N'') AS [section_no],
                NULLIF(LTRIM(RTRIM([section_name])),N'') AS [section_name],
                NULLIF(LTRIM(RTRIM([garment_group_name])),N'') AS [garment_group_name],
                NULLIF(LTRIM(RTRIM([detail_desc])),N'') AS [detail_desc]
            FROM STAGE_HM.SALES.StageArticles
        ), Convertidos AS (
            SELECT
                CASE WHEN LEN(s.[article_id]) BETWEEN 1 AND 10 AND s.[article_id] COLLATE Latin1_General_100_BIN2 NOT LIKE N'%[^0-9]%' THEN CONVERT(VARCHAR(20),RIGHT(N'0000000000'+s.[article_id],10)) END AS [ArticleID],
                CASE WHEN LEN(s.[article_id]) BETWEEN 1 AND 10 AND s.[article_id] COLLATE Latin1_General_100_BIN2 NOT LIKE N'%[^0-9]%' THEN CONVERT(VARCHAR(20),LEFT(RIGHT(N'0000000000'+s.[article_id],10),7)) ELSE 'Unknown' END AS [ProductCode],
                CASE WHEN LEN(s.[prod_name])<=255 THEN CONVERT(NVARCHAR(255),s.[prod_name]) ELSE N'Sin Datos' END AS [ProdName],
                CASE WHEN LEN(s.[product_type_name])<=100 THEN CONVERT(NVARCHAR(100),s.[product_type_name]) ELSE N'Sin Datos' END AS [ProductTypeName],
                CASE WHEN LEN(s.[product_group_name])<=100 THEN CONVERT(NVARCHAR(100),s.[product_group_name]) ELSE N'Sin Datos' END AS [ProductGroupName],
                CASE WHEN LEN(s.[graphical_appearance_name])<=100 THEN CONVERT(NVARCHAR(100),s.[graphical_appearance_name]) ELSE N'Sin Datos' END AS [GraphicalAppearanceName],
                CASE WHEN LEN(s.[colour_group_name])<=100 THEN CONVERT(NVARCHAR(100),s.[colour_group_name]) ELSE N'Sin Datos' END AS [ColourGroupName],
                CASE WHEN LEN(s.[perceived_colour_value_name])<=100 THEN CONVERT(NVARCHAR(100),s.[perceived_colour_value_name]) ELSE N'Sin Datos' END AS [PerceivedColourValueName],
                CASE WHEN LEN(s.[perceived_colour_master_name])<=100 THEN CONVERT(NVARCHAR(100),s.[perceived_colour_master_name]) ELSE N'Sin Datos' END AS [PerceivedColourMasterName],
                COALESCE(TRY_CONVERT(INT,s.[department_no]),-1) AS [DepartmentNo],
                CASE WHEN LEN(s.[department_name])<=100 THEN CONVERT(NVARCHAR(100),s.[department_name]) ELSE N'Sin Datos' END AS [DepartmentName],
                CASE WHEN LEN(s.[index_code])<=10 THEN CONVERT(VARCHAR(10),s.[index_code]) ELSE N'U' END AS [IndexCode],
                CASE WHEN LEN(s.[index_name])<=100 THEN CONVERT(NVARCHAR(100),s.[index_name]) ELSE N'Sin Datos' END AS [IndexName],
                CASE WHEN LEN(s.[index_group_name])<=100 THEN CONVERT(NVARCHAR(100),s.[index_group_name]) ELSE N'Sin Datos' END AS [IndexGroupName],
                COALESCE(TRY_CONVERT(INT,s.[section_no]),-1) AS [SectionNo],
                CASE WHEN LEN(s.[section_name])<=100 THEN CONVERT(NVARCHAR(100),s.[section_name]) ELSE N'Sin Datos' END AS [SectionName],
                CASE WHEN LEN(s.[garment_group_name])<=100 THEN CONVERT(NVARCHAR(100),s.[garment_group_name]) ELSE N'Sin Datos' END AS [GarmentGroupName],
                COALESCE(CONVERT(NVARCHAR(MAX),s.[detail_desc]),N'Sin Datos') AS [DetailDesc]
            FROM Leidos s
        )
        -- Consolidar copias de la misma información
        SELECT DISTINCT
            [ArticleID] COLLATE Latin1_General_100_BIN2 AS [ArticleID],
            [ProductCode] COLLATE Latin1_General_100_BIN2 AS [ProductCode],
            [ProdName] COLLATE Latin1_General_100_BIN2 AS [ProdName],
            [ProductTypeName] COLLATE Latin1_General_100_BIN2 AS [ProductTypeName],
            [ProductGroupName] COLLATE Latin1_General_100_BIN2 AS [ProductGroupName],
            [GraphicalAppearanceName] COLLATE Latin1_General_100_BIN2 AS [GraphicalAppearanceName],
            [ColourGroupName] COLLATE Latin1_General_100_BIN2 AS [ColourGroupName],
            [PerceivedColourValueName] COLLATE Latin1_General_100_BIN2 AS [PerceivedColourValueName],
            [PerceivedColourMasterName] COLLATE Latin1_General_100_BIN2 AS [PerceivedColourMasterName],
            [DepartmentNo],
            [DepartmentName] COLLATE Latin1_General_100_BIN2 AS [DepartmentName],
            [IndexCode] COLLATE Latin1_General_100_BIN2 AS [IndexCode],
            [IndexName] COLLATE Latin1_General_100_BIN2 AS [IndexName],
            [IndexGroupName] COLLATE Latin1_General_100_BIN2 AS [IndexGroupName],
            [SectionNo],
            [SectionName] COLLATE Latin1_General_100_BIN2 AS [SectionName],
            [GarmentGroupName] COLLATE Latin1_General_100_BIN2 AS [GarmentGroupName],
            [DetailDesc] COLLATE Latin1_General_100_BIN2 AS [DetailDesc]
        INTO #Preparados
        FROM Convertidos
        WHERE [ArticleID] IS NOT NULL;

        -- Cargar únicamente identificadores con una sola versión
        MERGE Sales.DimArticle WITH(HOLDLOCK) AS T
        USING (
            SELECT P.*
            FROM #Preparados P
            WHERE P.[ArticleID] COLLATE DATABASE_DEFAULT IN (
                SELECT [ArticleID] COLLATE DATABASE_DEFAULT
                FROM #Preparados
                GROUP BY [ArticleID] COLLATE DATABASE_DEFAULT
                HAVING COUNT_BIG(*)=1
            )
        ) AS S
        ON T.[ArticleID]=S.[ArticleID] COLLATE DATABASE_DEFAULT
        WHEN NOT MATCHED BY TARGET THEN
            INSERT([ArticleID],[ProductCode],[ProdName],[ProductTypeName],[ProductGroupName],[GraphicalAppearanceName],[ColourGroupName],[PerceivedColourValueName],[PerceivedColourMasterName],[DepartmentNo],[DepartmentName],[IndexCode],[IndexName],[IndexGroupName],[SectionNo],[SectionName],[GarmentGroupName],[DetailDesc])
            VALUES(S.[ArticleID],S.[ProductCode],S.[ProdName],S.[ProductTypeName],S.[ProductGroupName],S.[GraphicalAppearanceName],S.[ColourGroupName],S.[PerceivedColourValueName],S.[PerceivedColourMasterName],S.[DepartmentNo],S.[DepartmentName],S.[IndexCode],S.[IndexName],S.[IndexGroupName],S.[SectionNo],S.[SectionName],S.[GarmentGroupName],S.[DetailDesc]);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [GENERICO].[sp_DimFecha]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET DATEFIRST 7;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM GENERICO.DimFecha WHERE FechaKey<>-1;
        ;WITH Fechas AS (
            SELECT DISTINCT CASE WHEN LEN(LTRIM(RTRIM(Fecha)))=8 THEN TRY_CONVERT(DATE,Fecha,112) WHEN SUBSTRING(LTRIM(RTRIM(Fecha)),5,1)=N'-' THEN TRY_CONVERT(DATE,Fecha,23) ELSE TRY_CONVERT(DATE,Fecha,103) END AS Fecha
            FROM STAGE_HM.GENERICO.StageDimFecha
        ), Calendario AS (
            SELECT CONVERT(INT,CONVERT(CHAR(8),Fecha,112)) AS FechaKey,Fecha,
                DATEPART(WEEKDAY,Fecha) AS Dia_Semana,
                CHOOSE(DATEPART(WEEKDAY,Fecha),'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday') AS Nombre_Dia_Semana,
                DAY(Fecha) AS Dia_Mes,DATEPART(DAYOFYEAR,Fecha) AS Dia_Anio,
                CHOOSE(MONTH(Fecha),'January','February','March','April','May','June','July','August','September','October','November','December') AS Nombre_Mes,
                MONTH(Fecha) AS Mes_Anio,DATEPART(WEEK,Fecha) AS Semana_Anio,YEAR(Fecha) AS Anio,
                (MONTH(Fecha)+1)/2 AS Bimestre,DATEPART(QUARTER,Fecha) AS Trimestre,
                (MONTH(Fecha)+3)/4 AS Cuatrimestre,(MONTH(Fecha)+5)/6 AS Semestre,
                CASE WHEN DATEPART(WEEKDAY,Fecha) IN(1,7) THEN 1 ELSE 0 END AS Fin_Semana
            FROM Fechas WHERE Fecha IS NOT NULL
        )
        MERGE GENERICO.DimFecha WITH(HOLDLOCK) AS T
        USING Calendario AS S ON T.FechaKey=S.FechaKey
        WHEN NOT MATCHED BY TARGET THEN INSERT(FechaKey,Fecha,Dia_Semana,Nombre_Dia_Semana,Dia_Mes,Dia_Anio,Nombre_Mes,Mes_Anio,Semana_Anio,Anio,Bimestre,Trimestre,Cuatrimestre,Semestre,Fin_Semana)
            VALUES(S.FechaKey,S.Fecha,S.Dia_Semana,S.Nombre_Dia_Semana,S.Dia_Mes,S.Dia_Anio,S.Nombre_Mes,S.Mes_Anio,S.Semana_Anio,S.Anio,S.Bimestre,S.Trimestre,S.Cuatrimestre,S.Semestre,S.Fin_Semana);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [Sales].[sp_DimTemporada]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM Sales.DimTemporada WHERE TemporadaKey<>-1;
        ;WITH Leidos AS (
            SELECT TRY_CONVERT(INT,NULLIF(LTRIM(RTRIM(TemporadaID)),N'')) AS TemporadaID,
                COALESCE(CASE WHEN LEN(LTRIM(RTRIM(Temporada)))<=20 THEN NULLIF(LTRIM(RTRIM(Temporada)),N'') END,N'Sin Datos') AS Temporada,
                CASE WHEN LEN(LTRIM(RTRIM(FechaInicio)))=8 THEN TRY_CONVERT(DATE,FechaInicio,112) WHEN SUBSTRING(LTRIM(RTRIM(FechaInicio)),5,1)=N'-' THEN TRY_CONVERT(DATE,FechaInicio,23) ELSE TRY_CONVERT(DATE,FechaInicio,103) END AS Inicio,CASE WHEN LEN(LTRIM(RTRIM(FechaFin)))=8 THEN TRY_CONVERT(DATE,FechaFin,112) WHEN SUBSTRING(LTRIM(RTRIM(FechaFin)),5,1)=N'-' THEN TRY_CONVERT(DATE,FechaFin,23) ELSE TRY_CONVERT(DATE,FechaFin,103) END AS Fin
            FROM STAGE_HM.SALES.StageTemporada
        ), Convertidos AS (
            SELECT TemporadaID,Temporada,
                CASE WHEN Inicio<=Fin THEN Inicio ELSE CONVERT(DATE,'19000101',112) END AS FechaInicio,
                CASE WHEN Inicio<=Fin THEN Fin ELSE CONVERT(DATE,'19000101',112) END AS FechaFin
            FROM Leidos WHERE TemporadaID>0
        )
        SELECT DISTINCT TemporadaID,Temporada COLLATE Latin1_General_100_BIN2 AS Temporada,FechaInicio,FechaFin INTO #P FROM Convertidos;
        MERGE Sales.DimTemporada WITH(HOLDLOCK) AS T
        USING(SELECT P.* FROM #P P WHERE NOT EXISTS(
            SELECT 1 FROM #P D WHERE D.TemporadaID=P.TemporadaID AND
                (D.Temporada COLLATE Latin1_General_100_BIN2<>P.Temporada COLLATE Latin1_General_100_BIN2 OR D.FechaInicio<>P.FechaInicio OR D.FechaFin<>P.FechaFin)
        )) AS S ON T.TemporadaID=S.TemporadaID
        WHEN NOT MATCHED BY TARGET THEN INSERT(TemporadaID,Temporada,FechaInicio,FechaFin)
            VALUES(S.TemporadaID,S.Temporada,S.FechaInicio,S.FechaFin);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
