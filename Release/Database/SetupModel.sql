/****** Object:  UserDefinedFunction [dbo].[BuildAttributeQuery]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Buld the attribute query
-- =============================================
CREATE FUNCTION [dbo].[BuildAttributeQuery] (
  -- the attribute field name, NULL is supported
  @attributeField AS NVARCHAR(MAX),
  -- the attribute name as JSON
  @attributes AS NVARCHAR(MAX) = NULL
  )
RETURNS NVARCHAR(MAX)
AS
BEGIN
  -- the query sql
  DECLARE @sql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);
  DECLARE @attributeName VARCHAR(128);
  DECLARE @index INT;
  DECLARE @count INT;

  SET @sql = '';

  IF (@attributes IS NULL)
  BEGIN
    RETURN @sql;
  END

  SELECT @count = COUNT(*)
  FROM OPENJSON(@attributes);

  IF (@count = 0)
  BEGIN
    RETURN @sql;
  END

  -- foreach attribute
  SELECT @index = 0;

  WHILE (@index < @count)
  BEGIN
    SELECT @attributeName = value
    FROM OPENJSON(@attributes)
    WHERE [key] = @index;

    IF (@attributeField IS NULL)
    BEGIN
      SET @attributeSql = '
            NULL AS ' + @attributeName;
    END
    ELSE IF (LEN(@attributeName) > 0)
    BEGIN
      -- text attribute sql
      IF (SUBSTRING(@attributeName, 1, 3) = 'TA_')
      BEGIN
        SET @attributeSql = '
                dbo.GetTextAttributeValue(' + @attributeField + ', ''' + REPLACE(@attributeName, N'TA_', '') + ''') AS ' + @attributeName;
      END

      -- date attribute sql
      IF (SUBSTRING(@attributeName, 1, 3) = 'DA_')
      BEGIN
        SET @attributeSql = '
                dbo.GetDateAttributeValue(' + @attributeField + ', ''' + REPLACE(@attributeName, N'DA_', '') + ''') AS ' + @attributeName;
      END
          -- numeric attribute sql
      ELSE IF (SUBSTRING(@attributeName, 1, 3) = 'NA_')
      BEGIN
        SET @attributeSql = '
                dbo.GetNumericAttributeValue(' + @attributeField + ', ''' + REPLACE(@attributeName, N'NA_', '') + ''') AS ' + @attributeName;
      END
    END

    -- concat sql statement
    SET @sql = @sql + @attributeSql;

    -- separater between multiple attributes
    IF (@index <> @count - 1)
    BEGIN
      SET @sql = @sql + ', ';
    END

    SET @index = @index + 1
  END

  IF (LEN(@sql) > 0)
  BEGIN
    SET @sql = ',' + @sql + '
        ';
  END

  RETURN @sql;
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetAttributeNames]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the attribute names from JSON
-- =============================================
CREATE FUNCTION [dbo].[GetAttributeNames] (
  -- the attributes
  @attributes AS NVARCHAR(MAX)
  )
RETURNS NVARCHAR(MAX)
AS
BEGIN
  DECLARE @sql AS NVARCHAR(MAX);
  DECLARE @value VARCHAR(128);
  DECLARE @index INT;
  DECLARE @count INT;

  SET @sql = '';

  SELECT @count = COUNT(*)
  FROM OPENJSON(@attributes);

  IF (@count = 0)
  BEGIN
    RETURN @sql;
  END

  -- foreach attribute
  SET @index = 0;

  WHILE (@index < @count)
  BEGIN
    SELECT @value = value
    FROM OPENJSON(@attributes)
    WHERE [key] = @index;

    IF (LEN(@value) > 0)
    BEGIN
      -- concat attribute names
      SET @sql = @sql + @value;

      -- separater between multiple attributes
      IF (@index <> @count - 1)
      BEGIN
        SET @sql = @sql + ', ';
      END
    END

    SET @index = @index + 1
  END

  IF (LEN(@sql) > 0)
  BEGIN
    SET @sql = ',' + @sql + '
        ';
  END

  RETURN @sql;
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetDateAttributeValue]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get numeric value from JSON attributes
-- =============================================
CREATE FUNCTION [dbo].[GetDateAttributeValue] (
  -- the attributes json
  @attributes AS NVARCHAR(MAX),
  -- the attribute
  @name AS NVARCHAR(MAX)
  )
RETURNS DATETIME2(7)
AS
BEGIN
  DECLARE @type INT;
  DECLARE @value VARCHAR(MAX);

  SELECT @value = value,
    @type = type
  FROM OPENJSON(@attributes)
  WHERE [key] = @name;

  RETURN IIF(@type = 1, CAST(@value AS DATETIME2(7)), NULL);
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetLocalizedValue]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the localized value from JSON localizations
-- =============================================
CREATE FUNCTION [dbo].[GetLocalizedValue] (
  -- the localizations
  @localizations AS NVARCHAR(MAX),
  -- the cultue
  @culture AS NVARCHAR(128),
  -- the fallback value
  @fallback AS NVARCHAR(MAX)
  )
RETURNS NVARCHAR(MAX)
AS
BEGIN
  DECLARE @value VARCHAR(MAX);

  SELECT @value = value
  FROM OPENJSON(@localizations)
  WHERE [key] = @culture;

  RETURN IIF(@value IS NULL, @fallback, @value);
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetNumericAttributeValue]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get numeric value from JSON attributes
-- =============================================
CREATE FUNCTION [dbo].[GetNumericAttributeValue] (
  -- the attributes json
  @attributes AS NVARCHAR(MAX),
  -- the attribute
  @name AS NVARCHAR(MAX)
  )
RETURNS DECIMAL(28, 6)
AS
BEGIN
  DECLARE @type INT;
  DECLARE @value VARCHAR(MAX);

  SELECT @value = value,
    @type = type
  FROM OPENJSON(@attributes)
  WHERE [key] = @name;

  RETURN IIF(@type = 2, CAST(@value AS DECIMAL(28, 6)), NULL);
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetTextAttributeValue]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get a text value from JSON attributes
-- =============================================
CREATE FUNCTION [dbo].[GetTextAttributeValue] (
  -- the attributes json
  @attributes AS NVARCHAR(MAX),
  -- the attribute
  @name AS NVARCHAR(MAX)
  )
RETURNS NVARCHAR(MAX)
AS
BEGIN
  DECLARE @type INT;
  DECLARE @value VARCHAR(MAX);

  SELECT @value = value,
    @type = type
  FROM OPENJSON(@attributes)
  WHERE [key] = @name;

  RETURN IIF(@type = 1, @value, NULL);
END
GO

/****** Object:  UserDefinedFunction [dbo].[IsMatchingCluster]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Test for matching include/exclude clusters
-- =============================================
CREATE FUNCTION [dbo].[IsMatchingCluster] (
  -- the include clusters: JSON array of clusters VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of clusters VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL,
  -- the test clusters: JSON array of clusters VARCHAR(128)
  @testClusters AS VARCHAR(MAX) = NULL
  )
RETURNS BIT
AS
BEGIN
  DECLARE @value VARCHAR(128);
  DECLARE @index INT;
  DECLARE @count INT;
  DECLARE @testCount INT;

  SELECT @testCount = COUNT(*)
  FROM OPENJSON(@testClusters);

  IF (
      @includeClusters IS NOT NULL
      OR @excludeClusters IS NOT NULL
      )
  BEGIN
    -- include clusters
    DECLARE @includeCount INT;

    SELECT @includeCount = COUNT(*)
    FROM OPENJSON(@includeClusters);

    IF (@includeCount > 0)
    BEGIN
      SET @index = 0;

      WHILE (@index < @includeCount)
      BEGIN
        SELECT @value = value
        FROM OPENJSON(@includeClusters)
        WHERE [key] = @index;

        IF (LEN(@value) > 0)
        BEGIN
          SELECT @count = COUNT(*)
          FROM OPENJSON(@testClusters)
          WHERE value = @value;

          IF (@count = 0)
          BEGIN
            -- missing include cluster
            RETURN 0;
          END
        END

        SET @index = @index + 1
      END
    END

    -- exclude clusters
    DECLARE @excludeCount INT;

    SELECT @excludeCount = COUNT(*)
    FROM OPENJSON(@excludeClusters);

    IF (@excludeCount > 0)
    BEGIN
      SET @index = 0;

      WHILE (@index < @excludeCount)
      BEGIN
        SELECT @value = value
        FROM OPENJSON(@excludeClusters)
        WHERE [key] = @index;

        IF (LEN(@value) > 0)
        BEGIN
          SELECT @count = COUNT(*)
          FROM OPENJSON(@testClusters)
          WHERE value = @value;

          IF (@count > 0)
          BEGIN
            -- present exclude cluster
            RETURN 0;
          END
        END

        SET @index = @index + 1
      END
    END
  END

  RETURN 1;
END
GO

/****** Object:  Table [dbo].[PayrollLayer]    Script Date: 17.07.2023 15:01:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PayrollLayer] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [PayrollId] [int] NOT NULL,
  [RegulationName] [nvarchar](128) NOT NULL,
  [Level] [int] NOT NULL,
  [Priority] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_PayrollLayer] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Regulation]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Regulation] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Version] [int] NOT NULL,
  [SharedRegulation] [bit] NOT NULL,
  [ValidFrom] [datetime2](7) NULL,
  [Owner] [nvarchar](128) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [BaseRegulations] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Regulation.RegulationId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  UserDefinedFunction [dbo].[GetDerivedRegulations]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get all active derived regulation ids from the payroll
-- =============================================
CREATE FUNCTION [dbo].[GetDerivedRegulations] (
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- the creation date
  @createdBefore AS DATETIME2(7)
  )
RETURNS TABLE
AS
RETURN (
    WITH GroupRegulation AS (
        SELECT [Regulation].[Id],
          [PayrollLayer].[Level],
          [PayrollLayer].[Priority],
          ROW_NUMBER() OVER (
            -- group by regulation name within a payroll layer
            PARTITION BY [PayrollLayer].[Id],
            [Regulation].[Name] ORDER BY [Regulation].[ValidFrom] DESC,
              -- use latest created in case of same valid from
              [Regulation].[Created] DESC
            ) AS RowNumber
        FROM [PayrollLayer]
        INNER JOIN [Regulation]
          ON [PayrollLayer].[RegulationName] = [Regulation].[Name]
        -- active payroll layers and regulations only
        WHERE [Regulation].[Status] = 0
          -- working tenant or shared regulation 
          AND (
            [Regulation].[TenantId] = @tenantId
            OR [Regulation].[SharedRegulation] = 1
            )
          AND [Regulation].[Created] < @createdBefore
          AND (
            [Regulation].[ValidFrom] IS NULL
            OR [Regulation].[ValidFrom] < @regulationDate
            )
          AND [PayrollLayer].[Status] = 0
          AND [PayrollLayer].[PayrollId] = @payrollId
        )
    SELECT *
    FROM GroupRegulation
    WHERE RowNumber = 1
    )
GO

/****** Object:  Table [dbo].[Calendar]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Calendar] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [CycleTimeUnit] [int] NOT NULL,
  [PeriodTimeUnit] [int] NOT NULL,
  [TimeMap] [int] NOT NULL,
  [FirstMonthOfYear] [int] NULL,
  [PeriodDayCount] [decimal](28, 6) NULL,
  [YearWeekRule] [int] NULL,
  [FirstDayOfWeek] [int] NULL,
  [WeekMode] [int] NOT NULL,
  [WorkMonday] [bit] NULL,
  [WorkTuesday] [bit] NULL,
  [WorkWednesday] [bit] NULL,
  [WorkThursday] [bit] NULL,
  [WorkFriday] [bit] NULL,
  [WorkSaturday] [bit] NULL,
  [WorkSunday] [bit] NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Calendar] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Case]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Case] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [RegulationId] [int] NOT NULL,
  [CaseType] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [NameSynonyms] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [DefaultReason] [nvarchar](max) NULL,
  [DefaultReasonLocalizations] [nvarchar](max) NULL,
  [BaseCase] [nvarchar](128) NULL,
  [BaseCaseFields] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [CancellationType] [int] NOT NULL,
  [Hidden] [bit] NOT NULL,
  [AvailableExpression] [nvarchar](max) NULL,
  [BuildExpression] [nvarchar](max) NULL,
  [ValidateExpression] [nvarchar](max) NULL,
  [Lookups] [nvarchar](max) NULL,
  [Slots] [nvarchar](max) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [AvailableActions] [nvarchar](max) NULL,
  [BuildActions] [nvarchar](max) NULL,
  [ValidateActions] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_Case.CaseId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CaseAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CaseAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseId] [int] NOT NULL,
  [CaseChangeId] [int] NULL,
  [CaseType] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [NameSynonyms] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [DefaultReason] [nvarchar](max) NULL,
  [DefaultReasonLocalizations] [nvarchar](max) NULL,
  [BaseCase] [nvarchar](128) NULL,
  [BaseCaseFields] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [CancellationType] [int] NOT NULL,
  [Hidden] [bit] NOT NULL,
  [AvailableExpression] [nvarchar](max) NULL,
  [BuildExpression] [nvarchar](max) NULL,
  [ValidateExpression] [nvarchar](max) NULL,
  [Lookups] [nvarchar](max) NULL,
  [Slots] [nvarchar](max) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [AvailableActions] [nvarchar](max) NULL,
  [BuildActions] [nvarchar](max) NULL,
  [ValidateActions] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_CaseAudit.CaseAuditId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CaseField]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CaseField] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [CaseId] [int] NOT NULL,
  [ValueType] [int] NOT NULL,
  [ValueScope] [int] NOT NULL,
  [StartDateType] [int] NOT NULL,
  [EndDateType] [int] NOT NULL,
  [EndMandatory] [bit] NOT NULL,
  [DefaultStart] [nvarchar](128) NULL,
  [DefaultEnd] [nvarchar](128) NULL,
  [DefaultValue] [nvarchar](max) NULL,
  [LookupSettings] [nvarchar](max) NULL,
  [TimeType] [int] NOT NULL,
  [TimeUnit] [int] NOT NULL,
  [Culture] [nvarchar](128) NULL,
  [PeriodAggregation] [int] NOT NULL,
  [OverrideType] [int] NOT NULL,
  [CancellationMode] [int] NOT NULL,
  [ValueCreationMode] [int] NOT NULL,
  [ValueMandatory] [bit] NOT NULL,
  [Order] [int] NOT NULL,
  [Tags] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  [BuildActions] [nvarchar](max) NULL,
  [ValidateActions] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  [ValueAttributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_CaseField.CaseFieldId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CaseFieldAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CaseFieldAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseFieldId] [int] NOT NULL,
  [ValueType] [int] NOT NULL,
  [ValueScope] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [StartDateType] [int] NOT NULL,
  [EndDateType] [int] NOT NULL,
  [EndMandatory] [bit] NOT NULL,
  [DefaultStart] [nvarchar](128) NULL,
  [DefaultEnd] [nvarchar](128) NULL,
  [DefaultValue] [nvarchar](max) NULL,
  [LookupSettings] [nvarchar](max) NULL,
  [TimeType] [int] NOT NULL,
  [TimeUnit] [int] NOT NULL,
  [Culture] [nvarchar](128) NULL,
  [PeriodAggregation] [int] NOT NULL,
  [OverrideType] [int] NOT NULL,
  [CancellationMode] [int] NOT NULL,
  [ValueCreationMode] [int] NOT NULL,
  [ValueMandatory] [bit] NOT NULL,
  [Order] [int] NOT NULL,
  [Tags] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  [BuildActions] [nvarchar](max) NULL,
  [ValidateActions] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  [ValueAttributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_CaseFieldAudit] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CaseRelation]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CaseRelation] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [RegulationId] [int] NOT NULL,
  [SourceCaseName] [nvarchar](128) NOT NULL,
  [SourceCaseNameLocalizations] [nvarchar](max) NULL,
  [SourceCaseSlot] [nvarchar](128) NULL,
  [SourceCaseSlotLocalizations] [nvarchar](max) NULL,
  [TargetCaseName] [nvarchar](128) NOT NULL,
  [TargetCaseNameLocalizations] [nvarchar](max) NULL,
  [TargetCaseSlot] [nvarchar](128) NULL,
  [TargetCaseSlotLocalizations] [nvarchar](max) NULL,
  [RelationHash] [int] NOT NULL,
  [BuildExpression] [nvarchar](max) NULL,
  [ValidateExpression] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [Order] [int] NOT NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [BuildActions] [nvarchar](max) NULL,
  [ValidateActions] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_CaseRelation.CaseRelationId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CaseRelationAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CaseRelationAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseRelationId] [int] NOT NULL,
  [SourceCaseName] [nvarchar](128) NOT NULL,
  [SourceCaseNameLocalizations] [nvarchar](max) NULL,
  [SourceCaseSlot] [nvarchar](128) NULL,
  [SourceCaseSlotLocalizations] [nvarchar](max) NULL,
  [TargetCaseName] [nvarchar](128) NOT NULL,
  [TargetCaseNameLocalizations] [nvarchar](max) NULL,
  [TargetCaseSlot] [nvarchar](128) NULL,
  [TargetCaseSlotLocalizations] [nvarchar](max) NULL,
  [RelationHash] [int] NOT NULL,
  [BuildExpression] [nvarchar](max) NULL,
  [ValidateExpression] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [Order] [int] NOT NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [BuildActions] [nvarchar](max) NULL,
  [ValidateActions] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_CaseRelationAudit] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Collector]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Collector] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CollectMode] [int] NOT NULL,
  [Negated] [bit] NOT NULL,
  [RegulationId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [ValueType] [int] NOT NULL,
  [CollectorGroups] [nvarchar](max) NULL,
  [StartExpression] [nvarchar](max) NULL,
  [ApplyExpression] [nvarchar](max) NULL,
  [EndExpression] [nvarchar](max) NULL,
  [Threshold] [decimal](28, 6) NULL,
  [MinResult] [decimal](28, 6) NULL,
  [MaxResult] [decimal](28, 6) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_Collector.CollectorId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CollectorAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CollectorAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CollectorId] [int] NOT NULL,
  [CollectMode] [int] NOT NULL,
  [Negated] [bit] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [ValueType] [int] NOT NULL,
  [CollectorGroups] [nvarchar](max) NULL,
  [StartExpression] [nvarchar](max) NULL,
  [ApplyExpression] [nvarchar](max) NULL,
  [EndExpression] [nvarchar](max) NULL,
  [Threshold] [decimal](28, 6) NULL,
  [MinResult] [decimal](28, 6) NULL,
  [MaxResult] [decimal](28, 6) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_CollectorAudit.CollectorAuditId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CollectorCustomResult]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CollectorCustomResult] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CollectorResultId] [int] NOT NULL,
  [CollectorName] [nvarchar](128) NOT NULL,
  [CollectorNameHash] [int] NOT NULL,
  [CollectorNameLocalizations] [nvarchar](max) NULL,
  [Source] [nvarchar](128) NOT NULL,
  [ValueType] [int] NOT NULL,
  [Value] [decimal](28, 6) NOT NULL,
  [Start] [datetime2](7) NOT NULL,
  [StartHash] [int] NOT NULL,
  [End] [datetime2](7) NOT NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_CollectorCustomResult] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CollectorResult]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CollectorResult] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [PayrollResultId] [int] NOT NULL,
  [CollectorId] [int] NOT NULL,
  [CollectorName] [nvarchar](128) NOT NULL,
  [CollectorNameHash] [int] NOT NULL,
  [CollectorNameLocalizations] [nvarchar](max) NULL,
  [CollectMode] [int] NOT NULL,
  [Negated] [bit] NOT NULL,
  [ValueType] [int] NOT NULL,
  [Value] [decimal](28, 6) NOT NULL,
  [Start] [datetime2](7) NOT NULL,
  [StartHash] [int] NOT NULL,
  [End] [datetime2](7) NOT NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_CollectorResult] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CompanyCaseChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CompanyCaseChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [UserId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CancellationType] [int] NOT NULL,
  [CancellationId] [int] NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Reason] [nvarchar](max) NOT NULL,
  [ValidationCaseName] [nvarchar](128) NULL,
  [Forecast] [nvarchar](128) NULL,
  CONSTRAINT [PK_CompanyCaseChange] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CompanyCaseDocument]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CompanyCaseDocument] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseValueId] [int] NOT NULL,
  [Name] [nvarchar](256) NOT NULL,
  [Content] [nvarchar](max) NOT NULL,
  [ContentType] [nvarchar](128) NOT NULL,
  CONSTRAINT [PK_CompanyCaseDocument] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CompanyCaseValue]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CompanyCaseValue] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CaseName] [nvarchar](128) NOT NULL,
  [CaseNameLocalizations] [nvarchar](max) NULL,
  [CaseFieldName] [nvarchar](128) NOT NULL,
  [CaseFieldNameLocalizations] [nvarchar](max) NULL,
  [CaseSlot] [nvarchar](128) NULL,
  [CaseSlotLocalizations] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [Value] [nvarchar](max) NOT NULL,
  [NumericValue] [decimal](28, 6) NULL,
  [CaseRelation] [nvarchar](max) NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Start] [datetime2](7) NULL,
  [End] [datetime2](7) NULL,
  [Forecast] [nvarchar](128) NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_CompanyCaseValue] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[CompanyCaseValueChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CompanyCaseValueChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseChangeId] [int] NOT NULL,
  [CaseValueId] [int] NOT NULL,
  CONSTRAINT [PK_IX_CompanyCaseValueChange] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Division]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Division] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Culture] [nvarchar](128) NULL,
  [Calendar] [nvarchar](128) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Division] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Employee]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Employee] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Identifier] [nvarchar](128) NOT NULL,
  [FirstName] [nvarchar](128) NOT NULL,
  [LastName] [nvarchar](128) NOT NULL,
  [Culture] [nvarchar](128) NULL,
  [Calendar] [nvarchar](128) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Employee.EmployeeId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[EmployeeCaseChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EmployeeCaseChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [EmployeeId] [int] NOT NULL,
  [UserId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CancellationType] [int] NOT NULL,
  [CancellationId] [int] NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Reason] [nvarchar](max) NOT NULL,
  [ValidationCaseName] [nvarchar](128) NULL,
  [Forecast] [nvarchar](128) NULL,
  CONSTRAINT [PK_EmployeeCaseChange] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[EmployeeCaseDocument]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EmployeeCaseDocument] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseValueId] [int] NOT NULL,
  [Name] [nvarchar](256) NOT NULL,
  [Content] [nvarchar](max) NOT NULL,
  [ContentType] [nvarchar](128) NOT NULL,
  CONSTRAINT [PK_EmployeeCaseDocument] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[EmployeeCaseValue]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EmployeeCaseValue] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [EmployeeId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CaseName] [nvarchar](128) NOT NULL,
  [CaseNameLocalizations] [nvarchar](max) NULL,
  [CaseFieldName] [nvarchar](128) NOT NULL,
  [CaseFieldNameLocalizations] [nvarchar](max) NULL,
  [CaseSlot] [nvarchar](128) NULL,
  [CaseSlotLocalizations] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [Value] [nvarchar](max) NOT NULL,
  [NumericValue] [decimal](28, 6) NULL,
  [CaseRelation] [nvarchar](max) NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Start] [datetime2](7) NULL,
  [End] [datetime2](7) NULL,
  [Forecast] [nvarchar](128) NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_EmployeeCaseValue] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[EmployeeCaseValueChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EmployeeCaseValueChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseChangeId] [int] NOT NULL,
  [CaseValueId] [int] NOT NULL,
  CONSTRAINT [PK_EmployeeCaseValueChange] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[EmployeeDivision]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[EmployeeDivision] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [EmployeeId] [int] NOT NULL,
  [DivisionId] [int] NOT NULL,
  CONSTRAINT [PK_EmployeeDivision] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[GlobalCaseChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[GlobalCaseChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [UserId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CancellationType] [int] NOT NULL,
  [CancellationId] [int] NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Reason] [nvarchar](max) NOT NULL,
  [ValidationCaseName] [nvarchar](128) NULL,
  [Forecast] [nvarchar](128) NULL,
  CONSTRAINT [PK_GlobalCaseChange] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[GlobalCaseDocument]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[GlobalCaseDocument] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseValueId] [int] NOT NULL,
  [Name] [nvarchar](256) NOT NULL,
  [Content] [nvarchar](max) NOT NULL,
  [ContentType] [nvarchar](128) NOT NULL,
  CONSTRAINT [PK_GlobalCaseDocument] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[GlobalCaseValue]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[GlobalCaseValue] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CaseName] [nvarchar](128) NOT NULL,
  [CaseNameLocalizations] [nvarchar](max) NULL,
  [CaseFieldName] [nvarchar](128) NOT NULL,
  [CaseFieldNameLocalizations] [nvarchar](max) NULL,
  [CaseSlot] [nvarchar](128) NULL,
  [CaseSlotLocalizations] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [Value] [nvarchar](max) NOT NULL,
  [NumericValue] [decimal](28, 6) NULL,
  [CaseRelation] [nvarchar](max) NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Start] [datetime2](7) NULL,
  [End] [datetime2](7) NULL,
  [Forecast] [nvarchar](128) NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_GlobalCaseValue] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[GlobalCaseValueChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[GlobalCaseValueChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseChangeId] [int] NOT NULL,
  [CaseValueId] [int] NOT NULL,
  CONSTRAINT [PK_GlobalCaseValueChange] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Log]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Log] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Level] [int] NOT NULL,
  [Message] [nvarchar](max) NOT NULL,
  [User] [nvarchar](128) NOT NULL,
  [Error] [nvarchar](max) NULL,
  [Comment] [nvarchar](max) NULL,
  [Owner] [nvarchar](128) NULL,
  [OwnerType] [nvarchar](128) NULL,
  CONSTRAINT [PK_Log_1] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Lookup]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Lookup] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [RegulationId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [RangeSize] [decimal](28, 6) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Lookup] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[LookupAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LookupAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [LookupId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [RangeSize] [decimal](28, 6) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_LookupAudit] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[LookupValue]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LookupValue] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [LookupId] [int] NOT NULL,
  [Key] [nvarchar](max) NOT NULL,
  [KeyHash] [int] NOT NULL,
  [RangeValue] [decimal](28, 6) NULL,
  [Value] [nvarchar](max) NOT NULL,
  [ValueLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [LookupHash] [int] NOT NULL,
  CONSTRAINT [PK_LookupValue] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[LookupValueAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LookupValueAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [LookupValueId] [int] NOT NULL,
  [Key] [nvarchar](max) NOT NULL,
  [KeyHash] [int] NOT NULL,
  [RangeValue] [decimal](28, 6) NULL,
  [Value] [nvarchar](max) NOT NULL,
  [ValueLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [LookupHash] [int] NOT NULL,
  CONSTRAINT [PK_LookupValueAudit] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[NationalCaseChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[NationalCaseChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [UserId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CancellationType] [int] NOT NULL,
  [CancellationId] [int] NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Reason] [nvarchar](max) NOT NULL,
  [ValidationCaseName] [nvarchar](128) NULL,
  [Forecast] [nvarchar](128) NULL,
  CONSTRAINT [PK_CaseChange.NationalCaseChangeId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[NationalCaseDocument]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[NationalCaseDocument] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseValueId] [int] NOT NULL,
  [Name] [nvarchar](256) NOT NULL,
  [Content] [nvarchar](max) NOT NULL,
  [ContentType] [nvarchar](128) NOT NULL,
  CONSTRAINT [PK_NationalCaseDocument] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[NationalCaseValue]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[NationalCaseValue] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [DivisionId] [int] NULL,
  [CaseName] [nvarchar](128) NOT NULL,
  [CaseNameLocalizations] [nvarchar](max) NULL,
  [CaseFieldName] [nvarchar](128) NOT NULL,
  [CaseFieldNameLocalizations] [nvarchar](max) NULL,
  [CaseSlot] [nvarchar](128) NULL,
  [CaseSlotLocalizations] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [Value] [nvarchar](max) NOT NULL,
  [NumericValue] [decimal](28, 6) NULL,
  [CaseRelation] [nvarchar](max) NULL,
  [CancellationDate] [datetime2](7) NULL,
  [Start] [datetime2](7) NULL,
  [End] [datetime2](7) NULL,
  [Forecast] [nvarchar](128) NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_NationalCaseValue] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[NationalCaseValueChange]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[NationalCaseValueChange] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [CaseChangeId] [int] NOT NULL,
  [CaseValueId] [int] NOT NULL,
  CONSTRAINT [PK_NationalCaseValueChange] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Payroll]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Payroll] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [DivisionId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [ClusterSetCase] [nvarchar](128) NULL,
  [ClusterSetCaseField] [nvarchar](128) NULL,
  [ClusterSetCollector] [nvarchar](128) NULL,
  [ClusterSetCollectorRetro] [nvarchar](128) NULL,
  [ClusterSetWageType] [nvarchar](128) NULL,
  [ClusterSetWageTypeRetro] [nvarchar](128) NULL,
  [ClusterSetCaseValue] [nvarchar](128) NULL,
  [ClusterSetWageTypePeriod] [nvarchar](128) NULL,
  [ClusterSetWageTypeLookup] [nvarchar](128) NULL,
  [ClusterSets] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Payroll] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PayrollResult]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PayrollResult] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [PayrollId] [int] NOT NULL,
  [PayrunId] [int] NOT NULL,
  [PayrunJobId] [int] NOT NULL,
  [EmployeeId] [int] NOT NULL,
  [DivisionId] [int] NOT NULL,
  [CycleName] [nvarchar](128) NOT NULL,
  [CycleStart] [datetime2](7) NOT NULL,
  [CycleEnd] [datetime2](7) NOT NULL,
  [PeriodName] [nvarchar](128) NOT NULL,
  [PeriodStart] [datetime2](7) NOT NULL,
  [PeriodEnd] [datetime2](7) NOT NULL,
  CONSTRAINT [PK_PayrollResult.PayrollResultId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Payrun]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Payrun] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [PayrollId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [DefaultReason] [nvarchar](max) NULL,
  [DefaultReasonLocalizations] [nvarchar](max) NULL,
  [StartExpression] [nvarchar](max) NULL,
  [EmployeeAvailableExpression] [nvarchar](max) NULL,
  [EmployeeStartExpression] [nvarchar](max) NULL,
  [EmployeeEndExpression] [nvarchar](max) NULL,
  [WageTypeAvailableExpression] [nvarchar](max) NULL,
  [EndExpression] [nvarchar](max) NULL,
  [RetroTimeType] [int] NOT NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  CONSTRAINT [PK_Payrun.PayrunId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PayrunJob]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PayrunJob] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [PayrunId] [int] NOT NULL,
  [PayrollId] [int] NOT NULL,
  [DivisionId] [int] NOT NULL,
  [ParentJobId] [int] NULL,
  [CreatedUserId] [int] NOT NULL,
  [ReleasedUserId] [int] NULL,
  [ProcessedUserId] [int] NULL,
  [FinishedUserId] [int] NULL,
  [RetroPayMode] [int] NOT NULL,
  [JobStatus] [int] NOT NULL,
  [JobResult] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [Owner] [nvarchar](128) NULL,
  [Forecast] [nvarchar](128) NULL,
  [CycleName] [nvarchar](128) NOT NULL,
  [CycleStart] [datetime2](7) NOT NULL,
  [CycleEnd] [datetime2](7) NOT NULL,
  [PeriodName] [nvarchar](128) NOT NULL,
  [PeriodStart] [datetime2](7) NOT NULL,
  [PeriodEnd] [datetime2](7) NOT NULL,
  [EvaluationDate] [datetime2](7) NOT NULL,
  [Released] [datetime2](7) NULL,
  [Processed] [datetime2](7) NULL,
  [Finished] [datetime2](7) NULL,
  [CreatedReason] [nvarchar](max) NOT NULL,
  [ReleasedReason] [nvarchar](max) NULL,
  [ProcessedReason] [nvarchar](max) NULL,
  [FinishedReason] [nvarchar](max) NULL,
  [TotalEmployeeCount] [int] NOT NULL,
  [ProcessedEmployeeCount] [int] NOT NULL,
  [JobStart] [datetime2](7) NOT NULL,
  [JobEnd] [datetime2](7) NULL,
  [Message] [nvarchar](max) NULL,
  [ErrorMessage] [nvarchar](max) NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_PayrunJob] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PayrunJobEmployee]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PayrunJobEmployee] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [PayrunJobId] [int] NOT NULL,
  [EmployeeId] [int] NOT NULL,
  CONSTRAINT [PK_PayrunJobEmployee] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PayrunParameter]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PayrunParameter] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [PayrunId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [Mandatory] [bit] NOT NULL,
  [Value] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_PayrunParameter] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PayrunResult]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PayrunResult] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [PayrollResultId] [int] NOT NULL,
  [Source] [nvarchar](128) NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Slot] [nvarchar](128) NULL,
  [ValueType] [int] NOT NULL,
  [Value] [nvarchar](max) NULL,
  [NumericValue] [decimal](28, 6) NULL,
  [Start] [datetime2](7) NULL,
  [StartHash] [int] NOT NULL,
  [End] [datetime2](7) NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_PayrunResult] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PayrunTrace]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PayrunTrace] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [PayrollResultId] [int] NOT NULL,
  [Level] [int] NOT NULL,
  [Text] [nvarchar](max) NOT NULL,
  CONSTRAINT [PK_PayrunTrace] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[RegulationShare]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RegulationShare] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [ProviderTenantId] [int] NOT NULL,
  [ProviderRegulationId] [int] NOT NULL,
  [ConsumerTenantId] [int] NOT NULL,
  [ConsumerDivisionId] [int] NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_RegulationShare] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Report]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Report] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [RegulationId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [Category] [nvarchar](128) NULL,
  [Queries] [nvarchar](max) NULL,
  [Relations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [AttributeMode] [int] NOT NULL,
  [BuildExpression] [nvarchar](max) NULL,
  [StartExpression] [nvarchar](max) NULL,
  [EndExpression] [nvarchar](max) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_Report] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ReportAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReportAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [ReportId] [int] NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [Category] [nvarchar](128) NULL,
  [Queries] [nvarchar](max) NULL,
  [Relations] [nvarchar](max) NULL,
  [AttributeMode] [int] NOT NULL,
  [OverrideType] [int] NOT NULL,
  [BuildExpression] [nvarchar](max) NULL,
  [StartExpression] [nvarchar](max) NULL,
  [EndExpression] [nvarchar](max) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_ReportAudit] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ReportLog]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReportLog] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [ReportName] [nvarchar](128) NOT NULL,
  [ReportDate] [datetime2](7) NOT NULL,
  [Message] [nvarchar](max) NULL,
  [Key] [nvarchar](128) NULL,
  [User] [nvarchar](128) NOT NULL,
  CONSTRAINT [PK_ReportLog] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ReportParameter]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReportParameter] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [ReportId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [Mandatory] [bit] NOT NULL,
  [Hidden] [bit] NOT NULL,
  [Value] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [ParameterType] [int] NOT NULL,
  [OverrideType] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_ReportParameter] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ReportParameterAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReportParameterAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [ReportParameterId] [int] NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [Mandatory] [bit] NOT NULL,
  [Hidden] [bit] NOT NULL,
  [Value] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [ParameterType] [int] NOT NULL,
  [OverrideType] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_ReportParameterAudit] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ReportTemplate]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReportTemplate] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [ReportId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [Culture] [nvarchar](128) NOT NULL,
  [Content] [nvarchar](max) NOT NULL,
  [ContentType] [nvarchar](128) NULL,
  [Schema] [nvarchar](max) NULL,
  [Resource] [nvarchar](256) NULL,
  [OverrideType] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_ReportTemplate] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ReportTemplateAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ReportTemplateAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [ReportTemplateId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [Culture] [nvarchar](128) NOT NULL,
  [Content] [nvarchar](max) NOT NULL,
  [ContentType] [nvarchar](128) NULL,
  [Schema] [nvarchar](max) NULL,
  [Resource] [nvarchar](256) NULL,
  [OverrideType] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_ReportTemplateAudit] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Script]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Script] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [RegulationId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [FunctionTypeMask] [bigint] NOT NULL,
  [Value] [nvarchar](max) NOT NULL,
  [OverrideType] [int] NOT NULL,
  CONSTRAINT [PK_Script.ScriptId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ScriptAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ScriptAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [ScriptId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [FunctionTypeMask] [bigint] NOT NULL,
  [Value] [nvarchar](max) NOT NULL,
  [OverrideType] [int] NOT NULL,
  CONSTRAINT [PK_ScriptAudit.ScriptAuditId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Task]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Task] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [Category] [nvarchar](128) NULL,
  [Instruction] [nvarchar](max) NOT NULL,
  [ScheduledUserId] [int] NOT NULL,
  [Scheduled] [datetime2](7) NOT NULL,
  [CompletedUserId] [int] NULL,
  [Completed] [datetime2](7) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Task] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Tenant]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Tenant] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [Identifier] [nvarchar](128) NOT NULL,
  [Culture] [nvarchar](128) NULL,
  [Calendar] [nvarchar](128) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Tenant.TenantId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[User]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[User] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Identifier] [nvarchar](128) NOT NULL,
  [UserType] [int] NOT NULL,
  [Password] [nvarchar](128) NULL,
  [StoredSalt] [varbinary](max) NULL,
  [FirstName] [nvarchar](128) NOT NULL,
  [LastName] [nvarchar](128) NOT NULL,
  [Culture] [nvarchar](128) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_User.UserId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Version]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Version] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [MajorVersion] [int] NOT NULL,
  [MinorVersion] [int] NOT NULL,
  [SubVersion] [int] NOT NULL,
  [Owner] [nvarchar](128) NOT NULL,
  [Description] [nvarchar](max) NOT NULL,
  CONSTRAINT [PK_Version] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[WageType]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WageType] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [RegulationId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [WageTypeNumber] [decimal](28, 6) NOT NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [ValueType] [int] NOT NULL,
  [Calendar] [nvarchar](128) NULL,
  [Collectors] [nvarchar](max) NULL,
  [CollectorGroups] [nvarchar](max) NULL,
  [ValueExpression] [nvarchar](max) NULL,
  [ResultExpression] [nvarchar](max) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_WageType.WageTypeId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[WageTypeAudit]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WageTypeAudit] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [WageTypeId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [NameLocalizations] [nvarchar](max) NULL,
  [WageTypeNumber] [decimal](28, 6) NOT NULL,
  [Description] [nvarchar](max) NULL,
  [DescriptionLocalizations] [nvarchar](max) NULL,
  [OverrideType] [int] NOT NULL,
  [ValueType] [int] NOT NULL,
  [Calendar] [nvarchar](128) NULL,
  [Collectors] [nvarchar](max) NULL,
  [CollectorGroups] [nvarchar](max) NULL,
  [ValueExpression] [nvarchar](max) NULL,
  [ResultExpression] [nvarchar](max) NULL,
  [Script] [nvarchar](max) NULL,
  [ScriptVersion] [nvarchar](128) NULL,
  [Binary] [varbinary](max) NULL,
  [ScriptHash] [int] NULL,
  [Attributes] [nvarchar](max) NULL,
  [Clusters] [nvarchar](max) NULL,
  CONSTRAINT [PK_WageTypeAudit.WageTypeAuditId] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[WageTypeCustomResult]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WageTypeCustomResult] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [WageTypeResultId] [int] NOT NULL,
  [WageTypeNumber] [decimal](28, 6) NOT NULL,
  [WageTypeName] [nvarchar](128) NOT NULL,
  [WageTypeNameLocalizations] [nvarchar](max) NULL,
  [Source] [nvarchar](128) NOT NULL,
  [ValueType] [int] NOT NULL,
  [Value] [decimal](28, 6) NOT NULL,
  [Start] [datetime2](7) NOT NULL,
  [StartHash] [int] NOT NULL,
  [End] [datetime2](7) NOT NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_WageTypeCustomResult] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[WageTypeResult]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WageTypeResult] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [PayrollResultId] [int] NOT NULL,
  [WageTypeId] [int] NOT NULL,
  [WageTypeNumber] [decimal](28, 6) NOT NULL,
  [WageTypeName] [nvarchar](128) NOT NULL,
  [WageTypeNameLocalizations] [nvarchar](max) NULL,
  [ValueType] [int] NOT NULL,
  [Value] [decimal](28, 6) NOT NULL,
  [Start] [datetime2](7) NOT NULL,
  [StartHash] [int] NOT NULL,
  [End] [datetime2](7) NOT NULL,
  [Tags] [nvarchar](max) NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_WageTypeResult] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Webhook]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Webhook] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [TenantId] [int] NOT NULL,
  [Name] [nvarchar](128) NOT NULL,
  [ReceiverAddress] [nvarchar](128) NOT NULL,
  [Action] [int] NOT NULL,
  [Attributes] [nvarchar](max) NULL,
  CONSTRAINT [PK_Webhook] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[WebhookMessage]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WebhookMessage] (
  [Id] [int] IDENTITY(1, 1) NOT NULL,
  [Status] [int] NOT NULL,
  [Created] [datetime2](7) NOT NULL,
  [Updated] [datetime2](7) NOT NULL,
  [WebhookId] [int] NOT NULL,
  [ActionName] [nvarchar](128) NOT NULL,
  [ReceiverAddress] [nvarchar](128) NOT NULL,
  [RequestDate] [datetime2](7) NOT NULL,
  [RequestMessage] [nvarchar](max) NULL,
  [RequestOperation] [nvarchar](max) NULL,
  [ResponseDate] [datetime2](7) NULL,
  [ResponseStatus] [int] NULL,
  [ResponseMessage] [nvarchar](max) NULL,
  CONSTRAINT [PK_WebhookMessage] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (
    PAD_INDEX = OFF,
    STATISTICS_NORECOMPUTE = OFF,
    IGNORE_DUP_KEY = OFF,
    ALLOW_ROW_LOCKS = ON,
    ALLOW_PAGE_LOCKS = ON
    )
  ON [PRIMARY]
  ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Calendar.UniqueCalendarPerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Calendar.UniqueCalendarPerTenant] ON [dbo].[Calendar] (
  [Name] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Case.UniqueNamePerRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Case.UniqueNamePerRegulation] ON [dbo].[Case] (
  [RegulationId] ASC,
  [Name] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_CaseField.UniqueNamePerCase]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_CaseField.UniqueNamePerCase] ON [dbo].[CaseField] (
  [Name] ASC,
  [CaseId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_CaseField.ValueType]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CaseField.ValueType] ON [dbo].[CaseField] ([ValueType] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_CaseRelation.SourceCaseName]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CaseRelation.SourceCaseName] ON [dbo].[CaseRelation] ([SourceCaseName] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_CaseRelation.TargetCaseName]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CaseRelation.TargetCaseName] ON [dbo].[CaseRelation] ([TargetCaseName] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_CaseRelation.TargetSlot]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CaseRelation.TargetSlot] ON [dbo].[CaseRelation] ([TargetCaseSlot] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_CaseRelation.UniqueRelationInRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_CaseRelation.UniqueRelationInRegulation] ON [dbo].[CaseRelation] (
  [RegulationId] ASC,
  [RelationHash] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_Collector.CollectMode]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_Collector.CollectMode] ON [dbo].[Collector] ([CollectMode] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Collector.UniqueNamePerRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Collector.UniqueNamePerRegulation] ON [dbo].[Collector] (
  [Name] ASC,
  [RegulationId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_CollectorCustomResult.CollectorNameHash]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CollectorCustomResult.CollectorNameHash] ON [dbo].[CollectorCustomResult] ([CollectorNameHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_CollectorCustomResult.StartHash]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CollectorCustomResult.StartHash] ON [dbo].[CollectorCustomResult] ([StartHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_CollectorResult.CollectorNameHash]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CollectorResult.CollectorNameHash] ON [dbo].[CollectorResult] ([CollectorNameHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_CollectorResult.StartHash]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CollectorResult.StartHash] ON [dbo].[CollectorResult] ([StartHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_CompanyCaseValue.CaseFieldName]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CompanyCaseValue.CaseFieldName] ON [dbo].[CompanyCaseValue] ([CaseFieldName] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_CompanyCaseValue.Slot]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_CompanyCaseValue.Slot] ON [dbo].[CompanyCaseValue] ([CaseSlot] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_CompanyCaseValue.UniqueCompanyCaseValuePerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_CompanyCaseValue.UniqueCompanyCaseValuePerTenant] ON [dbo].[CompanyCaseValue] (
  [TenantId] ASC,
  [DivisionId] ASC,
  [CaseFieldName] ASC,
  [CaseSlot] ASC,
  [Created] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_CompanyCaseValueChange.UniqueValuePerChange]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_CompanyCaseValueChange.UniqueValuePerChange] ON [dbo].[CompanyCaseValueChange] (
  [CaseValueId] ASC,
  [CaseChangeId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Division.UniqueNamePerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Division.UniqueNamePerTenant] ON [dbo].[Division] (
  [Name] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Employee.UniqueIdentifierPerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Employee.UniqueIdentifierPerTenant] ON [dbo].[Employee] (
  [Identifier] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_EmployeeCaseValue.CaseFieldName]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_EmployeeCaseValue.CaseFieldName] ON [dbo].[EmployeeCaseValue] ([CaseFieldName] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_EmployeeCaseValue.Slot]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_EmployeeCaseValue.Slot] ON [dbo].[EmployeeCaseValue] ([CaseSlot] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_EmployeeCaseValue.UniqueCaseValuePerEmployee]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_EmployeeCaseValue.UniqueCaseValuePerEmployee] ON [dbo].[EmployeeCaseValue] (
  [EmployeeId] ASC,
  [DivisionId] ASC,
  [CaseFieldName] ASC,
  [CaseSlot] ASC,
  [Created] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_EmployeeCaseValueChange.UniqueValuePerChange]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_EmployeeCaseValueChange.UniqueValuePerChange] ON [dbo].[EmployeeCaseValueChange] (
  [CaseValueId] ASC,
  [CaseChangeId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_EmployeeDivision.UniqueEmployeePerDivision]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_EmployeeDivision.UniqueEmployeePerDivision] ON [dbo].[EmployeeDivision] (
  [EmployeeId] ASC,
  [DivisionId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_GlobalCaseValue.CaseFieldName]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_GlobalCaseValue.CaseFieldName] ON [dbo].[GlobalCaseValue] ([CaseFieldName] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_GlobalCaseValue.Slot]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_GlobalCaseValue.Slot] ON [dbo].[GlobalCaseValue] ([CaseSlot] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_GlobalCaseValue.UniqueGlobalValuePerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_GlobalCaseValue.UniqueGlobalValuePerTenant] ON [dbo].[GlobalCaseValue] (
  [TenantId] ASC,
  [DivisionId] ASC,
  [CaseFieldName] ASC,
  [CaseSlot] ASC,
  [Created] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_GlobalCaseValueChange.UniqueValuePerChange]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_GlobalCaseValueChange.UniqueValuePerChange] ON [dbo].[GlobalCaseValueChange] (
  [CaseValueId] ASC,
  [CaseChangeId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Lookup.UniqueNamePerRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Lookup.UniqueNamePerRegulation] ON [dbo].[Lookup] (
  [Name] ASC,
  [RegulationId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_LookupValue.Key]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_LookupValue.Key] ON [dbo].[LookupValue] ([KeyHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_LookupValue.UniqueValueKeyPerLookup]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_LookupValue.UniqueValueKeyPerLookup] ON [dbo].[LookupValue] (
  [LookupHash] ASC,
  [LookupId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_NationalCaseValue.CaseFieldName]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_NationalCaseValue.CaseFieldName] ON [dbo].[NationalCaseValue] ([CaseFieldName] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_NationalCaseValue.Slot]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_NationalCaseValue.Slot] ON [dbo].[NationalCaseValue] ([CaseSlot] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_NationalCaseValue.UniqueNationalValuePerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_NationalCaseValue.UniqueNationalValuePerTenant] ON [dbo].[NationalCaseValue] (
  [TenantId] ASC,
  [DivisionId] ASC,
  [CaseFieldName] ASC,
  [CaseSlot] ASC,
  [Created] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_NationalCaseValueChange.UniqueValuePerChange]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_NationalCaseValueChange.UniqueValuePerChange] ON [dbo].[NationalCaseValueChange] (
  [CaseValueId] ASC,
  [CaseChangeId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Payroll.UniqueNamePerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Payroll.UniqueNamePerTenant] ON [dbo].[Payroll] (
  [Name] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Regulation.UniqueNamePerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Regulation.UniqueNamePerTenant] ON [dbo].[Payroll] (
  [Name] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrollLayer.Priority]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_PayrollLayer.Priority] ON [dbo].[PayrollLayer] ([Priority] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrollLayer.UniqueLevelAndPriorityPerPayroll]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_PayrollLayer.UniqueLevelAndPriorityPerPayroll] ON [dbo].[PayrollLayer] (
  [Level] ASC,
  [Priority] ASC,
  [PayrollId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_PayrollLayer.UniqueNamePerPayrollLayer]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_PayrollLayer.UniqueNamePerPayrollLayer] ON [dbo].[PayrollLayer] (
  [RegulationName] ASC,
  [PayrollId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrollResult.PayrunId]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_PayrollResult.PayrunId] ON [dbo].[PayrollResult] ([PayrunId] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrollResult.UniqueEmployeePerPayrunJob]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_PayrollResult.UniqueEmployeePerPayrunJob] ON [dbo].[PayrollResult] (
  [EmployeeId] ASC,
  [PayrunJobId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Payrun.UniqueNamePerPayroll]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Payrun.UniqueNamePerPayroll] ON [dbo].[Payrun] (
  [Name] ASC,
  [PayrollId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrunJob.JobStatus]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_PayrunJob.JobStatus] ON [dbo].[PayrunJob] ([JobStatus] DESC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrunJob.ParentJob]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_PayrunJob.ParentJob] ON [dbo].[PayrunJob] ([ParentJobId] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrunJob.PeriodStart]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_PayrunJob.PeriodStart] ON [dbo].[PayrunJob] ([PeriodStart] DESC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrunJobEmployee.UniqueEmployeePerPayrunJob]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_PayrunJobEmployee.UniqueEmployeePerPayrunJob] ON [dbo].[PayrunJobEmployee] (
  [EmployeeId] ASC,
  [PayrunJobId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_PayrunParameter.UniqueNamePerPayrun]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_PayrunParameter.UniqueNamePerPayrun] ON [dbo].[PayrunParameter] (
  [Name] ASC,
  [Id] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_PayrunResult.Name]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_PayrunResult.Name] ON [dbo].[PayrunResult] ([Name] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_PayrunResult.StartHash]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_PayrunResult.StartHash] ON [dbo].[PayrunResult] ([StartHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Regulation.UniqueValidFromeRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Regulation.UniqueValidFromeRegulation] ON [dbo].[Regulation] (
  [Name] ASC,
  [ValidFrom] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_RegulationShare.UniqueRegulationShare]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_RegulationShare.UniqueRegulationShare] ON [dbo].[RegulationShare] (
  [ProviderTenantId] ASC,
  [ProviderRegulationId] ASC,
  [ConsumerTenantId] ASC,
  [ConsumerDivisionId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Report.Category]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_Report.Category] ON [dbo].[Report] ([Category] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Report.UniqueNamePerRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Report.UniqueNamePerRegulation] ON [dbo].[Report] (
  [Name] ASC,
  [RegulationId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_ReportParameter.UniqueNamePerReport]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_ReportParameter.UniqueNamePerReport] ON [dbo].[ReportParameter] (
  [Name] ASC,
  [ReportId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_ReportTemplate.UniqueLanguagePerReport]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_ReportTemplate.UniqueLanguagePerReport] ON [dbo].[ReportTemplate] (
  [ReportId] ASC,
  [Culture] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_ReportTemplate.UniqueTemplatePerPeport]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_ReportTemplate.UniqueTemplatePerPeport] ON [dbo].[ReportTemplate] (
  [Name] ASC,
  [Id] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_Script.FunctionType]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_Script.FunctionType] ON [dbo].[Script] ([FunctionTypeMask] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Script.UniqueNamePerRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Script.UniqueNamePerRegulation] ON [dbo].[Script] (
  [Name] ASC,
  [RegulationId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Tenant.UniqueIdentifier]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Tenant.UniqueIdentifier] ON [dbo].[Tenant] ([Identifier] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_User.UnqiueIdentifierPerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_User.UnqiueIdentifierPerTenant] ON [dbo].[User] (
  [Identifier] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_WageType.UniqueNamePerRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_WageType.UniqueNamePerRegulation] ON [dbo].[WageType] (
  [RegulationId] ASC,
  [Name] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_WageType.UniqueNumberPerRegulation]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_WageType.UniqueNumberPerRegulation] ON [dbo].[WageType] (
  [RegulationId] ASC,
  [WageTypeNumber] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_WageType.WageTypeNumber]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_WageType.WageTypeNumber] ON [dbo].[WageType] ([WageTypeNumber] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_WageTypeCustomResult.StartHash]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_WageTypeCustomResult.StartHash] ON [dbo].[WageTypeCustomResult] ([StartHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_WageTypeCustomResult.WageTypeNumber]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_WageTypeCustomResult.WageTypeNumber] ON [dbo].[WageTypeCustomResult] ([WageTypeNumber] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_WageTypeResult.StartHash]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_WageTypeResult.StartHash] ON [dbo].[WageTypeResult] ([StartHash] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

/****** Object:  Index [IX_WageTypeResult.WageTypeNumber]]    Script Date: 17.07.2023 15:01:36 ******/
CREATE NONCLUSTERED INDEX [IX_WageTypeResult.WageTypeNumber]]] ON [dbo].[WageTypeResult] ([WageTypeNumber] ASC)
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_Webhook.UniqueNamePerTenant]    Script Date: 17.07.2023 15:01:36 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Webhook.UniqueNamePerTenant] ON [dbo].[Webhook] (
  [Name] ASC,
  [TenantId] ASC
  )
  WITH (
      PAD_INDEX = OFF,
      STATISTICS_NORECOMPUTE = OFF,
      SORT_IN_TEMPDB = OFF,
      IGNORE_DUP_KEY = OFF,
      DROP_EXISTING = OFF,
      ONLINE = OFF,
      ALLOW_ROW_LOCKS = ON,
      ALLOW_PAGE_LOCKS = ON
      ) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Calendar] ADD CONSTRAINT [DF_Calendar_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Calendar] ADD CONSTRAINT [DF_Calendar_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Calendar] ADD CONSTRAINT [DF_Calendar_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Case] ADD CONSTRAINT [DF_Case_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Case] ADD CONSTRAINT [DF_Case_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Case] ADD CONSTRAINT [DF_Case_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CaseAudit] ADD CONSTRAINT [DF_CaseAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CaseAudit] ADD CONSTRAINT [DF_CaseAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CaseAudit] ADD CONSTRAINT [DF_CaseAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CaseField] ADD CONSTRAINT [DF_CaseField_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CaseField] ADD CONSTRAINT [DF_CaseField_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CaseField] ADD CONSTRAINT [DF_CaseField_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CaseFieldAudit] ADD CONSTRAINT [DF_CaseFieldAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CaseFieldAudit] ADD CONSTRAINT [DF_CaseFieldAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CaseFieldAudit] ADD CONSTRAINT [DF_CaseFieldAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CaseRelation] ADD CONSTRAINT [DF_CaseRelation_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CaseRelation] ADD CONSTRAINT [DF_CaseRelation_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CaseRelation] ADD CONSTRAINT [DF_CaseRelation_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CaseRelationAudit] ADD CONSTRAINT [DF_CaseRelationAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CaseRelationAudit] ADD CONSTRAINT [DF_CaseRelationAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CaseRelationAudit] ADD CONSTRAINT [DF_CaseRelationAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Collector] ADD CONSTRAINT [DF_Collector_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Collector] ADD CONSTRAINT [DF_Collector_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Collector] ADD CONSTRAINT [DF_Collector_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CollectorAudit] ADD CONSTRAINT [DF_CollectorAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CollectorAudit] ADD CONSTRAINT [DF_CollectorAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CollectorAudit] ADD CONSTRAINT [DF_CollectorAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CollectorCustomResult] ADD CONSTRAINT [DF_CollectorCustomResult_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CollectorCustomResult] ADD CONSTRAINT [DF_CollectorCustomResult_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CollectorCustomResult] ADD CONSTRAINT [DF_CollectorCustomResult_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CollectorResult] ADD CONSTRAINT [DF_CollectorResult_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CollectorResult] ADD CONSTRAINT [DF_CollectorResult_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CollectorResult] ADD CONSTRAINT [DF_CollectorResult_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CompanyCaseChange] ADD CONSTRAINT [DF_CompanyCaseChange_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CompanyCaseChange] ADD CONSTRAINT [DF_CompanyCaseChange_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CompanyCaseChange] ADD CONSTRAINT [DF_CompanyCaseChange_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CompanyCaseDocument] ADD CONSTRAINT [DF_CompanyCaseDocument_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CompanyCaseDocument] ADD CONSTRAINT [DF_CompanyCaseDocument_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CompanyCaseDocument] ADD CONSTRAINT [DF_CompanyCaseDocument_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CompanyCaseValue] ADD CONSTRAINT [DF_CompanyCaseValue2_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CompanyCaseValue] ADD CONSTRAINT [DF_CompanyCaseValue2_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CompanyCaseValue] ADD CONSTRAINT [DF_CompanyCaseValue2_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[CompanyCaseValueChange] ADD CONSTRAINT [DF_CompanyCaseChangeAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[CompanyCaseValueChange] ADD CONSTRAINT [DF_CompanyCaseChangeAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[CompanyCaseValueChange] ADD CONSTRAINT [DF_CompanyCaseChangeAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Division] ADD CONSTRAINT [DF_Division_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Division] ADD CONSTRAINT [DF_Division_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Division] ADD CONSTRAINT [DF_Division_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Employee] ADD CONSTRAINT [DF_Employee_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Employee] ADD CONSTRAINT [DF_Employee_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Employee] ADD CONSTRAINT [DF_Employee_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[EmployeeCaseChange] ADD CONSTRAINT [DF_EmployeeCaseChange_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[EmployeeCaseChange] ADD CONSTRAINT [DF_EmployeeCaseChange_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[EmployeeCaseChange] ADD CONSTRAINT [DF_EmployeeCaseChange_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[EmployeeCaseDocument] ADD CONSTRAINT [DF_EmployeeCaseDocument_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[EmployeeCaseDocument] ADD CONSTRAINT [DF_EmployeeCaseDocument_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[EmployeeCaseDocument] ADD CONSTRAINT [DF_EmployeeCaseDocument_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[EmployeeCaseValue] ADD CONSTRAINT [DF_EmployeeCaseValue_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[EmployeeCaseValue] ADD CONSTRAINT [DF_EmployeeCaseValue_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[EmployeeCaseValue] ADD CONSTRAINT [DF_EmployeeCaseValue_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[EmployeeCaseValueChange] ADD CONSTRAINT [DF_EmployeeCaseCangeAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[EmployeeCaseValueChange] ADD CONSTRAINT [DF_EmployeeCaseCangeAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[EmployeeCaseValueChange] ADD CONSTRAINT [DF_EmployeeCaseCangeAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[EmployeeDivision] ADD CONSTRAINT [DF_EmployeeDivision_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[EmployeeDivision] ADD CONSTRAINT [DF_EmployeeDivision_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[EmployeeDivision] ADD CONSTRAINT [DF_EmployeeDivision_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[GlobalCaseChange] ADD CONSTRAINT [DF_GlobalCaseChange_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[GlobalCaseChange] ADD CONSTRAINT [DF_GlobalCaseChange_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[GlobalCaseChange] ADD CONSTRAINT [DF_GlobalCaseChange_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[GlobalCaseDocument] ADD CONSTRAINT [DF_GlobalCaseDocument_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[GlobalCaseDocument] ADD CONSTRAINT [DF_GlobalCaseDocument_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[GlobalCaseDocument] ADD CONSTRAINT [DF_GlobalCaseDocument_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[GlobalCaseValue] ADD CONSTRAINT [DF_GlobalCaseValue_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[GlobalCaseValue] ADD CONSTRAINT [DF_GlobalCaseValue_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[GlobalCaseValue] ADD CONSTRAINT [DF_GlobalCaseValue_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[GlobalCaseValueChange] ADD CONSTRAINT [DF_GlobalCaseValueChange_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[GlobalCaseValueChange] ADD CONSTRAINT [DF_GlobalCaseValueChange_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[GlobalCaseValueChange] ADD CONSTRAINT [DF_GlobalCaseValueChange_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Log] ADD CONSTRAINT [DF_Log_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Log] ADD CONSTRAINT [DF_Log_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Log] ADD CONSTRAINT [DF_Log_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Lookup] ADD CONSTRAINT [DF_Lookup_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Lookup] ADD CONSTRAINT [DF_Lookup_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Lookup] ADD CONSTRAINT [DF_Lookup_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[LookupAudit] ADD CONSTRAINT [DF_LookupAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[LookupAudit] ADD CONSTRAINT [DF_LookupAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[LookupAudit] ADD CONSTRAINT [DF_LookupAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[LookupValue] ADD CONSTRAINT [DF_LookupRow_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[LookupValue] ADD CONSTRAINT [DF_LookupRow_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[LookupValue] ADD CONSTRAINT [DF_LookupRow_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[LookupValueAudit] ADD CONSTRAINT [DF_LookupValueAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[LookupValueAudit] ADD CONSTRAINT [DF_LookupValueAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[LookupValueAudit] ADD CONSTRAINT [DF_LookupValueAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[NationalCaseChange] ADD CONSTRAINT [DF_CaseChange_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[NationalCaseChange] ADD CONSTRAINT [DF_CaseChange_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[NationalCaseChange] ADD CONSTRAINT [DF_CaseChange_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[NationalCaseDocument] ADD CONSTRAINT [DF_NationalCaseDocument_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[NationalCaseDocument] ADD CONSTRAINT [DF_NationalCaseDocument_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[NationalCaseDocument] ADD CONSTRAINT [DF_NationalCaseDocument_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[NationalCaseValue] ADD CONSTRAINT [DF_NationalCaseValue_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[NationalCaseValue] ADD CONSTRAINT [DF_NationalCaseValue_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[NationalCaseValue] ADD CONSTRAINT [DF_NationalCaseValue_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[NationalCaseValueChange] ADD CONSTRAINT [DF_CaseChangeAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[NationalCaseValueChange] ADD CONSTRAINT [DF_CaseChangeAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[NationalCaseValueChange] ADD CONSTRAINT [DF_CaseChangeAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Payroll] ADD CONSTRAINT [DF_Payroll_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Payroll] ADD CONSTRAINT [DF_Payroll_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Payroll] ADD CONSTRAINT [DF_Payroll_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[PayrollLayer] ADD CONSTRAINT [DF_PayrollLayer_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[PayrollLayer] ADD CONSTRAINT [DF_PayrollLayer_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[PayrollLayer] ADD CONSTRAINT [DF_PayrollLayer_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[PayrollResult] ADD CONSTRAINT [DF_PayrunResult_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[PayrollResult] ADD CONSTRAINT [DF_PayrunResult_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[PayrollResult] ADD CONSTRAINT [DF_PayrunResult_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Payrun] ADD CONSTRAINT [DF_Payrun_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Payrun] ADD CONSTRAINT [DF_Payrun_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Payrun] ADD CONSTRAINT [DF_Payrun_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[PayrunJob] ADD CONSTRAINT [DF_PayrunJob_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[PayrunJob] ADD CONSTRAINT [DF_PayrunJob_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[PayrunJob] ADD CONSTRAINT [DF_PayrunJob_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[PayrunJobEmployee] ADD CONSTRAINT [DF_PayrunJobEmployee_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[PayrunJobEmployee] ADD CONSTRAINT [DF_PayrunJobEmployee_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[PayrunJobEmployee] ADD CONSTRAINT [DF_PayrunJobEmployee_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[PayrunParameter] ADD CONSTRAINT [DF_PayrunParameter_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[PayrunParameter] ADD CONSTRAINT [DF_PayrunParameter_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[PayrunParameter] ADD CONSTRAINT [DF_PayrunParameter_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[PayrunResult] ADD CONSTRAINT [DF_PayrunResult_Status_1] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[PayrunResult] ADD CONSTRAINT [DF_PayrunResult_Created_1] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[PayrunResult] ADD CONSTRAINT [DF_PayrunResult_Updated_1] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[PayrunTrace] ADD CONSTRAINT [DF_PayrunTrace_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[PayrunTrace] ADD CONSTRAINT [DF_PayrunTrace_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[PayrunTrace] ADD CONSTRAINT [DF_PayrunTrace_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Regulation] ADD CONSTRAINT [DF_Regulation_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Regulation] ADD CONSTRAINT [DF_Regulation_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Regulation] ADD CONSTRAINT [DF_Regulation_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[RegulationShare] ADD CONSTRAINT [DF_RegulationPermission_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[RegulationShare] ADD CONSTRAINT [DF_RegulationPermission_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[RegulationShare] ADD CONSTRAINT [DF_RegulationPermission_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Report] ADD CONSTRAINT [DF_PayrollResultReport_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Report] ADD CONSTRAINT [DF_PayrollResultReport_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Report] ADD CONSTRAINT [DF_PayrollResultReport_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[ReportAudit] ADD CONSTRAINT [DF_ReportAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[ReportAudit] ADD CONSTRAINT [DF_ReportAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[ReportAudit] ADD CONSTRAINT [DF_ReportAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[ReportLog] ADD CONSTRAINT [DF_ReportLog_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[ReportLog] ADD CONSTRAINT [DF_ReportLog_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[ReportLog] ADD CONSTRAINT [DF_ReportLog_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[ReportLog] ADD CONSTRAINT [DF_ReportLog_Created1] DEFAULT(getutcdate())
FOR [ReportDate]
GO

ALTER TABLE [dbo].[ReportParameter] ADD CONSTRAINT [DF_ReportParameter_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[ReportParameter] ADD CONSTRAINT [DF_ReportParameter_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[ReportParameter] ADD CONSTRAINT [DF_ReportParameter_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[ReportParameterAudit] ADD CONSTRAINT [DF_ReportParameterAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[ReportParameterAudit] ADD CONSTRAINT [DF_ReportParameterAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[ReportParameterAudit] ADD CONSTRAINT [DF_ReportParameterAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[ReportTemplate] ADD CONSTRAINT [DF_ReportTemplate_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[ReportTemplate] ADD CONSTRAINT [DF_ReportTemplate_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[ReportTemplate] ADD CONSTRAINT [DF_ReportTemplate_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[ReportTemplateAudit] ADD CONSTRAINT [DF_ReportTemplateAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[ReportTemplateAudit] ADD CONSTRAINT [DF_ReportTemplateAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[ReportTemplateAudit] ADD CONSTRAINT [DF_ReportTemplateAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Script] ADD CONSTRAINT [DF_Script_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Script] ADD CONSTRAINT [DF_Script_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Script] ADD CONSTRAINT [DF_Script_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[ScriptAudit] ADD CONSTRAINT [DF_ScriptAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[ScriptAudit] ADD CONSTRAINT [DF_ScriptAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[ScriptAudit] ADD CONSTRAINT [DF_ScriptAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Task] ADD CONSTRAINT [DF_Task_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Task] ADD CONSTRAINT [DF_Task_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Task] ADD CONSTRAINT [DF_Task_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Tenant] ADD CONSTRAINT [DF_Tenant_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Tenant] ADD CONSTRAINT [DF_Tenant_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Tenant] ADD CONSTRAINT [DF_Tenant_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[User] ADD CONSTRAINT [DF_User_STatus] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[User] ADD CONSTRAINT [DF_User_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[User] ADD CONSTRAINT [DF_User_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[User] ADD CONSTRAINT [DF_User_Supervisor] DEFAULT((0))
FOR [UserType]
GO

ALTER TABLE [dbo].[Version] ADD CONSTRAINT [DF_Version_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[WageType] ADD CONSTRAINT [DF_WageType_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[WageType] ADD CONSTRAINT [DF_WageType_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[WageType] ADD CONSTRAINT [DF_WageType_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[WageTypeAudit] ADD CONSTRAINT [DF_WageTypeAudit_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[WageTypeAudit] ADD CONSTRAINT [DF_WageTypeAudit_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[WageTypeAudit] ADD CONSTRAINT [DF_WageTypeAudit_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[WageTypeCustomResult] ADD CONSTRAINT [DF_WageTypeCustomResult_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[WageTypeCustomResult] ADD CONSTRAINT [DF_WageTypeCustomResult_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[WageTypeCustomResult] ADD CONSTRAINT [DF_WageTypeCustomResult_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[WageTypeResult] ADD CONSTRAINT [DF_WageTypeResult_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[WageTypeResult] ADD CONSTRAINT [DF_WageTypeResult_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[WageTypeResult] ADD CONSTRAINT [DF_WageTypeResult_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Webhook] ADD CONSTRAINT [DF_Webhook_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[Webhook] ADD CONSTRAINT [DF_Webhook_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[Webhook] ADD CONSTRAINT [DF_Webhook_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[WebhookMessage] ADD CONSTRAINT [DF_WebhookMessage_Status] DEFAULT((0))
FOR [Status]
GO

ALTER TABLE [dbo].[WebhookMessage] ADD CONSTRAINT [DF_WebhookMessage_Created] DEFAULT(getutcdate())
FOR [Created]
GO

ALTER TABLE [dbo].[WebhookMessage] ADD CONSTRAINT [DF_WebhookMessage_Updated] DEFAULT(getutcdate())
FOR [Updated]
GO

ALTER TABLE [dbo].[Calendar]
  WITH CHECK ADD CONSTRAINT [FK_Calendar_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Calendar] CHECK CONSTRAINT [FK_Calendar_Tenant]
GO

ALTER TABLE [dbo].[Case]
  WITH CHECK ADD CONSTRAINT [FK_Case_Regulation] FOREIGN KEY ([RegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[Case] CHECK CONSTRAINT [FK_Case_Regulation]
GO

ALTER TABLE [dbo].[CaseAudit]
  WITH CHECK ADD CONSTRAINT [FK_Case.CaseAudit_Case] FOREIGN KEY ([CaseId]) REFERENCES [dbo].[Case]([Id])
GO

ALTER TABLE [dbo].[CaseAudit] CHECK CONSTRAINT [FK_Case.CaseAudit_Case]
GO

ALTER TABLE [dbo].[CaseAudit]
  WITH CHECK ADD CONSTRAINT [FK_Case.CaseAudit_CaseChange] FOREIGN KEY ([CaseChangeId]) REFERENCES [dbo].[NationalCaseChange]([Id])
GO

ALTER TABLE [dbo].[CaseAudit] CHECK CONSTRAINT [FK_Case.CaseAudit_CaseChange]
GO

ALTER TABLE [dbo].[CaseField]
  WITH CHECK ADD CONSTRAINT [FK_CaseField_Case] FOREIGN KEY ([CaseId]) REFERENCES [dbo].[Case]([Id])
GO

ALTER TABLE [dbo].[CaseField] CHECK CONSTRAINT [FK_CaseField_Case]
GO

ALTER TABLE [dbo].[CaseFieldAudit]
  WITH CHECK ADD CONSTRAINT [FK_CaseFieldAudit_CaseField] FOREIGN KEY ([CaseFieldId]) REFERENCES [dbo].[CaseField]([Id])
GO

ALTER TABLE [dbo].[CaseFieldAudit] CHECK CONSTRAINT [FK_CaseFieldAudit_CaseField]
GO

ALTER TABLE [dbo].[CaseRelation]
  WITH CHECK ADD CONSTRAINT [FK_CaseRelation_Regulation] FOREIGN KEY ([RegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[CaseRelation] CHECK CONSTRAINT [FK_CaseRelation_Regulation]
GO

ALTER TABLE [dbo].[CaseRelationAudit]
  WITH CHECK ADD CONSTRAINT [FK_CaseRelationAudit_CaseRelation] FOREIGN KEY ([CaseRelationId]) REFERENCES [dbo].[CaseRelation]([Id])
GO

ALTER TABLE [dbo].[CaseRelationAudit] CHECK CONSTRAINT [FK_CaseRelationAudit_CaseRelation]
GO

ALTER TABLE [dbo].[Collector]
  WITH CHECK ADD CONSTRAINT [FK_Collector_Regulation] FOREIGN KEY ([RegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[Collector] CHECK CONSTRAINT [FK_Collector_Regulation]
GO

ALTER TABLE [dbo].[CollectorAudit]
  WITH CHECK ADD CONSTRAINT [FK_Regulation.CollectorAudit_Collector] FOREIGN KEY ([CollectorId]) REFERENCES [dbo].[Collector]([Id])
GO

ALTER TABLE [dbo].[CollectorAudit] CHECK CONSTRAINT [FK_Regulation.CollectorAudit_Collector]
GO

ALTER TABLE [dbo].[CollectorCustomResult]
  WITH CHECK ADD CONSTRAINT [FK_CollectorCustomResult_CollectorResult] FOREIGN KEY ([CollectorResultId]) REFERENCES [dbo].[CollectorResult]([Id])
GO

ALTER TABLE [dbo].[CollectorCustomResult] CHECK CONSTRAINT [FK_CollectorCustomResult_CollectorResult]
GO

ALTER TABLE [dbo].[CollectorResult]
  WITH CHECK ADD CONSTRAINT [FK_CollectorResult_PayrollResult] FOREIGN KEY ([PayrollResultId]) REFERENCES [dbo].[PayrollResult]([Id])
GO

ALTER TABLE [dbo].[CollectorResult] CHECK CONSTRAINT [FK_CollectorResult_PayrollResult]
GO

ALTER TABLE [dbo].[CompanyCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseChange_CancellationCaseChange] FOREIGN KEY ([CancellationId]) REFERENCES [dbo].[CompanyCaseChange]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseChange] CHECK CONSTRAINT [FK_CompanyCaseChange_CancellationCaseChange]
GO

ALTER TABLE [dbo].[CompanyCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseChange_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseChange] CHECK CONSTRAINT [FK_CompanyCaseChange_Division]
GO

ALTER TABLE [dbo].[CompanyCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseChange_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseChange] CHECK CONSTRAINT [FK_CompanyCaseChange_Tenant]
GO

ALTER TABLE [dbo].[CompanyCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseChange_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseChange] CHECK CONSTRAINT [FK_CompanyCaseChange_User]
GO

ALTER TABLE [dbo].[CompanyCaseDocument]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseDocument_CompanyCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[CompanyCaseValue]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseDocument] CHECK CONSTRAINT [FK_CompanyCaseDocument_CompanyCaseValue]
GO

ALTER TABLE [dbo].[CompanyCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseValue_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseValue] CHECK CONSTRAINT [FK_CompanyCaseValue_Division]
GO

ALTER TABLE [dbo].[CompanyCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseValue_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseValue] CHECK CONSTRAINT [FK_CompanyCaseValue_Tenant]
GO

ALTER TABLE [dbo].[CompanyCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_CompanyCaseValueChange_CompanyCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[CompanyCaseValue]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseValueChange] CHECK CONSTRAINT [FK_CompanyCaseValueChange_CompanyCaseValue]
GO

ALTER TABLE [dbo].[CompanyCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_IX_CompanyCaseValueChange_CompanyCaseChange] FOREIGN KEY ([CaseChangeId]) REFERENCES [dbo].[CompanyCaseChange]([Id])
GO

ALTER TABLE [dbo].[CompanyCaseValueChange] CHECK CONSTRAINT [FK_IX_CompanyCaseValueChange_CompanyCaseChange]
GO

ALTER TABLE [dbo].[Division]
  WITH CHECK ADD CONSTRAINT [FK_Division_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Division] CHECK CONSTRAINT [FK_Division_Tenant]
GO

ALTER TABLE [dbo].[Employee]
  WITH CHECK ADD CONSTRAINT [FK_Employee_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Employee] CHECK CONSTRAINT [FK_Employee_Tenant]
GO

ALTER TABLE [dbo].[EmployeeCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseChange_CancellationCaseChange] FOREIGN KEY ([CancellationId]) REFERENCES [dbo].[EmployeeCaseChange]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseChange] CHECK CONSTRAINT [FK_EmployeeCaseChange_CancellationCaseChange]
GO

ALTER TABLE [dbo].[EmployeeCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseChange_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseChange] CHECK CONSTRAINT [FK_EmployeeCaseChange_Division]
GO

ALTER TABLE [dbo].[EmployeeCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseChange_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseChange] CHECK CONSTRAINT [FK_EmployeeCaseChange_Employee]
GO

ALTER TABLE [dbo].[EmployeeCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseChange_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseChange] CHECK CONSTRAINT [FK_EmployeeCaseChange_User]
GO

ALTER TABLE [dbo].[EmployeeCaseDocument]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseDocument_EmployeeCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[EmployeeCaseValue]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseDocument] CHECK CONSTRAINT [FK_EmployeeCaseDocument_EmployeeCaseValue]
GO

ALTER TABLE [dbo].[EmployeeCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseValue_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseValue] CHECK CONSTRAINT [FK_EmployeeCaseValue_Division]
GO

ALTER TABLE [dbo].[EmployeeCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseValue_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseValue] CHECK CONSTRAINT [FK_EmployeeCaseValue_Employee]
GO

ALTER TABLE [dbo].[EmployeeCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseValueChange_EmployeeCaseChange] FOREIGN KEY ([CaseChangeId]) REFERENCES [dbo].[EmployeeCaseChange]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseValueChange] CHECK CONSTRAINT [FK_EmployeeCaseValueChange_EmployeeCaseChange]
GO

ALTER TABLE [dbo].[EmployeeCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeCaseValueChange_EmployeeCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[EmployeeCaseValue]([Id])
GO

ALTER TABLE [dbo].[EmployeeCaseValueChange] CHECK CONSTRAINT [FK_EmployeeCaseValueChange_EmployeeCaseValue]
GO

ALTER TABLE [dbo].[EmployeeDivision]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeDivision_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[EmployeeDivision] CHECK CONSTRAINT [FK_EmployeeDivision_Division]
GO

ALTER TABLE [dbo].[EmployeeDivision]
  WITH CHECK ADD CONSTRAINT [FK_EmployeeDivision_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee]([Id])
GO

ALTER TABLE [dbo].[EmployeeDivision] CHECK CONSTRAINT [FK_EmployeeDivision_Employee]
GO

ALTER TABLE [dbo].[GlobalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseChange_CancellationGlobalCaseChange] FOREIGN KEY ([CancellationId]) REFERENCES [dbo].[GlobalCaseChange]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseChange] CHECK CONSTRAINT [FK_GlobalCaseChange_CancellationGlobalCaseChange]
GO

ALTER TABLE [dbo].[GlobalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseChange_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseChange] CHECK CONSTRAINT [FK_GlobalCaseChange_Division]
GO

ALTER TABLE [dbo].[GlobalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseChange_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseChange] CHECK CONSTRAINT [FK_GlobalCaseChange_Tenant]
GO

ALTER TABLE [dbo].[GlobalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseChange_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseChange] CHECK CONSTRAINT [FK_GlobalCaseChange_User]
GO

ALTER TABLE [dbo].[GlobalCaseDocument]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseDocument_GlobalCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[GlobalCaseValue]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseDocument] CHECK CONSTRAINT [FK_GlobalCaseDocument_GlobalCaseValue]
GO

ALTER TABLE [dbo].[GlobalCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseValue_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseValue] CHECK CONSTRAINT [FK_GlobalCaseValue_Division]
GO

ALTER TABLE [dbo].[GlobalCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseValue_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseValue] CHECK CONSTRAINT [FK_GlobalCaseValue_Tenant]
GO

ALTER TABLE [dbo].[GlobalCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseValueChange_GlobalCaseChange] FOREIGN KEY ([CaseChangeId]) REFERENCES [dbo].[GlobalCaseChange]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseValueChange] CHECK CONSTRAINT [FK_GlobalCaseValueChange_GlobalCaseChange]
GO

ALTER TABLE [dbo].[GlobalCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_GlobalCaseValueChange_GlobalCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[GlobalCaseValue]([Id])
GO

ALTER TABLE [dbo].[GlobalCaseValueChange] CHECK CONSTRAINT [FK_GlobalCaseValueChange_GlobalCaseValue]
GO

ALTER TABLE [dbo].[Log]
  WITH CHECK ADD CONSTRAINT [FK_Log_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Log] CHECK CONSTRAINT [FK_Log_Tenant]
GO

ALTER TABLE [dbo].[Lookup]
  WITH CHECK ADD CONSTRAINT [FK_Lookup_Regulation] FOREIGN KEY ([RegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[Lookup] CHECK CONSTRAINT [FK_Lookup_Regulation]
GO

ALTER TABLE [dbo].[LookupAudit]
  WITH CHECK ADD CONSTRAINT [FK_LookupAudit_Lookup] FOREIGN KEY ([LookupId]) REFERENCES [dbo].[Lookup]([Id])
GO

ALTER TABLE [dbo].[LookupAudit] CHECK CONSTRAINT [FK_LookupAudit_Lookup]
GO

ALTER TABLE [dbo].[LookupValue]
  WITH CHECK ADD CONSTRAINT [FK_LookupValue_Lookup] FOREIGN KEY ([LookupId]) REFERENCES [dbo].[Lookup]([Id])
GO

ALTER TABLE [dbo].[LookupValue] CHECK CONSTRAINT [FK_LookupValue_Lookup]
GO

ALTER TABLE [dbo].[LookupValueAudit]
  WITH CHECK ADD CONSTRAINT [FK_LookupValueAudit_LookupValue] FOREIGN KEY ([LookupValueId]) REFERENCES [dbo].[LookupValue]([Id])
GO

ALTER TABLE [dbo].[LookupValueAudit] CHECK CONSTRAINT [FK_LookupValueAudit_LookupValue]
GO

ALTER TABLE [dbo].[NationalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_CaseChange_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[NationalCaseChange] CHECK CONSTRAINT [FK_CaseChange_User]
GO

ALTER TABLE [dbo].[NationalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseChange_CancellationCaseChange] FOREIGN KEY ([CancellationId]) REFERENCES [dbo].[NationalCaseChange]([Id])
GO

ALTER TABLE [dbo].[NationalCaseChange] CHECK CONSTRAINT [FK_NationalCaseChange_CancellationCaseChange]
GO

ALTER TABLE [dbo].[NationalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseChange_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[NationalCaseChange] CHECK CONSTRAINT [FK_NationalCaseChange_Division]
GO

ALTER TABLE [dbo].[NationalCaseChange]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseChange_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[NationalCaseChange] CHECK CONSTRAINT [FK_NationalCaseChange_Tenant]
GO

ALTER TABLE [dbo].[NationalCaseDocument]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseDocument_NationalCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[NationalCaseValue]([Id])
GO

ALTER TABLE [dbo].[NationalCaseDocument] CHECK CONSTRAINT [FK_NationalCaseDocument_NationalCaseValue]
GO

ALTER TABLE [dbo].[NationalCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseValue_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[NationalCaseValue] CHECK CONSTRAINT [FK_NationalCaseValue_Division]
GO

ALTER TABLE [dbo].[NationalCaseValue]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseValue_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[NationalCaseValue] CHECK CONSTRAINT [FK_NationalCaseValue_Tenant]
GO

ALTER TABLE [dbo].[NationalCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseValueChange_NationalCaseChange] FOREIGN KEY ([CaseChangeId]) REFERENCES [dbo].[NationalCaseChange]([Id])
GO

ALTER TABLE [dbo].[NationalCaseValueChange] CHECK CONSTRAINT [FK_NationalCaseValueChange_NationalCaseChange]
GO

ALTER TABLE [dbo].[NationalCaseValueChange]
  WITH CHECK ADD CONSTRAINT [FK_NationalCaseValueChange_NationalCaseValue] FOREIGN KEY ([CaseValueId]) REFERENCES [dbo].[NationalCaseValue]([Id])
GO

ALTER TABLE [dbo].[NationalCaseValueChange] CHECK CONSTRAINT [FK_NationalCaseValueChange_NationalCaseValue]
GO

ALTER TABLE [dbo].[Payroll]
  WITH CHECK ADD CONSTRAINT [FK_Payroll_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[Payroll] CHECK CONSTRAINT [FK_Payroll_Division]
GO

ALTER TABLE [dbo].[Payroll]
  WITH CHECK ADD CONSTRAINT [FK_Payroll_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Payroll] CHECK CONSTRAINT [FK_Payroll_Tenant]
GO

ALTER TABLE [dbo].[PayrollLayer]
  WITH CHECK ADD CONSTRAINT [FK_PayrollLayer_Payroll] FOREIGN KEY ([PayrollId]) REFERENCES [dbo].[Payroll]([Id])
GO

ALTER TABLE [dbo].[PayrollLayer] CHECK CONSTRAINT [FK_PayrollLayer_Payroll]
GO

ALTER TABLE [dbo].[PayrollResult]
  WITH CHECK ADD CONSTRAINT [FK_PayrollResult_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[PayrollResult] CHECK CONSTRAINT [FK_PayrollResult_Division]
GO

ALTER TABLE [dbo].[PayrollResult]
  WITH CHECK ADD CONSTRAINT [FK_PayrollResult_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee]([Id])
GO

ALTER TABLE [dbo].[PayrollResult] CHECK CONSTRAINT [FK_PayrollResult_Employee]
GO

ALTER TABLE [dbo].[PayrollResult]
  WITH CHECK ADD CONSTRAINT [FK_PayrollResult_Payroll] FOREIGN KEY ([PayrollId]) REFERENCES [dbo].[Payroll]([Id])
GO

ALTER TABLE [dbo].[PayrollResult] CHECK CONSTRAINT [FK_PayrollResult_Payroll]
GO

ALTER TABLE [dbo].[PayrollResult]
  WITH CHECK ADD CONSTRAINT [FK_PayrollResult_PayrunJob] FOREIGN KEY ([PayrunJobId]) REFERENCES [dbo].[PayrunJob]([Id])
GO

ALTER TABLE [dbo].[PayrollResult] CHECK CONSTRAINT [FK_PayrollResult_PayrunJob]
GO

ALTER TABLE [dbo].[Payrun]
  WITH CHECK ADD CONSTRAINT [FK_Payrun_Payroll] FOREIGN KEY ([PayrollId]) REFERENCES [dbo].[Payroll]([Id])
GO

ALTER TABLE [dbo].[Payrun] CHECK CONSTRAINT [FK_Payrun_Payroll]
GO

ALTER TABLE [dbo].[Payrun]
  WITH CHECK ADD CONSTRAINT [FK_Payrun_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Payrun] CHECK CONSTRAINT [FK_Payrun_Tenant]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_Division] FOREIGN KEY ([DivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_Division]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_FinishUser] FOREIGN KEY ([FinishedUserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_FinishUser]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_ParentPayrunJob] FOREIGN KEY ([ParentJobId]) REFERENCES [dbo].[PayrunJob]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_ParentPayrunJob]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_Payroll] FOREIGN KEY ([PayrollId]) REFERENCES [dbo].[Payroll]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_Payroll]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_Payrun] FOREIGN KEY ([PayrunId]) REFERENCES [dbo].[Payrun]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_Payrun]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_ProcessUser] FOREIGN KEY ([ProcessedUserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_ProcessUser]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_ReleaseUser] FOREIGN KEY ([ReleasedUserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_ReleaseUser]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_Tenant]
GO

ALTER TABLE [dbo].[PayrunJob]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJob_User] FOREIGN KEY ([CreatedUserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[PayrunJob] CHECK CONSTRAINT [FK_PayrunJob_User]
GO

ALTER TABLE [dbo].[PayrunJobEmployee]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJobEmployee_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee]([Id])
GO

ALTER TABLE [dbo].[PayrunJobEmployee] CHECK CONSTRAINT [FK_PayrunJobEmployee_Employee]
GO

ALTER TABLE [dbo].[PayrunJobEmployee]
  WITH CHECK ADD CONSTRAINT [FK_PayrunJobEmployee_PayrunJob] FOREIGN KEY ([PayrunJobId]) REFERENCES [dbo].[PayrunJob]([Id])
GO

ALTER TABLE [dbo].[PayrunJobEmployee] CHECK CONSTRAINT [FK_PayrunJobEmployee_PayrunJob]
GO

ALTER TABLE [dbo].[PayrunParameter]
  WITH CHECK ADD CONSTRAINT [FK_PayrunParameter_Payrun] FOREIGN KEY ([PayrunId]) REFERENCES [dbo].[Payrun]([Id])
GO

ALTER TABLE [dbo].[PayrunParameter] CHECK CONSTRAINT [FK_PayrunParameter_Payrun]
GO

ALTER TABLE [dbo].[PayrunResult]
  WITH CHECK ADD CONSTRAINT [FK_PayrunResult_PayrollResult] FOREIGN KEY ([PayrollResultId]) REFERENCES [dbo].[PayrollResult]([Id])
GO

ALTER TABLE [dbo].[PayrunResult] CHECK CONSTRAINT [FK_PayrunResult_PayrollResult]
GO

ALTER TABLE [dbo].[PayrunTrace]
  WITH CHECK ADD CONSTRAINT [FK_PayrunTrace_PayrollResult] FOREIGN KEY ([PayrollResultId]) REFERENCES [dbo].[PayrollResult]([Id])
GO

ALTER TABLE [dbo].[PayrunTrace] CHECK CONSTRAINT [FK_PayrunTrace_PayrollResult]
GO

ALTER TABLE [dbo].[Regulation]
  WITH CHECK ADD CONSTRAINT [FK_Regulation_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Regulation] CHECK CONSTRAINT [FK_Regulation_Tenant]
GO

ALTER TABLE [dbo].[RegulationShare]
  WITH CHECK ADD CONSTRAINT [FK_RegulationShare_ConsumerDivision] FOREIGN KEY ([ConsumerDivisionId]) REFERENCES [dbo].[Division]([Id])
GO

ALTER TABLE [dbo].[RegulationShare] CHECK CONSTRAINT [FK_RegulationShare_ConsumerDivision]
GO

ALTER TABLE [dbo].[RegulationShare]
  WITH CHECK ADD CONSTRAINT [FK_RegulationShare_PermissionTenant] FOREIGN KEY ([ConsumerTenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[RegulationShare] CHECK CONSTRAINT [FK_RegulationShare_PermissionTenant]
GO

ALTER TABLE [dbo].[RegulationShare]
  WITH CHECK ADD CONSTRAINT [FK_RegulationShare_ProviderRegulation] FOREIGN KEY ([ProviderRegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[RegulationShare] CHECK CONSTRAINT [FK_RegulationShare_ProviderRegulation]
GO

ALTER TABLE [dbo].[RegulationShare]
  WITH CHECK ADD CONSTRAINT [FK_RegulationShare_ProviderTenant] FOREIGN KEY ([ProviderTenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[RegulationShare] CHECK CONSTRAINT [FK_RegulationShare_ProviderTenant]
GO

ALTER TABLE [dbo].[Report]
  WITH CHECK ADD CONSTRAINT [FK_Report_Regulation] FOREIGN KEY ([RegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[Report] CHECK CONSTRAINT [FK_Report_Regulation]
GO

ALTER TABLE [dbo].[ReportLog]
  WITH CHECK ADD CONSTRAINT [FK_ReportLog_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[ReportLog] CHECK CONSTRAINT [FK_ReportLog_Tenant]
GO

ALTER TABLE [dbo].[ReportParameter]
  WITH CHECK ADD CONSTRAINT [FK_ReportParameter_Report] FOREIGN KEY ([ReportId]) REFERENCES [dbo].[Report]([Id])
GO

ALTER TABLE [dbo].[ReportParameter] CHECK CONSTRAINT [FK_ReportParameter_Report]
GO

ALTER TABLE [dbo].[ReportTemplate]
  WITH CHECK ADD CONSTRAINT [FK_ReportTemplate_Report] FOREIGN KEY ([ReportId]) REFERENCES [dbo].[Report]([Id])
GO

ALTER TABLE [dbo].[ReportTemplate] CHECK CONSTRAINT [FK_ReportTemplate_Report]
GO

ALTER TABLE [dbo].[Script]
  WITH CHECK ADD CONSTRAINT [FK_Script_Regulation] FOREIGN KEY ([RegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[Script] CHECK CONSTRAINT [FK_Script_Regulation]
GO

ALTER TABLE [dbo].[Task]
  WITH CHECK ADD CONSTRAINT [FK_Task_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Task] CHECK CONSTRAINT [FK_Task_Tenant]
GO

ALTER TABLE [dbo].[Task]
  WITH CHECK ADD CONSTRAINT [FK_Task_User] FOREIGN KEY ([ScheduledUserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[Task] CHECK CONSTRAINT [FK_Task_User]
GO

ALTER TABLE [dbo].[Task]
  WITH CHECK ADD CONSTRAINT [FK_Task_User1] FOREIGN KEY ([CompletedUserId]) REFERENCES [dbo].[User]([Id])
GO

ALTER TABLE [dbo].[Task] CHECK CONSTRAINT [FK_Task_User1]
GO

ALTER TABLE [dbo].[User]
  WITH CHECK ADD CONSTRAINT [FK_User_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_User_Tenant]
GO

ALTER TABLE [dbo].[WageType]
  WITH CHECK ADD CONSTRAINT [FK_WageType_Regulation] FOREIGN KEY ([RegulationId]) REFERENCES [dbo].[Regulation]([Id])
GO

ALTER TABLE [dbo].[WageType] CHECK CONSTRAINT [FK_WageType_Regulation]
GO

ALTER TABLE [dbo].[WageTypeAudit]
  WITH CHECK ADD CONSTRAINT [FK_Regulation.WageTypeAudit_WageType] FOREIGN KEY ([WageTypeId]) REFERENCES [dbo].[WageType]([Id])
GO

ALTER TABLE [dbo].[WageTypeAudit] CHECK CONSTRAINT [FK_Regulation.WageTypeAudit_WageType]
GO

ALTER TABLE [dbo].[WageTypeCustomResult]
  WITH CHECK ADD CONSTRAINT [FK_WageTypeCustomResult_WageTypeResult] FOREIGN KEY ([WageTypeResultId]) REFERENCES [dbo].[WageTypeResult]([Id])
GO

ALTER TABLE [dbo].[WageTypeCustomResult] CHECK CONSTRAINT [FK_WageTypeCustomResult_WageTypeResult]
GO

ALTER TABLE [dbo].[WageTypeResult]
  WITH CHECK ADD CONSTRAINT [FK_WageTypeResult_PayrollResult] FOREIGN KEY ([PayrollResultId]) REFERENCES [dbo].[PayrollResult]([Id])
GO

ALTER TABLE [dbo].[WageTypeResult] CHECK CONSTRAINT [FK_WageTypeResult_PayrollResult]
GO

ALTER TABLE [dbo].[Webhook]
  WITH CHECK ADD CONSTRAINT [FK_Webhook_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant]([Id])
GO

ALTER TABLE [dbo].[Webhook] CHECK CONSTRAINT [FK_Webhook_Tenant]
GO

ALTER TABLE [dbo].[WebhookMessage]
  WITH CHECK ADD CONSTRAINT [FK_WebhookMessage_Webhook] FOREIGN KEY ([WebhookId]) REFERENCES [dbo].[Webhook]([Id])
GO

ALTER TABLE [dbo].[WebhookMessage] CHECK CONSTRAINT [FK_WebhookMessage_Webhook]
GO

/****** Object:  StoredProcedure [dbo].[DeleteAllCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Delete all case values
--	
CREATE PROCEDURE [dbo].[DeleteAllCaseValues]
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  EXEC [dbo].[DeleteAllGlobalCaseValues]

  EXEC [dbo].[DeleteAllNationalCaseValues]

  EXEC [dbo].[DeleteAllCompanyCaseValues]

  EXEC [dbo].[DeleteAllEmployeeCaseValues]
END
GO

/****** Object:  StoredProcedure [dbo].[DeleteAllCompanyCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Delete all company case values
--	
CREATE PROCEDURE [dbo].[DeleteAllCompanyCaseValues]
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DELETE
  FROM [dbo].[CompanyCaseValueChange]

  DELETE
  FROM [dbo].[CompanyCaseDocument]

  DELETE
  FROM [dbo].[CompanyCaseValue]

  DELETE
  FROM [dbo].[CompanyCaseChange]
END
GO

/****** Object:  StoredProcedure [dbo].[DeleteAllEmployeeCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Delete all employee case values
--	
CREATE PROCEDURE [dbo].[DeleteAllEmployeeCaseValues]
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DELETE
  FROM [dbo].[EmployeeCaseValueChange]

  DELETE
  FROM [dbo].[EmployeeCaseDocument]

  DELETE
  FROM [dbo].[EmployeeCaseValue]

  DELETE
  FROM [dbo].[EmployeeCaseChange]
END
GO

/****** Object:  StoredProcedure [dbo].[DeleteAllGlobalCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Delete all global case values
--	
CREATE PROCEDURE [dbo].[DeleteAllGlobalCaseValues]
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DELETE
  FROM [dbo].[GlobalCaseValueChange]

  DELETE
  FROM [dbo].[GlobalCaseDocument]

  DELETE
  FROM [dbo].[GlobalCaseValue]

  DELETE
  FROM [dbo].[GlobalCaseChange]
END
GO

/****** Object:  StoredProcedure [dbo].[DeleteAllNationalCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Delete all national case values
--	
CREATE PROCEDURE [dbo].[DeleteAllNationalCaseValues]
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DELETE
  FROM [dbo].[NationalCaseValueChange]

  DELETE
  FROM [dbo].[NationalCaseDocument]

  DELETE
  FROM [dbo].[NationalCaseValue]

  DELETE
  FROM [dbo].[NationalCaseChange]
END
GO

/****** Object:  StoredProcedure [dbo].[DeletePayrunJob]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Detete payrun job including all his related objects
--	
CREATE PROCEDURE [dbo].[DeletePayrunJob]
  -- the tenant
  @tenantId AS INT,
  -- the payrun job to delete
  @payrunJobId AS INT
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- transaction start
  BEGIN TRANSACTION;

  SAVE TRANSACTION DeletePayrunJobTransaction;

  BEGIN TRY
    -- payrun results
    DELETE [dbo].[PayrunResult]
    FROM [dbo].[PayrunResult]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[PayrunResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrollResult].[PayrunJobId] = @payrunJobId

    -- wage type custom results
    DELETE [dbo].[WageTypeCustomResult]
    FROM [dbo].[WageTypeCustomResult]
    INNER JOIN [dbo].[WageTypeResult]
      ON [dbo].[WageTypeCustomResult].[WageTypeResultId] = [dbo].[WageTypeResult].[Id]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[WageTypeResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrollResult].[PayrunJobId] = @payrunJobId

    -- wage type results
    DELETE [dbo].[WageTypeResult]
    FROM [dbo].[WageTypeResult]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[WageTypeResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrollResult].[PayrunJobId] = @payrunJobId

    -- collector custom results
    DELETE [dbo].[CollectorCustomResult]
    FROM [dbo].[CollectorCustomResult]
    INNER JOIN [dbo].[CollectorResult]
      ON [dbo].[CollectorCustomResult].[CollectorResultId] = [dbo].[CollectorResult].[Id]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[CollectorResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrollResult].[PayrunJobId] = @payrunJobId

    -- collector results
    DELETE [dbo].[CollectorResult]
    FROM [dbo].[CollectorResult]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[CollectorResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrollResult].[PayrunJobId] = @payrunJobId

    -- payroll results
    DELETE
    FROM [dbo].[PayrollResult]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrollResult].[PayrunJobId] = @payrunJobId

    -- payrun job emplyoee
    DELETE [dbo].[PayrunJobEmployee]
    FROM [dbo].[PayrunJobEmployee]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrunJobEmployee].[PayrunJobId] = @payrunJobId

    -- payrun job
    DELETE [dbo].[PayrunJob]
    FROM [dbo].[PayrunJob]
    WHERE @tenantId = @tenantId
      AND [dbo].[PayrunJob].[Id] = @payrunJobId

    -- transaction end
    COMMIT TRANSACTION;

    -- success
    RETURN 1
  END TRY

  BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
      ROLLBACK TRANSACTION DeletePayrunJobTransaction;
    END

    -- failure
    RETURN 0
  END CATCH
END
GO

/****** Object:  StoredProcedure [dbo].[DeleteTenant]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Detete tenant including all his related objects
--	
CREATE PROCEDURE [dbo].[DeleteTenant]
  -- the tenant to delete
  @tenantId AS INT
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  -- transaction start
  BEGIN TRANSACTION;

  SAVE TRANSACTION DeleteTenantTransaction;

  BEGIN TRY
    -- payroll results
    DELETE [dbo].[PayrunResult]
    FROM [dbo].[PayrunResult]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[PayrunResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE [dbo].[PayrollResult].[TenantId] = @tenantId

    DELETE [dbo].[WageTypeCustomResult]
    FROM [dbo].[WageTypeCustomResult]
    INNER JOIN [dbo].[WageTypeResult]
      ON [dbo].[WageTypeCustomResult].[WageTypeResultId] = [dbo].[WageTypeResult].[Id]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[WageTypeResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE [dbo].[PayrollResult].[TenantId] = @tenantId

    DELETE [dbo].[WageTypeResult]
    FROM [dbo].[WageTypeResult]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[WageTypeResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE [dbo].[PayrollResult].[TenantId] = @tenantId

    DELETE [dbo].[CollectorCustomResult]
    FROM [dbo].[CollectorCustomResult]
    INNER JOIN [dbo].[CollectorResult]
      ON [dbo].[CollectorCustomResult].[CollectorResultId] = [dbo].[CollectorResult].[Id]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[CollectorResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE [dbo].[PayrollResult].[TenantId] = @tenantId

    DELETE [dbo].[CollectorResult]
    FROM [dbo].[CollectorResult]
    INNER JOIN [dbo].[PayrollResult]
      ON [dbo].[CollectorResult].[PayrollResultId] = [dbo].[PayrollResult].[Id]
    WHERE [dbo].[PayrollResult].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[PayrollResult]
    WHERE [TenantId] = @tenantId

    -- payrun with jobs
    DELETE [dbo].[PayrunJobEmployee]
    FROM [dbo].[PayrunJobEmployee]
    INNER JOIN [dbo].[PayrunJob]
      ON [dbo].[PayrunJobEmployee].[PayrunJobId] = [dbo].[PayrunJob].[Id]
    WHERE [dbo].[PayrunJob].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[PayrunJob]
    WHERE [TenantId] = @tenantId

    DELETE [dbo].[PayrunParameter]
    FROM [dbo].[PayrunParameter]
    INNER JOIN [dbo].[Payrun]
      ON [dbo].[PayrunParameter].[PayrunId] = [dbo].[Payrun].[Id]
    WHERE [dbo].[Payrun].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[Payrun]
    WHERE [TenantId] = @tenantId

    -- payroll with payroll layers
    DELETE [dbo].[PayrollLayer]
    FROM [dbo].[PayrollLayer]
    INNER JOIN [dbo].[Payroll]
      ON [dbo].[PayrollLayer].[PayrollId] = [dbo].[Payroll].[Id]
    WHERE [dbo].[Payroll].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[Payroll]
    WHERE [TenantId] = @tenantId

    -- regulation shares
    DELETE [dbo].[RegulationShare]
    FROM [dbo].[RegulationShare]
    WHERE [dbo].[RegulationShare].[ProviderTenantId] = @tenantId
      OR [dbo].[RegulationShare].[ConsumerTenantId] = @tenantId

    -- regulation
    DELETE [dbo].[ReportTemplateAudit]
    FROM [dbo].[ReportTemplateAudit]
    INNER JOIN [dbo].[ReportTemplate]
      ON [dbo].[ReportTemplateAudit].[ReportTemplateId] = [dbo].[ReportTemplate].[Id]
    INNER JOIN [dbo].[Report]
      ON [dbo].[ReportTemplate].[ReportId] = [dbo].[Report].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Report].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[ReportTemplate]
    FROM [dbo].[ReportTemplate]
    INNER JOIN [dbo].[Report]
      ON [dbo].[ReportTemplate].[ReportId] = [dbo].[Report].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Report].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[ReportParameterAudit]
    FROM [dbo].[ReportParameterAudit]
    INNER JOIN [dbo].[ReportParameter]
      ON [dbo].[ReportParameterAudit].[ReportParameterId] = [dbo].[ReportParameter].[Id]
    INNER JOIN [dbo].[Report]
      ON [dbo].[ReportParameter].[ReportId] = [dbo].[Report].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Report].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[ReportParameter]
    FROM [dbo].[ReportParameter]
    INNER JOIN [dbo].[Report]
      ON [dbo].[ReportParameter].[ReportId] = [dbo].[Report].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Report].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[ReportAudit]
    FROM [dbo].[ReportAudit]
    INNER JOIN [dbo].[Report]
      ON [dbo].[ReportAudit].[ReportId] = [dbo].[Report].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Report].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[Report]
    FROM [dbo].[Report]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Report].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[ScriptAudit]
    FROM [dbo].[ScriptAudit]
    INNER JOIN [dbo].[Script]
      ON [dbo].[ScriptAudit].[ScriptId] = [dbo].[Script].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Script].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[Script]
    FROM [dbo].[Script]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Script].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[LookupValueAudit]
    FROM [dbo].[LookupValueAudit]
    INNER JOIN [dbo].[LookupValue]
      ON [dbo].[LookupValueAudit].[LookupValueId] = [dbo].[LookupValue].[Id]
    INNER JOIN [dbo].[Lookup]
      ON [dbo].[LookupValue].[LookupId] = [dbo].[Lookup].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Lookup].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[LookupValue]
    FROM [dbo].[LookupValue]
    INNER JOIN [dbo].[Lookup]
      ON [dbo].[LookupValue].[LookupId] = [dbo].[Lookup].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Lookup].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[LookupAudit]
    FROM [dbo].[LookupAudit]
    INNER JOIN [dbo].[Lookup]
      ON [dbo].[LookupAudit].[LookupId] = [dbo].[Lookup].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Lookup].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[Lookup]
    FROM [dbo].[Lookup]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Lookup].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[CollectorAudit]
    FROM [dbo].[CollectorAudit]
    INNER JOIN [dbo].[Collector]
      ON [dbo].[CollectorAudit].[CollectorId] = [dbo].[Collector].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Collector].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[Collector]
    FROM [dbo].[Collector]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Collector].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[WageTypeAudit]
    FROM [dbo].[WageTypeAudit]
    INNER JOIN [dbo].[WageType]
      ON [dbo].[WageTypeAudit].[WageTypeId] = [dbo].[WageType].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[WageType].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[WageType]
    FROM [dbo].[WageType]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[WageType].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[CaseRelationAudit]
    FROM [dbo].[CaseRelationAudit]
    INNER JOIN [dbo].[CaseRelation]
      ON [dbo].[CaseRelationAudit].[CaseRelationId] = [dbo].[CaseRelation].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[CaseRelation].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[CaseRelation]
    FROM [dbo].[CaseRelation]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[CaseRelation].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[CaseFieldAudit]
    FROM [dbo].[CaseFieldAudit]
    INNER JOIN [dbo].[CaseField]
      ON [dbo].[CaseFieldAudit].[CaseFieldId] = [dbo].[CaseField].[Id]
    INNER JOIN [dbo].[Case]
      ON [dbo].[CaseField].[CaseId] = [dbo].[Case].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Case].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[CaseField]
    FROM [dbo].[CaseField]
    INNER JOIN [dbo].[Case]
      ON [dbo].[CaseField].[CaseId] = [dbo].[Case].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Case].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[CaseAudit]
    FROM [dbo].[CaseAudit]
    INNER JOIN [dbo].[Case]
      ON [dbo].[CaseAudit].[CaseId] = [dbo].[Case].[Id]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Case].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE [dbo].[Case]
    FROM [dbo].[Case]
    INNER JOIN [dbo].[Regulation]
      ON [dbo].[Case].[RegulationId] = [dbo].[Regulation].[Id]
    WHERE [dbo].[Regulation].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[Regulation]
    WHERE [TenantId] = @tenantId

    -- employee
    DELETE [dbo].[EmployeeCaseValueChange]
    FROM [dbo].[EmployeeCaseValueChange]
    INNER JOIN [dbo].[EmployeeCaseChange]
      ON [dbo].[EmployeeCaseValueChange].[CaseChangeId] = [dbo].[EmployeeCaseChange].[Id]
    INNER JOIN [dbo].[Employee]
      ON [dbo].[EmployeeCaseChange].[EmployeeId] = [dbo].[Employee].[Id]
    WHERE [dbo].[Employee].[TenantId] = @tenantId

    DELETE [dbo].[EmployeeCaseChange]
    FROM [dbo].[EmployeeCaseChange]
    INNER JOIN [dbo].[Employee]
      ON [dbo].[EmployeeCaseChange].[EmployeeId] = [dbo].[Employee].[Id]
    WHERE [dbo].[Employee].[TenantId] = @tenantId

    DELETE [dbo].[EmployeeCaseDocument]
    FROM [dbo].[EmployeeCaseDocument]
    INNER JOIN [dbo].[EmployeeCaseValue]
      ON [dbo].[EmployeeCaseDocument].[CaseValueId] = [dbo].[EmployeeCaseValue].[Id]
    INNER JOIN [dbo].[Employee]
      ON [dbo].[EmployeeCaseValue].[EmployeeId] = [dbo].[Employee].[Id]
    WHERE [dbo].[Employee].[TenantId] = @tenantId

    DELETE [dbo].[EmployeeCaseValue]
    FROM [dbo].[EmployeeCaseValue]
    INNER JOIN [dbo].[Employee]
      ON [dbo].[EmployeeCaseValue].[EmployeeId] = [dbo].[Employee].[Id]
    WHERE [dbo].[Employee].[TenantId] = @tenantId

    DELETE [dbo].[EmployeeDivision]
    FROM [dbo].[EmployeeDivision]
    INNER JOIN [dbo].[Employee]
      ON [dbo].[EmployeeDivision].[EmployeeId] = [dbo].[Employee].[Id]
    WHERE [dbo].[Employee].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[Employee]
    WHERE [TenantId] = @tenantId

    -- company
    DELETE [dbo].[CompanyCaseValueChange]
    FROM [dbo].[CompanyCaseValueChange]
    INNER JOIN [dbo].[CompanyCaseChange]
      ON [dbo].[CompanyCaseValueChange].[CaseChangeId] = [dbo].[CompanyCaseChange].[Id]
    WHERE [dbo].[CompanyCaseChange].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[CompanyCaseChange]
    WHERE [TenantId] = @tenantId

    DELETE [dbo].[CompanyCaseDocument]
    FROM [dbo].[CompanyCaseDocument]
    INNER JOIN [dbo].[CompanyCaseValue]
      ON [dbo].[CompanyCaseDocument].[CaseValueId] = [dbo].[CompanyCaseValue].[Id]
    WHERE [dbo].[CompanyCaseValue].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[CompanyCaseValue]
    WHERE [TenantId] = @tenantId

    -- national
    DELETE [dbo].[NationalCaseValueChange]
    FROM [dbo].[NationalCaseValueChange]
    INNER JOIN [dbo].[NationalCaseChange]
      ON [dbo].[NationalCaseValueChange].[CaseChangeId] = [dbo].[NationalCaseChange].[Id]
    WHERE [dbo].[NationalCaseChange].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[NationalCaseChange]
    WHERE [TenantId] = @tenantId

    DELETE [dbo].[NationalCaseDocument]
    FROM [dbo].[NationalCaseDocument]
    INNER JOIN [dbo].[NationalCaseValue]
      ON [dbo].[NationalCaseDocument].[CaseValueId] = [dbo].[NationalCaseValue].[Id]
    WHERE [dbo].[NationalCaseValue].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[NationalCaseValue]
    WHERE [TenantId] = @tenantId

    -- Global
    DELETE [dbo].[GlobalCaseValueChange]
    FROM [dbo].[GlobalCaseValueChange]
    INNER JOIN [dbo].[GlobalCaseChange]
      ON [dbo].[GlobalCaseValueChange].[CaseChangeId] = [dbo].[GlobalCaseChange].[Id]
    WHERE [dbo].[GlobalCaseChange].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[GlobalCaseChange]
    WHERE [TenantId] = @tenantId

    DELETE [dbo].[GlobalCaseDocument]
    FROM [dbo].[GlobalCaseDocument]
    INNER JOIN [dbo].[GlobalCaseValue]
      ON [dbo].[GlobalCaseDocument].[CaseValueId] = [dbo].[GlobalCaseValue].[Id]
    WHERE [dbo].[GlobalCaseValue].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[GlobalCaseValue]
    WHERE [TenantId] = @tenantId

    -- webhook
    DELETE [dbo].[WebhookMessage]
    FROM [dbo].[WebhookMessage]
    INNER JOIN [dbo].[Webhook]
      ON [dbo].[WebhookMessage].[WebhookId] = [dbo].[Webhook].[Id]
    WHERE [dbo].[Webhook].[TenantId] = @tenantId

    DELETE
    FROM [dbo].[Webhook]
    WHERE [TenantId] = @tenantId

    -- task
    DELETE
    FROM [dbo].[Task]
    WHERE [TenantId] = @tenantId

    -- log
    DELETE
    FROM [dbo].[Log]
    WHERE [TenantId] = @tenantId

    -- report log
    DELETE [dbo].[ReportLog]
    WHERE [dbo].[ReportLog].[TenantId] = @tenantId

    -- user
    DELETE
    FROM [dbo].[User]
    WHERE [TenantId] = @tenantId

    -- division
    DELETE
    FROM [dbo].[Division]
    WHERE [TenantId] = @tenantId

    -- calendar
    DELETE
    FROM [dbo].[Calendar]
    WHERE [TenantId] = @tenantId

    -- tenant
    DELETE
    FROM [dbo].[Tenant]
    WHERE [Id] = @tenantId

    -- transaction end
    COMMIT TRANSACTION;

    -- success
    RETURN 1
  END TRY

  BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
      ROLLBACK TRANSACTION DeleteTenantTransaction;
    END

    -- failure
    RETURN 0
  END CATCH
END
GO

/****** Object:  StoredProcedure [dbo].[GetCollectorCustomResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee collector custom results from a time period
-- =============================================
CREATE PROCEDURE [dbo].[GetCollectorCustomResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the payrun job id
  @payrunJobId AS INT = NULL,
  -- the parent payrun job id
  @parentPayrunJobId AS INT = NULL,
  -- the collector name hashes: JSON array of INT
  @collectorNameHashes AS VARCHAR(MAX) = NULL,
  -- period start
  @periodStart AS DATETIME2(7) = NULL,
  -- period end
  @periodEnd AS DATETIME2(7) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @collectorNameHash INT;
  DECLARE @collectorCount INT;

  SELECT @collectorCount = COUNT(*)
  FROM OPENJSON(@collectorNameHashes);

  -- special query for single collector
  -- better perfomance to indexed column of the collector name
  IF (@collectorCount = 1)
  BEGIN
    SELECT @collectorNameHash = CAST(value AS INT)
    FROM OPENJSON(@collectorNameHashes);

    SELECT TOP (100) PERCENT dbo.[CollectorCustomResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[CollectorResult]
      ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
    INNER JOIN dbo.[CollectorCustomResult]
      ON dbo.[CollectorResult].[Id] = dbo.[CollectorCustomResult].[CollectorResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (
        @collectorNameHashes IS NULL
        OR dbo.[CollectorCustomResult].[CollectorNameHash] = @collectorNameHash
        )
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[CollectorResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[CollectorResult].[Created]
  END
  ELSE
  BEGIN
    SELECT TOP (100) PERCENT dbo.[CollectorCustomResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[CollectorResult]
      ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
    INNER JOIN dbo.[CollectorCustomResult]
      ON dbo.[CollectorResult].[Id] = dbo.[CollectorCustomResult].[CollectorResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (
        @collectorNameHashes IS NULL
        OR dbo.[CollectorCustomResult].[CollectorNameHash] IN (
          SELECT value
          FROM OPENJSON(@collectorNameHashes)
          )
        )
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[CollectorResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[CollectorResult].[Created]
  END
END
GO

/****** Object:  StoredProcedure [dbo].[GetCollectorResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee collector results from a time period
-- =============================================
CREATE PROCEDURE [dbo].[GetCollectorResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the payrun job id
  @payrunJobId AS INT = NULL,
  -- the parent payrun job id
  @parentPayrunJobId AS INT = NULL,
  -- the collector name hashes: JSON array of INT
  @collectorNameHashes AS VARCHAR(MAX) = NULL,
  -- period start
  @periodStart AS DATETIME2(7) = NULL,
  -- period end
  @periodEnd AS DATETIME2(7) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @collectorNameHash INT;
  DECLARE @collectorCount INT;

  SELECT @collectorCount = COUNT(*)
  FROM OPENJSON(@collectorNameHashes);

  -- special query for single collector
  -- better perfomance to indexed column of the collector name
  IF (@collectorCount = 1)
  BEGIN
    SELECT @collectorNameHash = CAST(value AS INT)
    FROM OPENJSON(@collectorNameHashes);

    SELECT TOP (100) PERCENT dbo.[CollectorResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[CollectorResult]
      ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (
        @collectorNameHashes IS NULL
        OR dbo.[CollectorResult].[CollectorNameHash] = @collectorNameHash
        )
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[CollectorResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[CollectorResult].[Created]
  END
  ELSE
  BEGIN
    SELECT TOP (100) PERCENT dbo.[CollectorResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[CollectorResult]
      ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (
        @collectorNameHashes IS NULL
        OR dbo.[CollectorResult].[CollectorNameHash] IN (
          SELECT value
          FROM OPENJSON(@collectorNameHashes)
          )
        )
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[CollectorResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[CollectorResult].[Created]
  END
END
GO

/****** Object:  StoredProcedure [dbo].[GetCompanyCaseChangeValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get company case changes using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetCompanyCaseChangeValues]
  -- the company id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL,
  -- the cultue
  @culture AS NVARCHAR(128) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
  INTO ##CompanyCaseChangeValuePivot
    FROM (
      SELECT
  -- tenant
  [dbo].[CompanyCaseChange].[TenantId],
  -- case change
  [dbo].[CompanyCaseChange].[Id] AS CaseChangeId,
  [dbo].[CompanyCaseChange].[Created] AS CaseChangeCreated,
  [dbo].[CompanyCaseChange].[Reason],
  [dbo].[CompanyCaseChange].[ValidationCaseName],
  [dbo].[CompanyCaseChange].[CancellationType],
  [dbo].[CompanyCaseChange].[CancellationId],
  [dbo].[CompanyCaseChange].[CancellationDate],
  NULL AS [EmployeeId],
  [dbo].[CompanyCaseChange].[UserId],
  [dbo].[User].[Identifier] AS UserIdentifier,
  [dbo].[CompanyCaseChange].[DivisionId],
  -- case value
  [dbo].[CompanyCaseValue].[Id],
  [dbo].[CompanyCaseValue].[Created],
  [dbo].[CompanyCaseValue].[Updated],
  [dbo].[CompanyCaseValue].[Status],
  -- localized case name
  ' + IIF(@culture IS NULL, '[dbo].[CompanyCaseValue].[CaseName]', 'dbo.GetLocalizedValue([dbo].[CompanyCaseValue].[CaseNameLocalizations], ''' + 
      @culture + ''', [dbo].[CompanyCaseValue].[CaseName])') + ' AS [CaseName],
  -- localized case field name
  ' + IIF(@culture IS NULL, '[dbo].[CompanyCaseValue].[CaseFieldName]', 'dbo.GetLocalizedValue([dbo].[CompanyCaseValue].[CaseFieldNameLocalizations], ''' + @culture + ''', [dbo].[CompanyCaseValue].[CaseFieldName])') + ' AS [CaseFieldName],
  -- localized case slot
  ' + IIF(@culture IS NULL, '[dbo].[CompanyCaseValue].[CaseSlot]', 'dbo.GetLocalizedValue([dbo].[CompanyCaseValue].[CaseSlotLocalizations], ''' + @culture + ''', [dbo].[CompanyCaseValue].[CaseSlot])') + 
    ' AS [CaseSlot],
  [dbo].[CompanyCaseValue].[CaseRelation],
  [dbo].[CompanyCaseValue].[ValueType],
  [dbo].[CompanyCaseValue].[Value],
  [dbo].[CompanyCaseValue].[NumericValue],
  [dbo].[CompanyCaseValue].[Start],
  [dbo].[CompanyCaseValue].[End],
  [dbo].[CompanyCaseValue].[Forecast],
  [dbo].[CompanyCaseValue].[Tags],
  [dbo].[CompanyCaseValue].[Attributes],
  -- documents
  (
      SELECT Count(*)
      FROM [dbo].[CompanyCaseDocument]
      WHERE [CaseValueId] = [dbo].[CompanyCaseValue].[Id]
      ) AS Documents'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[CompanyCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N'  FROM [dbo].[CompanyCaseValue]
        LEFT JOIN [dbo].[CompanyCaseValueChange]
          ON [dbo].[CompanyCaseValue].[Id] = [dbo].[CompanyCaseValueChange].[CaseValueId]
        LEFT JOIN [dbo].[CompanyCaseChange]
          ON [dbo].[CompanyCaseValueChange].[CaseChangeId] = [dbo].[CompanyCaseChange].[Id]
        LEFT JOIN [dbo].[User]
          ON [dbo].[User].[Id] = [dbo].[CompanyCaseChange].[UserId]
        WHERE ([dbo].[CompanyCaseChange].[TenantId] = ' + CONVERT(VARCHAR(10), @parentId) + ')) AS CCCV';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- start cleanup
  DROP TABLE

  IF EXISTS ##CompanyCaseChangeValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- cleanup
  DROP TABLE

  IF EXISTS ##CompanyCaseChangeValuePivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetCompanyCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get company case values using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetCompanyCaseValues]
  -- the company id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
    INTO ##CompanyCaseValuePivot
    FROM (
        SELECT [dbo].[CompanyCaseValue].*'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[CompanyCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N'  FROM dbo.CompanyCaseValue
      WHERE CompanyCaseValue.TenantId = ' + CAST(@parentId AS VARCHAR(10)) + ') AS CCVA';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- cleanup
  DROP TABLE

  IF EXISTS ##CompanyCaseValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- cleanup
  DROP TABLE

  IF EXISTS ##CompanyCaseValuePivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetConsolidatedCollectorCustomResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get consolidated collector custom results
-- =============================================
CREATE PROCEDURE [dbo].[GetConsolidatedCollectorCustomResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the collector name hashes: JSON array of INT
  @collectorNameHashes AS VARCHAR(MAX) = NULL,
  -- the period start hashes: JSON array of INT
  @periodStartHashes AS VARCHAR(MAX) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @collectorNameHash INT;
  DECLARE @collectorCount INT;

  SELECT @collectorCount = COUNT(*)
  FROM OPENJSON(@collectorNameHashes);

  -- special query for single collector
  -- better perfomance to indexed column of the collector name
  IF (@collectorCount = 1)
  BEGIN
    SELECT @collectorNameHash = CAST(value AS INT)
    FROM OPENJSON(@collectorNameHashes);

    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[CollectorCustomResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[CollectorResult].[CollectorName],
          dbo.[CollectorCustomResult].[Start] ORDER BY dbo.[CollectorCustomResult].[Created] DESC,
            dbo.[CollectorCustomResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[CollectorResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
      INNER JOIN dbo.[CollectorCustomResult]
        ON dbo.[CollectorResult].[Id] = dbo.[CollectorCustomResult].[CollectorResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrunJob].[TenantId] = @tenantId)
        AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[CollectorCustomResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (
          @collectorNameHashes IS NULL
          OR dbo.[CollectorCustomResult].[CollectorNameHash] = @collectorNameHash
          )
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[CollectorCustomResult].[Created] <= @evaluationDate
          )
      ) AS GroupCollectorResult
    WHERE RowNumber = 1;
  END
  ELSE
  BEGIN
    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[CollectorCustomResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[CollectorResult].[CollectorName],
          dbo.[CollectorCustomResult].[Start] ORDER BY dbo.[CollectorCustomResult].[Created] DESC,
            dbo.[CollectorCustomResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[CollectorResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
      INNER JOIN dbo.[CollectorCustomResult]
        ON dbo.[CollectorResult].[Id] = dbo.[CollectorCustomResult].[CollectorResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[CollectorCustomResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (
          @collectorNameHashes IS NULL
          OR dbo.[CollectorCustomResult].[CollectorNameHash] IN (
            SELECT value
            FROM OPENJSON(@collectorNameHashes)
            )
          )
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[CollectorCustomResult].[Created] <= @evaluationDate
          )
      ) AS GroupCollectorResult
    WHERE RowNumber = 1;
  END
END
GO

/****** Object:  StoredProcedure [dbo].[GetConsolidatedCollectorResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee collector results from a time period
-- =============================================
CREATE PROCEDURE [dbo].[GetConsolidatedCollectorResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the collector name hashes: JSON array of INT
  @collectorNameHashes AS VARCHAR(MAX) = NULL,
  -- the period start hashes: JSON array of INT
  @periodStartHashes AS VARCHAR(MAX) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @collectorNameHash INT;
  DECLARE @collectorCount INT;

  SELECT @collectorCount = COUNT(*)
  FROM OPENJSON(@collectorNameHashes);

  -- special query for single collector
  -- better perfomance to indexed column of the collector name
  IF (@collectorCount = 1)
  BEGIN
    SELECT @collectorNameHash = CAST(value AS INT)
    FROM OPENJSON(@collectorNameHashes);

    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[CollectorResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[CollectorResult].[CollectorName],
          dbo.[CollectorResult].[Start] ORDER BY dbo.[CollectorResult].[Created] DESC,
            dbo.[CollectorResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[CollectorResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrunJob].[TenantId] = @tenantId)
        AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[CollectorResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (
          @collectorNameHashes IS NULL
          OR dbo.[CollectorResult].[CollectorNameHash] = @collectorNameHash
          )
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[CollectorResult].[Created] <= @evaluationDate
          )
      ) AS GroupCollectorResult
    WHERE RowNumber = 1;
  END
  ELSE
  BEGIN
    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[CollectorResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[CollectorResult].[CollectorName],
          dbo.[CollectorResult].[Start] ORDER BY dbo.[CollectorResult].[Created] DESC,
            dbo.[CollectorResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[CollectorResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[CollectorResult].[PayrollResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[CollectorResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (
          @collectorNameHashes IS NULL
          OR dbo.[CollectorResult].[CollectorNameHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@collectorNameHashes)
            )
          )
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[CollectorResult].[Created] <= @evaluationDate
          )
      ) AS GroupCollectorResult
    WHERE RowNumber = 1;
  END
END
GO

/****** Object:  StoredProcedure [dbo].[GetConsolidatedPayrunResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get consolidated payrun results from a time period
-- =============================================
CREATE PROCEDURE [dbo].[GetConsolidatedPayrunResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the result names: JSON array of VARCHAR(128)
  @names AS VARCHAR(MAX) = NULL,
  -- the period start hashes: JSON array of INT
  @periodStartHashes AS VARCHAR(MAX) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  SELECT *
  FROM (
    SELECT dbo.[PayrollResult].[EmployeeId],
      dbo.[PayrollResult].[DivisionId],
      dbo.[PayrollResult].[PayrunId],
      dbo.[PayrollResult].[PayrunJobId],
      dbo.[PayrunJob].[JobStatus],
      dbo.[PayrunJob].[Forecast],
      dbo.[PayrunResult].*,
      ROW_NUMBER() OVER (
        PARTITION BY dbo.[PayrollResult].[PayrunId],
        dbo.[PayrunResult].[Name],
        dbo.[PayrunResult].[Start] ORDER BY dbo.[PayrunResult].[Created] DESC,
          dbo.[PayrunResult].[Id] DESC
        ) AS RowNumber
    FROM dbo.[PayrunResult]
    INNER JOIN dbo.[PayrollResult]
      ON dbo.[PayrollResult].[Id] = dbo.[PayrunResult].[PayrollResultId]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    WHERE (dbo.[PayrunJob].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @periodStartHashes IS NULL
        OR dbo.[PayrunResult].[StartHash] IN (
          SELECT CAST(value AS INT)
          FROM OPENJSON(@periodStartHashes)
          )
        )
      AND (
        @names IS NULL
        OR LOWER(dbo.[PayrunResult].[Name]) IN (
          SELECT LOWER(value)
          FROM OPENJSON(@names)
          )
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[PayrunResult].[Created] <= @evaluationDate
        )
    ) AS GroupPayrunResult
  WHERE RowNumber = 1;
END
GO

/****** Object:  StoredProcedure [dbo].[GetConsolidatedWageTypeCustomResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get consolidated custom wage type results
-- =============================================
CREATE PROCEDURE [dbo].[GetConsolidatedWageTypeCustomResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the wage type number: JSON array of DECIMAL(28, 6)
  @wageTypeNumbers AS VARCHAR(MAX) = NULL,
  -- the period start hashes: JSON array of INT
  @periodStartHashes AS VARCHAR(MAX) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @wageTypeNumber DECIMAL(28, 6);
  DECLARE @wageTypeCount INT;

  SELECT @wageTypeCount = COUNT(*)
  FROM OPENJSON(@wageTypeNumbers);

  -- special query for single wage type
  -- better perfomance to indexed column of the wage type number
  IF (@wageTypeCount = 1)
  BEGIN
    SELECT @wageTypeNumber = CAST(value AS DECIMAL(28, 6))
    FROM OPENJSON(@wageTypeNumbers);

    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[WageTypeCustomResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[WageTypeResult].[WageTypeNumber],
          dbo.[WageTypeCustomResult].[Start] ORDER BY dbo.[WageTypeCustomResult].[Created] DESC,
            dbo.[WageTypeCustomResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[WageTypeResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
      INNER JOIN dbo.[WageTypeCustomResult]
        ON dbo.[WageTypeResult].[Id] = dbo.[WageTypeCustomResult].[WageTypeResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrunJob].[TenantId] = @tenantId)
        AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[WageTypeCustomResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (dbo.[WageTypeCustomResult].[WageTypeNumber] = @wageTypeNumber)
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[WageTypeCustomResult].[Created] <= @evaluationDate
          )
      ) AS GroupWageTypeResult
    WHERE RowNumber = 1;
  END
  ELSE
  BEGIN
    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[WageTypeCustomResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[WageTypeResult].[WageTypeNumber],
          dbo.[WageTypeCustomResult].[Start] ORDER BY dbo.[WageTypeCustomResult].[Created] DESC,
            dbo.[WageTypeCustomResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[WageTypeResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
      INNER JOIN dbo.[WageTypeCustomResult]
        ON dbo.[WageTypeResult].[Id] = dbo.[WageTypeCustomResult].[WageTypeResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[WageTypeCustomResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (
          @wageTypeNumbers IS NULL
          OR dbo.[WageTypeCustomResult].[WageTypeNumber] IN (
            SELECT CAST(value AS DECIMAL(28, 6))
            FROM OPENJSON(@wageTypeNumbers)
            )
          )
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[WageTypeCustomResult].[Created] <= @evaluationDate
          )
      ) AS GroupWageTypeResult
    WHERE RowNumber = 1;
  END
END
GO

/****** Object:  StoredProcedure [dbo].[GetConsolidatedWageTypeResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee wage type results from a time period
-- =============================================
CREATE PROCEDURE [dbo].[GetConsolidatedWageTypeResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the wage type number: JSON array of DECIMAL(28, 6)
  @wageTypeNumbers AS VARCHAR(MAX) = NULL,
  -- the period start hashes: JSON array of INT
  @periodStartHashes AS VARCHAR(MAX) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @wageTypeNumber DECIMAL(28, 6);
  DECLARE @wageTypeCount INT;

  SELECT @wageTypeCount = COUNT(*)
  FROM OPENJSON(@wageTypeNumbers);

  -- special query for single wage type
  -- better perfomance to indexed column of the wage type number
  IF (@wageTypeCount = 1)
  BEGIN
    SELECT @wageTypeNumber = CAST(value AS DECIMAL(28, 6))
    FROM OPENJSON(@wageTypeNumbers);

    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[WageTypeResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[WageTypeResult].[WageTypeNumber],
          dbo.[WageTypeResult].[Start] ORDER BY dbo.[WageTypeResult].[Created] DESC,
            dbo.[WageTypeResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[WageTypeResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrunJob].[TenantId] = @tenantId)
        AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[WageTypeResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (dbo.[WageTypeResult].[WageTypeNumber] = @wageTypeNumber)
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[WageTypeResult].[Created] <= @evaluationDate
          )
      ) AS GroupWageTypeResult
    WHERE RowNumber = 1;
  END
  ELSE
  BEGIN
    SELECT *
    FROM (
      SELECT dbo.[PayrollResult].[EmployeeId],
        dbo.[PayrollResult].[DivisionId],
        dbo.[PayrollResult].[PayrunId],
        dbo.[PayrollResult].[PayrunJobId],
        dbo.[PayrunJob].[JobStatus],
        dbo.[PayrunJob].[Forecast],
        dbo.[WageTypeResult].*,
        ROW_NUMBER() OVER (
          PARTITION BY dbo.[PayrollResult].[PayrunId],
          dbo.[WageTypeResult].[WageTypeNumber],
          dbo.[WageTypeResult].[Start] ORDER BY dbo.[WageTypeResult].[Created] DESC,
            dbo.[WageTypeResult].[Id] DESC
          ) AS RowNumber
      FROM dbo.[WageTypeResult]
      INNER JOIN dbo.[PayrollResult]
        ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
      INNER JOIN dbo.[PayrunJob]
        ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
      WHERE (dbo.[PayrollResult].[EmployeeId] = @employeeId)
        AND (
          @divisionId IS NULL
          OR dbo.[PayrollResult].[DivisionId] = @divisionId
          )
        AND (
          @periodStartHashes IS NULL
          OR dbo.[WageTypeResult].[StartHash] IN (
            SELECT CAST(value AS INT)
            FROM OPENJSON(@periodStartHashes)
            )
          )
        AND (
          @wageTypeNumbers IS NULL
          OR dbo.[WageTypeResult].[WageTypeNumber] IN (
            SELECT CAST(value AS DECIMAL(28, 6))
            FROM OPENJSON(@wageTypeNumbers)
            )
          )
        AND (
          @jobStatus IS NULL
          OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
          )
        AND (
          [PayrunJob].[Forecast] IS NULL
          OR [PayrunJob].[Forecast] = @forecast
          )
        AND (
          @evaluationDate IS NULL
          OR dbo.[WageTypeResult].[Created] <= @evaluationDate
          )
      ) AS GroupWageTypeResult
    WHERE RowNumber = 1;
  END
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedCaseFields]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the derived case fields of payroll (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedCaseFields]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- name of the case fields: JSON array of VARCHAR(128)
  @caseFieldNames AS VARCHAR(MAX) = NULL,
  -- the include clusters: JSON array of cluster names VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of cluster names VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select the case fields by name, using the order of the payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    dbo.[Case].[Id] AS [CaseId],
    dbo.[Case].[CaseType] AS [CaseType],
    dbo.[CaseField].*
  FROM dbo.[CaseField]
  INNER JOIN dbo.[Case]
    ON dbo.[CaseField].[CaseId] = dbo.[Case].[Id]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Case].[RegulationId] = [Regulations].[Id]
  -- active case fields only
  WHERE dbo.[CaseField].[Status] = 0
    AND dbo.[CaseField].[Created] < @createdBefore
    AND (
      (
        @includeClusters IS NULL
        AND @excludeClusters IS NULL
        )
      OR dbo.IsMatchingCluster(@includeClusters, @excludeClusters, dbo.[CaseField].[Clusters]) = 1
      )
    AND (
      @caseFieldNames IS NULL
      OR LOWER(dbo.[CaseField].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@caseFieldNames)
        )
      )
  -- sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedCaseFieldsOfCase]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the derived case fields of payroll (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedCaseFieldsOfCase]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- name of the cases: JSON array of VARCHAR(128)
  @caseNames AS VARCHAR(MAX) = NULL,
  -- the include clusters: JSON array of cluster names VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of cluster names VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select the case fields by name, using the order of the payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    dbo.[Case].[Id] AS [CaseId],
    dbo.[Case].[CaseType] AS [CaseType],
    dbo.[CaseField].*
  FROM dbo.[CaseField]
  INNER JOIN dbo.[Case]
    ON dbo.[CaseField].[CaseId] = dbo.[Case].[Id]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Case].[RegulationId] = [Regulations].[Id]
  -- active case fields only
  WHERE dbo.[CaseField].[Status] = 0
    AND dbo.[CaseField].[Created] < @createdBefore
    AND (
      (
        @includeClusters IS NULL
        AND @excludeClusters IS NULL
        )
      OR dbo.IsMatchingCluster(@includeClusters, @excludeClusters, dbo.[CaseField].[Clusters]) = 1
      )
    AND (
      @caseNames IS NULL
      OR LOWER(dbo.[Case].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@caseNames)
        )
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedCaseRelations]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get derived case relations (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedCaseRelations]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the from case name
  @sourceCaseName AS NVARCHAR(128) = NULL,
  -- the to case name
  @targetCaseName AS NVARCHAR(128) = NULL,
  -- the include clusters: JSON array of cluster names VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of cluster names VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active case relation, using the from/to case name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    -- perfomance hint: don't use [CaseRelation].*
    dbo.[CaseRelation].[Id],
    dbo.[CaseRelation].[Status],
    dbo.[CaseRelation].[Created],
    dbo.[CaseRelation].[Updated],
    dbo.[CaseRelation].[RegulationId],
    dbo.[CaseRelation].[SourceCaseName],
    dbo.[CaseRelation].[SourceCaseNameLocalizations],
    dbo.[CaseRelation].[SourceCaseSlot],
    dbo.[CaseRelation].[SourceCaseSlotLocalizations],
    dbo.[CaseRelation].[TargetCaseName],
    dbo.[CaseRelation].[TargetCaseNameLocalizations],
    dbo.[CaseRelation].[TargetCaseSlot],
    dbo.[CaseRelation].[TargetCaseSlotLocalizations],
    dbo.[CaseRelation].[RelationHash],
    dbo.[CaseRelation].[BuildExpression],
    dbo.[CaseRelation].[ValidateExpression],
    dbo.[CaseRelation].[OverrideType],
    dbo.[CaseRelation].[Order],
    --   dbo.[CaseRelation].[Binary],
    dbo.[CaseRelation].[ScriptHash],
    dbo.[CaseRelation].[Attributes],
    dbo.[CaseRelation].[Clusters]
  -- excluded columns
  --dbo.[CaseRelation].[Script],
  --dbo.[CaseRelation].[ScriptVersion]
  FROM dbo.[CaseRelation]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[CaseRelation].[RegulationId] = [Regulations].[Id]
  -- active case relation only
  WHERE dbo.[CaseRelation].[Status] = 0
    AND dbo.[CaseRelation].[Created] < @createdBefore
    AND (
      @sourceCaseName IS NULL
      OR LOWER(dbo.[CaseRelation].[SourceCaseName]) = LOWER(@sourceCaseName)
      )
    AND (
      @targetCaseName IS NULL
      OR LOWER(dbo.[CaseRelation].[TargetCaseName]) = LOWER(@targetCaseName)
      )
    AND (
      (
        @includeClusters IS NULL
        AND @excludeClusters IS NULL
        )
      OR dbo.IsMatchingCluster(@includeClusters, @excludeClusters, dbo.[CaseRelation].[Clusters]) = 1
      )
  -- derived order by case relation source/target case names
  ORDER BY dbo.[CaseRelation].[SourceCaseName],
    dbo.[CaseRelation].[TargetCaseName],
    [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedCases]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived cases (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedCases]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the case type
  @caseType AS INT = NULL,
  -- the case names: JSON array of VARCHAR(128)
  @caseNames AS VARCHAR(MAX) = NULL,
  -- the include clusters: JSON array of cluster names VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of cluster names VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL,
  -- hidden case filter
  @hidden AS BIT = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active cases, using the order of case name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    -- perfomance hint: don't use [Case].*
    dbo.[Case].[Id],
    dbo.[Case].[Status],
    dbo.[Case].[Created],
    dbo.[Case].[Updated],
    dbo.[Case].[RegulationId],
    dbo.[Case].[CaseType],
    dbo.[Case].[Name],
    dbo.[Case].[NameLocalizations],
    dbo.[Case].[NameSynonyms],
    dbo.[Case].[Description],
    dbo.[Case].[DescriptionLocalizations],
    dbo.[Case].[DefaultReason],
    dbo.[Case].[DefaultReasonLocalizations],
    dbo.[Case].[BaseCase],
    dbo.[Case].[BaseCaseFields],
    dbo.[Case].[OverrideType],
    dbo.[Case].[CancellationType],
    dbo.[Case].[AvailableExpression],
    dbo.[Case].[BuildExpression],
    dbo.[Case].[ValidateExpression],
    dbo.[Case].[Lookups],
    dbo.[Case].[Slots],
    --   dbo.[Case].[Binary],
    dbo.[Case].[ScriptHash],
    dbo.[Case].[Attributes],
    dbo.[Case].[Clusters],
    dbo.[Case].[AvailableActions]
  -- excluded columns
  --dbo.[Case].[BuildActions],
  --dbo.[Case].[ValidateActions],
  --dbo.[Case].[Script],
  --dbo.[Case].[ScriptVersion]
  FROM dbo.[Case]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Case].[RegulationId] = [Regulations].[Id]
  -- active cases only
  WHERE dbo.[Case].[Status] = 0
    AND dbo.[Case].[Created] < @createdBefore
    -- hidden filter
    AND (
      @hidden IS NULL
      OR dbo.[Case].[Hidden] = @hidden
      )
    -- case type filter
    AND (
      @caseType IS NULL
      OR dbo.[Case].[CaseType] = @caseType
      )
    -- clusters filter
    AND (
      (
        @includeClusters IS NULL
        AND @excludeClusters IS NULL
        )
      OR dbo.IsMatchingCluster(@includeClusters, @excludeClusters, dbo.[Case].[Clusters]) = 1
      )
    -- case names filter
    AND (
      @caseNames IS NULL
      OR LOWER(dbo.[Case].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@caseNames)
        )
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedCollectors]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived collectors (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedCollectors]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the collector names: JSON array of VARCHAR(128)
  @collectorNames AS VARCHAR(MAX) = NULL,
  -- the include clusters: JSON array of cluster names VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of cluster names VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active collectors, using the order of collector name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    -- perfomance hint: don't use [Collector].*
    dbo.[Collector].[Id],
    dbo.[Collector].[Status],
    dbo.[Collector].[Created],
    dbo.[Collector].[Updated],
    dbo.[Collector].[RegulationId],
    dbo.[Collector].[Name],
    dbo.[Collector].[NameLocalizations],
    dbo.[Collector].[CollectMode],
    dbo.[Collector].[Negated],
    dbo.[Collector].[OverrideType],
    dbo.[Collector].[CollectorGroups],
    dbo.[Collector].[StartExpression],
    dbo.[Collector].[ApplyExpression],
    dbo.[Collector].[EndExpression],
    dbo.[Collector].[Threshold],
    dbo.[Collector].[MinResult],
    dbo.[Collector].[MaxResult],
    --   dbo.[Collector].[Binary],
    dbo.[Collector].[ScriptHash],
    dbo.[Collector].[Attributes],
    dbo.[Collector].[Clusters]
  -- excluded columns
  --dbo.[Collector].[Script],
  --dbo.[Collector].[ScriptVersion]
  FROM dbo.[Collector]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Collector].[RegulationId] = [Regulations].[Id]
  -- active collectors only
  WHERE dbo.[Collector].[Status] = 0
    AND dbo.[Collector].[Created] < @createdBefore
    AND (
      (
        @includeClusters IS NULL
        AND @excludeClusters IS NULL
        )
      OR dbo.IsMatchingCluster(@includeClusters, @excludeClusters, dbo.[Collector].[Clusters]) = 1
      )
    AND (
      @collectorNames IS NULL
      OR LOWER(dbo.[Collector].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@collectorNames)
        )
      )
  -- derived order by collector name
  ORDER BY dbo.[Collector].[Name],
    [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedLookups]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived lookups (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedLookups]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the lookup names: JSON array of VARCHAR(128)
  @lookupNames AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active lookups, using the order of lookup name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    dbo.[Lookup].*
  FROM dbo.[Lookup]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Lookup].[RegulationId] = [Regulations].[Id]
  -- active lookups only
  WHERE dbo.[Lookup].[Status] = 0
    AND dbo.[Lookup].[Created] < @createdBefore
    AND (
      @lookupNames IS NULL
      OR LOWER(dbo.[Lookup].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@lookupNames)
        )
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedLookupValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived lookup values (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedLookupValues]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the lookup names: JSON array of VARCHAR(128)
  @lookupNames AS VARCHAR(MAX) = NULL,
  -- the lookup keys: JSON array of VARCHAR(128)
  @lookupKeys AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active lookup parameters, using the order of lookup name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    dbo.[LookupValue].*
  FROM dbo.[LookupValue]
  INNER JOIN dbo.[Lookup]
    ON dbo.[LookupValue].[LookupId] = dbo.[Lookup].[Id]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Lookup].[RegulationId] = [Regulations].[Id]
  -- active lookups only
  WHERE dbo.[LookupValue].[Status] = 0
    AND dbo.[LookupValue].[Created] < @createdBefore
    AND (
      @lookupNames IS NULL
      OR LOWER(dbo.[Lookup].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@lookupNames)
        )
      )
    AND (
      -- case sensitive lookup value key
      @lookupKeys IS NULL
      OR dbo.[LookupValue].[Key] IN (
        SELECT value
        FROM OPENJSON(@lookupKeys)
        )
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedPayrollRegulations]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the derived regulations of payroll (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedPayrollRegulations]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7)
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select the derived regulations
  SELECT *
  FROM dbo.[GetDerivedRegulations](@tenantId, @payrollId, @regulationDate, @createdBefore)
  -- sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedReportParameters]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived report parameters (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedReportParameters]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the report names: JSON array of VARCHAR(128)
  @reportNames AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active report parameters, using the order of report name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    dbo.[ReportParameter].*
  FROM dbo.[ReportParameter]
  INNER JOIN dbo.[Report]
    ON dbo.[ReportParameter].[ReportId] = dbo.[Report].[Id]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Report].[RegulationId] = [Regulations].[Id]
  -- active reports only
  WHERE dbo.[ReportParameter].[Status] = 0
    AND dbo.[ReportParameter].[Created] < @createdBefore
    AND (
      @reportNames IS NULL
      OR LOWER(dbo.[Report].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@reportNames)
        )
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedReports]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived reports (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedReports]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the report names: JSON array of VARCHAR(128)
  @reportNames AS VARCHAR(MAX) = NULL,
  -- the include clusters: JSON array of cluster names VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of cluster names VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active reports, using the order of report name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    -- perfomance hint: don't use [Report].*
    dbo.[Report].[Id],
    dbo.[Report].[Status],
    dbo.[Report].[Created],
    dbo.[Report].[Updated],
    dbo.[Report].[RegulationId],
    dbo.[Report].[Name],
    dbo.[Report].[NameLocalizations],
    dbo.[Report].[Description],
    dbo.[Report].[DescriptionLocalizations],
    dbo.[Report].[Category],
    dbo.[Report].[Queries],
    dbo.[Report].[Relations],
    dbo.[Report].[AttributeMode],
    dbo.[Report].[BuildExpression],
    dbo.[Report].[StartExpression],
    dbo.[Report].[EndExpression],
    --  dbo.[Report].[Binary],
    dbo.[Report].[ScriptHash],
    dbo.[Report].[Attributes],
    dbo.[Report].[Clusters]
  -- excluded columns
  --dbo.[Report].[Script],
  --dbo.[Report].[ScriptVersion]
  FROM dbo.[Report]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Report].[RegulationId] = [Regulations].[Id]
  -- active reports only
  WHERE dbo.[Report].[Status] = 0
    AND dbo.[Report].[Created] < @createdBefore
    AND (
      (
        @includeClusters IS NULL
        AND @excludeClusters IS NULL
        )
      OR dbo.IsMatchingCluster(@includeClusters, @excludeClusters, dbo.[Report].[Clusters]) = 1
      )
    AND (
      @reportNames IS NULL
      OR LOWER(dbo.[Report].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@reportNames)
        )
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedReportTemplates]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived report templates (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedReportTemplates]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the report names: JSON array of VARCHAR(128)
  @reportNames AS VARCHAR(MAX) = NULL,
  -- the report culture
  @culture AS VARCHAR(128) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active report templates, using the order of report name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    dbo.[ReportTemplate].*
  FROM dbo.[ReportTemplate]
  INNER JOIN dbo.[Report]
    ON dbo.[ReportTemplate].[ReportId] = dbo.[Report].[Id]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Report].[RegulationId] = [Regulations].[Id]
  -- active reports only
  WHERE dbo.[ReportTemplate].[Status] = 0
    AND dbo.[ReportTemplate].[Created] < @createdBefore
    AND (
      @reportNames IS NULL
      OR LOWER(dbo.[Report].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@reportNames)
        )
      )
    AND (
      @culture IS NULL
      OR dbo.[ReportTemplate].[Culture] = @culture
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedScripts]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get the topmost derived scripts (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedScripts]
  -- the tenant
  @tenantId AS INT,
  -- the payroll
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the script names: JSON array of VARCHAR(128)
  @scriptNames AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select all active scripts, using the order of script name and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    -- perfomance hint: don't use [Script].*
    dbo.[Script].[Id],
    dbo.[Script].[Status],
    dbo.[Script].[Created],
    dbo.[Script].[Updated],
    dbo.[Script].[RegulationId],
    dbo.[Script].[Name],
    dbo.[Script].[FunctionTypeMask],
    dbo.[Script].[Value]
  FROM dbo.[Script]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[Script].[RegulationId] = [Regulations].[Id]
  -- active scripts only
  WHERE dbo.[Script].[Status] = 0
    AND dbo.[Script].[Created] < @createdBefore
    AND (
      @scriptNames IS NULL
      OR LOWER(dbo.[Script].[Name]) IN (
        SELECT LOWER(value)
        FROM OPENJSON(@scriptNames)
        )
      )
  -- derived order by sort order
  ORDER BY [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetDerivedWageTypes]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get derived wage types (only active).
-- =============================================
CREATE PROCEDURE [dbo].[GetDerivedWageTypes]
  -- the tenant
  @tenantId AS INT,
  -- the payroll,
  @payrollId AS INT,
  -- the regulation valid from date
  @regulationDate AS DATETIME2(7),
  -- creation date
  @createdBefore AS DATETIME2(7),
  -- the wage type numbers: JSON array of DECIMAL(28, 6)
  @wageTypeNumbers AS VARCHAR(MAX) = NULL,
  -- the include clusters: JSON array of cluster names VARCHAR(128)
  @includeClusters AS VARCHAR(MAX) = NULL,
  -- the exclude clusters: JSON array of cluster names VARCHAR(128)
  @excludeClusters AS VARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- select using the wage type number and payroll level
  SELECT [Regulations].[Id] AS [RegulationId],
    [Regulations].[Level] AS [Level],
    [Regulations].[Priority] AS [Priority],
    -- perfomance hint: don't use [WageType].*
    dbo.[WageType].[Id],
    dbo.[WageType].[Status],
    dbo.[WageType].[Created],
    dbo.[WageType].[Updated],
    dbo.[WageType].[RegulationId],
    dbo.[WageType].[Name],
    dbo.[WageType].[NameLocalizations],
    dbo.[WageType].[WageTypeNumber],
    dbo.[WageType].[Description],
    dbo.[WageType].[DescriptionLocalizations],
    dbo.[WageType].[OverrideType],
    dbo.[WageType].[Calendar],
    dbo.[WageType].[Collectors],
    dbo.[WageType].[CollectorGroups],
    dbo.[WageType].[ValueExpression],
    dbo.[WageType].[ResultExpression],
    --  dbo.[WageType].[Binary],
    dbo.[WageType].[ScriptHash],
    dbo.[WageType].[Attributes],
    dbo.[WageType].[Clusters]
  -- excluded columns
  -- dbo.[WageType].[Script],
  -- dbo.[WageType].[ScriptVersion],
  FROM dbo.[WageType]
  INNER JOIN dbo.GetDerivedRegulations(@tenantId, @payrollId, @regulationDate, @createdBefore) AS [Regulations]
    ON dbo.[WageType].[RegulationId] = [Regulations].[Id]
  -- active wage types only
  WHERE dbo.[WageType].[Status] = 0
    AND dbo.[WageType].[Created] < @createdBefore
    AND (
      (
        @includeClusters IS NULL
        AND @excludeClusters IS NULL
        )
      OR dbo.IsMatchingCluster(@includeClusters, @excludeClusters, dbo.[WageType].[Clusters]) = 1
      )
    AND (
      @wageTypeNumbers IS NULL
      OR dbo.[WageType].[WageTypeNumber] IN (
        SELECT CAST(value AS DECIMAL(28, 6))
        FROM OPENJSON(@wageTypeNumbers)
        )
      )
  -- derived order by wage type number
  ORDER BY dbo.[WageType].[WageTypeNumber],
    [Level] DESC,
    [Priority] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetEmployeeCaseChangeValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee case changes using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetEmployeeCaseChangeValues]
  -- the employee id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL,
  -- the cultue
  @culture AS NVARCHAR(128) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
  INTO ##EmployeeCaseChangeValuePivot
    FROM (
      SELECT
  -- tenant
  [dbo].[Employee].[TenantId],
  -- case change
  [dbo].[EmployeeCaseChange].[Id] AS CaseChangeId,
  [dbo].[EmployeeCaseChange].[Created] AS CaseChangeCreated,
  [dbo].[EmployeeCaseChange].[Reason],
  [dbo].[EmployeeCaseChange].[ValidationCaseName],
  [dbo].[EmployeeCaseChange].[CancellationType],
  [dbo].[EmployeeCaseChange].[CancellationId],
  [dbo].[EmployeeCaseChange].[CancellationDate],
  [dbo].[EmployeeCaseChange].[EmployeeId],
  [dbo].[EmployeeCaseChange].[UserId],
  [dbo].[User].[Identifier] AS UserIdentifier,
  [dbo].[EmployeeCaseChange].[DivisionId],
  -- case value
  [dbo].[EmployeeCaseValue].[Id],
  [dbo].[EmployeeCaseValue].[Created],
  [dbo].[EmployeeCaseValue].[Updated],
  [dbo].[EmployeeCaseValue].[Status],
  -- localized case name
  ' + IIF(@culture IS NULL, '[dbo].[EmployeeCaseValue].[CaseName]', 
      'dbo.GetLocalizedValue([dbo].[EmployeeCaseValue].[CaseNameLocalizations], ''' + @culture + ''', [dbo].[EmployeeCaseValue].[CaseName])') + ' AS [CaseName],
  -- localized case field name
  ' + IIF(@culture IS NULL, '[dbo].[EmployeeCaseValue].[CaseFieldName]', 'dbo.GetLocalizedValue([dbo].[EmployeeCaseValue].[CaseFieldNameLocalizations], ''' + @culture + ''', [dbo].[EmployeeCaseValue].[CaseFieldName])') + ' AS [CaseFieldName],
  -- localized case slot
  ' + IIF(@culture IS NULL, '[dbo].[EmployeeCaseValue].[CaseSlot]', 'dbo.GetLocalizedValue([dbo].[EmployeeCaseValue].[CaseSlotLocalizations], ''' + @culture + ''', [dbo].[EmployeeCaseValue].[CaseSlot])') + 
    ' AS [CaseSlot],
  [dbo].[EmployeeCaseValue].[CaseRelation],
  [dbo].[EmployeeCaseValue].[ValueType],
  [dbo].[EmployeeCaseValue].[Value],
  [dbo].[EmployeeCaseValue].[NumericValue],
  [dbo].[EmployeeCaseValue].[Start],
  [dbo].[EmployeeCaseValue].[End],
  [dbo].[EmployeeCaseValue].[Forecast],
  [dbo].[EmployeeCaseValue].[Tags],
  [dbo].[EmployeeCaseValue].[Attributes],
  -- documents
  (
      SELECT Count(*)
      FROM [dbo].[EmployeeCaseDocument]
      WHERE [CaseValueId] = [dbo].[EmployeeCaseValue].[Id]
      ) AS Documents'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[EmployeeCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N' FROM [dbo].[EmployeeCaseValue]
        LEFT JOIN [dbo].[EmployeeCaseValueChange]
          ON [dbo].[EmployeeCaseValue].[Id] = [dbo].[EmployeeCaseValueChange].[CaseValueId]
        LEFT JOIN [dbo].[EmployeeCaseChange]
          ON [dbo].[EmployeeCaseValueChange].[CaseChangeId] = [dbo].[EmployeeCaseChange].[Id]
        LEFT JOIN [dbo].[User]
          ON [dbo].[User].[Id] = [dbo].[EmployeeCaseChange].[UserId]
        LEFT JOIN [dbo].[Employee]
          ON [dbo].[Employee].[Id] = [dbo].[EmployeeCaseChange].[EmployeeId]
          WHERE ([dbo].[EmployeeCaseChange].[EmployeeId] = ' + CONVERT(VARCHAR(10), @parentId) + ')) AS ECCV';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- start cleanup
  DROP TABLE

  IF EXISTS ##EmployeeCaseChangeValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- end cleanup
  DROP TABLE

  IF EXISTS ##EmployeeCaseChangeValuePivot
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetEmployeeCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee case values using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetEmployeeCaseValues]
  -- the employee id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
    INTO ##EmployeeCaseValuePivot
    FROM (
      SELECT [dbo].[EmployeeCaseValue].*'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[EmployeeCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N'  FROM dbo.EmployeeCaseValue
      WHERE EmployeeCaseValue.EmployeeId = ' + CAST(@parentId AS VARCHAR(10)) + ') AS ECVA';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- cleanup
  DROP TABLE

  IF EXISTS ##EmployeeCaseValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- cleanup
  DROP TABLE

  IF EXISTS ##EmployeeCaseValuePivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetGlobalCaseChangeValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get global case changes using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetGlobalCaseChangeValues]
  -- the global id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL,
  -- the cultue
  @culture AS NVARCHAR(128) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
  INTO ##GlobalCaseChangeValuePivot
    FROM (
      SELECT
  -- tenant
  [dbo].[GlobalCaseChange].[TenantId],
  -- case change
  [dbo].[GlobalCaseChange].[Id] AS CaseChangeId,
  [dbo].[GlobalCaseChange].[Created] AS CaseChangeCreated,
  [dbo].[GlobalCaseChange].[Reason],
  [dbo].[GlobalCaseChange].[ValidationCaseName],
  [dbo].[GlobalCaseChange].[CancellationType],
  [dbo].[GlobalCaseChange].[CancellationId],
  [dbo].[GlobalCaseChange].[CancellationDate],
  NULL AS [EmployeeId],
  [dbo].[GlobalCaseChange].[UserId],
  [dbo].[User].[Identifier] AS UserIdentifier,
  [dbo].[GlobalCaseChange].[DivisionId],
  -- case value
  [dbo].[GlobalCaseValue].[Id],
  [dbo].[GlobalCaseValue].[Created],
  [dbo].[GlobalCaseValue].[Updated],
  [dbo].[GlobalCaseValue].[Status],
  -- localized case name
  ' + IIF(@culture IS NULL, '[dbo].[GlobalCaseValue].[CaseName]', 'dbo.GetLocalizedValue([dbo].[GlobalCaseValue].[CaseNameLocalizations], ''' + @culture + 
      ''', [dbo].[GlobalCaseValue].[CaseName])') + ' AS [CaseName],
  -- localized case field name
  ' + IIF(@culture IS NULL, '[dbo].[GlobalCaseValue].[CaseFieldName]', 'dbo.GetLocalizedValue([dbo].[GlobalCaseValue].[CaseFieldNameLocalizations], ''' + @culture + ''', [dbo].[GlobalCaseValue].[CaseFieldName])') + ' AS [CaseFieldName],
  -- localized case slot
  ' + IIF(@culture IS NULL, '[dbo].[GlobalCaseValue].[CaseSlot]', 'dbo.GetLocalizedValue([dbo].[GlobalCaseValue].[CaseSlotLocalizations], ''' + @culture + ''', [dbo].[GlobalCaseValue].[CaseSlot])') + 
    ' AS [CaseSlot],
  [dbo].[GlobalCaseValue].[CaseRelation],
  [dbo].[GlobalCaseValue].[ValueType],
  [dbo].[GlobalCaseValue].[Value],
  [dbo].[GlobalCaseValue].[NumericValue],
  [dbo].[GlobalCaseValue].[Start],
  [dbo].[GlobalCaseValue].[End],
  [dbo].[GlobalCaseValue].[Forecast],
  [dbo].[GlobalCaseValue].[Tags],
  [dbo].[GlobalCaseValue].[Attributes],
  -- documents
  (
      SELECT Count(*)
      FROM [dbo].[GlobalCaseDocument]
      WHERE [CaseValueId] = [dbo].[GlobalCaseValue].[Id]
      ) AS Documents'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[GlobalCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N'  FROM [dbo].[GlobalCaseValue]
        LEFT JOIN [dbo].[GlobalCaseValueChange]
          ON [dbo].[GlobalCaseValue].[Id] = [dbo].[GlobalCaseValueChange].[CaseValueId]
        LEFT JOIN [dbo].[GlobalCaseChange]
          ON [dbo].[GlobalCaseValueChange].[CaseChangeId] = [dbo].[GlobalCaseChange].[Id]
        LEFT JOIN [dbo].[User]
          ON [dbo].[User].[Id] = [dbo].[GlobalCaseChange].[UserId]
          WHERE ([dbo].[GlobalCaseChange].[TenantId] = ' + CONVERT(VARCHAR(10), @parentId) + ')) AS GCCV';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- start cleanup
  DROP TABLE

  IF EXISTS ##GlobalCaseChangeValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- cleanup
  DROP TABLE

  IF EXISTS ##GlobalCaseChangeValuePivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetGlobalCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get global case values using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetGlobalCaseValues]
  -- the global id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
    INTO ##GlobalCaseValuePivot
    FROM (
      SELECT [dbo].[GlobalCaseValue].*'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[GlobalCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N'  FROM dbo.GlobalCaseValue
      WHERE GlobalCaseValue.TenantId = ' + CAST(@parentId AS VARCHAR(10)) + ') AS GCVA';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- cleanup
  DROP TABLE

  IF EXISTS ##GlobalCaseValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- cleanup
  DROP TABLE

  IF EXISTS ##GlobalCaseValuePivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetLookupRangeValue]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get all base payroll ids, starting from the derived regulation until the root regulation
--	
CREATE PROCEDURE [dbo].[GetLookupRangeValue]
  -- the lookup
  @lookupId AS INT,
  -- the range value
  @rangeValue AS DECIMAL(28, 6),
  -- the lookup value key hash
  @keyHash AS INT = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @rangeSize DECIMAL(28, 6)
  DECLARE @minValue DECIMAL(28, 6)
  DECLARE @maxValue DECIMAL(28, 6)

  -- get range data
  SELECT @rangeSize = [RangeSize]
  FROM dbo.[Lookup]
  WHERE dbo.[Lookup].[Id] = @lookupId

  IF (@rangeSize IS NULL)
  BEGIN
    SET @rangeSize = 0.0
  END

  -- get min/max values
  SELECT @minValue = MIN([RangeValue]),
    @maxValue = MAX([RangeValue]) + @rangeSize
  FROM dbo.[LookupValue]
  INNER JOIN [dbo].[Lookup]
    ON [dbo].[LookupValue].[LookupId] = [dbo].[Lookup].[Id]
  WHERE dbo.[Lookup].[Id] = @lookupId

  -- out of boundaries
  IF (@minValue IS NULL)
    OR (@rangeValue < @minValue)
    OR (@rangeValue > @maxValue)
  BEGIN
    RETURN NULL
  END

  -- select lookup value with the next smaller range value
  SELECT TOP 1 *
  FROM dbo.[LookupValue]
  INNER JOIN [dbo].[Lookup]
    ON [dbo].[LookupValue].[LookupId] = [dbo].[Lookup].[Id]
  WHERE dbo.[Lookup].[Id] = @lookupId
    AND dbo.[LookupValue].[RangeValue] <= @rangeValue
    AND (
      @keyHash IS NULL
      OR dbo.[LookupValue].[KeyHash] = @keyHash
      )
  ORDER BY dbo.[LookupValue].[RangeValue] DESC
END
GO

/****** Object:  StoredProcedure [dbo].[GetNationalCaseChangeValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get national case changes using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetNationalCaseChangeValues]
  -- the national id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL,
  -- the cultue
  @culture AS NVARCHAR(128) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
  INTO ##NationalCaseChangeValuePivot
    FROM (
      SELECT
  -- tenant
  [dbo].[NationalCaseChange].[TenantId],
  -- case change
  [dbo].[NationalCaseChange].[Id] AS CaseChangeId,
  [dbo].[NationalCaseChange].[Created] AS CaseChangeCreated,
  [dbo].[NationalCaseChange].[Reason],
  [dbo].[NationalCaseChange].[ValidationCaseName],
  [dbo].[NationalCaseChange].[CancellationType],
  [dbo].[NationalCaseChange].[CancellationId],
  [dbo].[NationalCaseChange].[CancellationDate],
  NULL AS [EmployeeId],
  [dbo].[NationalCaseChange].[UserId],
  [dbo].[User].[Identifier] AS UserIdentifier,
  [dbo].[NationalCaseChange].[DivisionId],
  -- case value
  [dbo].[NationalCaseValue].[Id],
  [dbo].[NationalCaseValue].[Created],
  [dbo].[NationalCaseValue].[Updated],
  [dbo].[NationalCaseValue].[Status],
    -- localized case name
  ' + IIF(@culture IS NULL, '[dbo].[NationalCaseValue].[CaseName]', 
      'dbo.GetLocalizedValue([dbo].[NationalCaseValue].[CaseNameLocalizations], ''' + @culture + ''', [dbo].[NationalCaseValue].[CaseName])') + ' AS [CaseName],
  -- localized case field name
  ' + IIF(@culture IS NULL, '[dbo].[NationalCaseValue].[CaseFieldName]', 'dbo.GetLocalizedValue([dbo].[NationalCaseValue].[CaseFieldNameLocalizations], ''' + @culture + ''', [dbo].[NationalCaseValue].[CaseFieldName])') + ' AS [CaseFieldName],
  -- localized case slot
  ' + IIF(@culture IS NULL, '[dbo].[NationalCaseValue].[CaseSlot]', 'dbo.GetLocalizedValue([dbo].[NationalCaseValue].[CaseSlotLocalizations], ''' + @culture + ''', [dbo].[NationalCaseValue].[CaseSlot])') + 
    ' AS [CaseSlot],
  [dbo].[NationalCaseValue].[CaseRelation],
  [dbo].[NationalCaseValue].[ValueType],
  [dbo].[NationalCaseValue].[Value],
  [dbo].[NationalCaseValue].[NumericValue],
  [dbo].[NationalCaseValue].[Start],
  [dbo].[NationalCaseValue].[End],
  [dbo].[NationalCaseValue].[Forecast],
  [dbo].[NationalCaseValue].[Tags],
  [dbo].[NationalCaseValue].[Attributes],
  -- documents
  (
      SELECT Count(*)
      FROM [dbo].[NationalCaseDocument]
      WHERE [CaseValueId] = [dbo].[NationalCaseValue].[Id]
      ) AS Documents'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[NationalCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N'  FROM [dbo].[NationalCaseValue]
        LEFT JOIN [dbo].[NationalCaseValueChange]
          ON [dbo].[NationalCaseValue].[Id] = [dbo].[NationalCaseValueChange].[CaseValueId]
        LEFT JOIN [dbo].[NationalCaseChange]
          ON [dbo].[NationalCaseValueChange].[CaseChangeId] = [dbo].[NationalCaseChange].[Id]
        LEFT JOIN [dbo].[User]
          ON [dbo].[User].[Id] = [dbo].[NationalCaseChange].[UserId]
          WHERE ([dbo].[NationalCaseChange].[TenantId] = ' + CONVERT(VARCHAR(10), @parentId) + ')) AS NCCV';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- start cleanup
  DROP TABLE

  IF EXISTS ##NationalCaseChangeValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- cleanup
  DROP TABLE

  IF EXISTS ##NationalCaseChangeValuePivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetNationalCaseValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get national case values using the attributes pivot
-- do not change the parameter names!
-- =============================================
CREATE PROCEDURE [dbo].[GetNationalCaseValues]
  -- the national id
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
    INTO ##NationalCaseValuePivot
    FROM (
      SELECT [dbo].[NationalCaseValue].*'
  -- pivot sql part 2: attribute queries
  SET @attributeSql = dbo.BuildAttributeQuery('[dbo].[NationalCaseValue].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  -- pivot sql part 3
  SET @pivotSql = @pivotSql + N'  FROM dbo.NationalCaseValue
      WHERE NationalCaseValue.TenantId = ' + CAST(@parentId AS VARCHAR(10)) + ') AS NCVA';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- cleanup
  DROP TABLE

  IF EXISTS ##NationalCaseValuePivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql

  -- cleanup
  DROP TABLE

  IF EXISTS ##NationalCaseValuePivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetPayrollResultValues]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Payroll result values
-- =============================================
CREATE PROCEDURE [dbo].[GetPayrollResultValues]
  -- the parent id (unsuses, required from case value query)
  @parentId AS INT,
  -- the query sql
  @sql AS NVARCHAR(MAX),
  -- the employee id
  @employeeId AS INT = NULL,
  -- the attribute names: JSON array of VARCHAR(128)
  @attributes AS NVARCHAR(MAX) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  -- pivot select
  DECLARE @pivotSql AS NVARCHAR(MAX);
  DECLARE @attributeSql AS NVARCHAR(MAX);

  -- pivot sql begin part
  -- pivot sql part 1
  SET @pivotSql = N'SELECT *
    INTO ##PayrollResultPivot
    FROM (
'
  SET @pivotSql = @pivotSql + 
    N'
  SELECT
  -- tenant
  [PayrollResult].[TenantId],
  -- payroll result
  [PayrollResult].[Id] AS [PayrollResultId],
  [PayrollResult].[Created],
  -- payroll value
  [PayrollValue].[ResultKind],
  [PayrollValue].[ResultId],
  [PayrollValue].[ResultParentId],
  [PayrollValue].[ResultNumber],
  [PayrollValue].[KindName],
  [PayrollValue].[ResultCreated],
  [PayrollValue].[ResultStart],
  [PayrollValue].[ResultEnd],
  [PayrollValue].[ResultType],
  [PayrollValue].[ResultValue],
  [PayrollValue].[ResultNumericValue],
  [PayrollValue].[ResultTags],
  [PayrollValue].[Attributes],
  -- payrun job
  [PayrunJob].[Id] AS [JobId],
  [PayrunJob].[Name] AS [JobName],
  [PayrunJob].[CreatedReason] AS [JobReason],
  [PayrunJob].[Forecast],
  [PayrunJob].[JobStatus],
  [PayrunJob].[CycleName],
  [PayrunJob].[PeriodName],
  [PayrunJob].[PeriodStart],
  [PayrunJob].[PeriodEnd],
  -- payrun
  [Payrun].[Id] AS [PayrunId],
  [Payrun].[Name] AS [PayrunName],
  -- payroll
  [Payroll].[Id] AS [PayrollId],
  [Payroll].[Name] AS [PayrollName],
  -- division
  [Division].[Id] AS [DivisionId],
  [Division].[Name] AS [DivisionName],
  [Division].[Culture],
  -- user
  [User].[Id] AS [UserId],
  [User].[Identifier] AS [UserIdentifier],
  -- employee
  [Employee].[Id] AS [EmployeeId],
  [Employee].[Identifier] AS [EmployeeIdentifier]'
  SET @attributeSql = dbo.GetAttributeNames(@attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  SET @pivotSql = @pivotSql + '
FROM (
'
  -- pivot sql collector result
  SET @pivotSql = @pivotSql + N'
    -- collector results
  SELECT 10 AS [ResultKind], -- 10: collector
    [PayrollResultId],
    [CollectorResult].[Id] AS [ResultId],
    [PayrollResultId] AS [ResultParentId],
    [CollectorName] AS [KindName],
    0 AS [ResultNumber], -- no custom result
    [CollectorResult].[Created] AS [ResultCreated],
    [CollectorResult].[Start] AS [ResultStart],
    [CollectorResult].[End] AS [ResultEnd],
    [CollectorResult].[Tags] AS [ResultTags],
    [CollectorResult].[Attributes],
    [CollectorResult].[ValueType] AS [ResultType],
    LTRIM([CollectorResult].[Value]) AS [ResultValue],
    [CollectorResult].[Value] AS [ResultNumericValue]';
  SET @attributeSql = dbo.BuildAttributeQuery('[CollectorResult].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  SET @pivotSql = @pivotSql + N'
    FROM [dbo].[CollectorResult]
  
    UNION ALL

'
  -- pivot sql collector custom result
  SET @pivotSql = @pivotSql + N'
    -- collector custom results
  SELECT 11 AS [ResultKind], -- 11: collector custom
    [PayrollResultId],
    [CollectorCustomResult].[Id] AS [ResultId],
    [CollectorResult].[Id] AS [ResultParentId],
    [CollectorCustomResult].[Source] AS [KindName],
    0 AS [ResultNumber], -- no custom result
    [CollectorCustomResult].[Created] AS [ResultCreated],
    [CollectorCustomResult].[Start] AS [ResultStart],
    [CollectorCustomResult].[End] AS [ResultEnd],
    [CollectorCustomResult].[Tags] AS [ResultTags],
    [CollectorCustomResult].[Attributes],
    [CollectorCustomResult].[ValueType] AS [ResultType],
    LTRIM([CollectorCustomResult].[Value]) AS [ResultValue],
    [CollectorCustomResult].[Value] AS [ResultNumericValue]';
  SET @attributeSql = dbo.BuildAttributeQuery('[CollectorCustomResult].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  SET @pivotSql = @pivotSql + N'
    FROM [dbo].[CollectorResult]
  INNER JOIN [dbo].[CollectorCustomResult]
    ON [CollectorResult].[Id] = [CollectorCustomResult].[CollectorResultId]
  
  UNION ALL

'
  -- pivot sql wage type result
  SET @pivotSql = @pivotSql + N'
    -- wage type results
  SELECT 20 AS [ResultKind], -- 20: wage type
    [PayrollResultId],
    [WageTypeResult].[Id] AS [ResultId],
    [PayrollResultId] AS [ResultParentId],
    [WageTypeName] AS [KindName],
    [WageTypeNumber] AS [ResultNumber],
    [WageTypeResult].[Created] AS [ResultCreated],
    [WageTypeResult].[Start] AS [ResultStart],
    [WageTypeResult].[End] AS [ResultEnd],
    [WageTypeResult].[Tags] AS [ResultTags],
    [WageTypeResult].[Attributes],
    [WageTypeResult].[ValueType] AS [ResultType],
    LTRIM([WageTypeResult].[Value]) AS [ResultValue],
    [WageTypeResult].[Value] AS [ResultNumericValue]';
  SET @attributeSql = dbo.BuildAttributeQuery('[WageTypeResult].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  SET @pivotSql = @pivotSql + N'
    FROM [dbo].[WageTypeResult]
  
  UNION ALL

'
  -- pivot sql wage type custom result
  SET @pivotSql = @pivotSql + N'
    -- wage type custom results
  SELECT 21 AS [ResultKind], -- 21: wage type custom
    [PayrollResultId],
    [WageTypeCustomResult].[Id] AS [ResultId],
    [WageTypeResult].[Id] AS [ResultParentId],
    [WageTypeCustomResult].[Source] AS [KindName],
    0 AS [ResultNumber], -- no custom result
    [WageTypeCustomResult].[Created] AS [ResultCreated],
    [WageTypeCustomResult].[Start] AS [ResultStart],
    [WageTypeCustomResult].[End] AS [ResultEnd],
    [WageTypeCustomResult].[Tags] AS [ResultTags],
    [WageTypeCustomResult].[Attributes],
    [WageTypeCustomResult].[ValueType] AS [ResultType],
    LTRIM([WageTypeCustomResult].[Value]) AS [ResultValue],
    [WageTypeCustomResult].[Value] AS [ResultNumericValue]';
  SET @attributeSql = dbo.BuildAttributeQuery('[WageTypeCustomResult].[Attributes]', @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  SET @pivotSql = @pivotSql + N'
    FROM [dbo].[WageTypeResult]
  INNER JOIN [dbo].[WageTypeCustomResult]
    ON [WageTypeResult].[Id] = [WageTypeCustomResult].[WageTypeResultId]
  
  UNION ALL

'
  -- pivot sql payrun result
  SET @pivotSql = @pivotSql + N'
    -- payrun results
  SELECT 30 AS [ResultKind], -- 30: payrun
    [PayrollResultId],
    [PayrunResult].[Id] AS [ResultId],
    [PayrollResultId] AS [ResultParentId],
    [PayrunResult].[Name] AS [KindName],
    0 AS [ResultNumber], -- no custom results
    [PayrunResult].[Created] AS [ResultCreated],
    [PayrunResult].[Start] AS [ResultStart],
    [PayrunResult].[End] AS [ResultEnd],
    [PayrunResult].[Tags] AS [ResultTags],
    [PayrunResult].[Attributes],
    [PayrunResult].[ValueType] AS [ResultType],
    LTRIM([PayrunResult].[Value]) AS [ResultValue],
    [PayrunResult].[NumericValue] AS [ResultNumericValue]';
  SET @attributeSql = dbo.BuildAttributeQuery(NULL, @attributes);
  SET @pivotSql = @pivotSql + @attributeSql;
  SET @pivotSql = @pivotSql + N'
    FROM [dbo].[PayrunResult]
'
  -- pivot sql end part
  SET @pivotSql = @pivotSql + N'
  ) PayrollValue
LEFT JOIN
  -- payroll result
  [dbo].[PayrollResult]
  ON [PayrollResult].[Id] = [PayrollValue].[PayrollResultId]
LEFT JOIN
  -- parun job
  [dbo].[PayrunJob]
  ON [PayrollResult].[PayrunJobId] = [PayrunJob].[Id]
LEFT JOIN
  -- payrun
  [dbo].[Payrun]
  ON [PayrunJob].[PayrunId] = [Payrun].[Id]
LEFT JOIN
  -- employee
  [dbo].[Employee]
  ON [PayrollResult].[EmployeeId] = [Employee].[Id]
LEFT JOIN
  -- payroll
  [dbo].[Payroll]
  ON [PayrollResult].[PayrollId] = [Payroll].[Id]
LEFT JOIN
  -- division
  [dbo].[Division]
  ON [Payroll].[DivisionId] = [Division].[Id]
LEFT JOIN
  -- user
  [dbo].[User]
  ON [PayrunJob].[CreatedUserId] = [User].Id ' + IIF(@employeeId IS NULL, N'', N'WHERE [dbo].[Employee].[Id] = ' + cast(@employeeId AS VARCHAR(10))) + N') AS PCV';

  -- debug help
  --PRINT CAST(@pivotSql AS NTEXT);
  -- transaction start
  BEGIN TRANSACTION;

  -- cleanup
  DROP TABLE

  IF EXISTS ##PayrollResultPivot;
    -- build pivot table
    EXECUTE dbo.sp_executesql @pivotSql;

  -- apply query to pivot table
  EXECUTE dbo.sp_executesql @sql;

  -- cleanup
  DROP TABLE

  IF EXISTS ##PayrollResultPivot;
    -- transaction end
    COMMIT TRANSACTION;
END
GO

/****** Object:  StoredProcedure [dbo].[GetWageTypeCustomResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee wage type custom results from a time period
-- =============================================
CREATE PROCEDURE [dbo].[GetWageTypeCustomResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the payrun job id
  @payrunJobId AS INT = NULL,
  -- the parent payrun job id
  @parentPayrunJobId AS INT = NULL,
  -- the wage type numbers: JSON array of DECIMAL(28, 6)
  @wageTypeNumbers AS VARCHAR(MAX) = NULL,
  -- period start
  @periodStart AS DATETIME2(7) = NULL,
  -- period end
  @periodEnd AS DATETIME2(7) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @wageTypeNumber DECIMAL(28, 6);
  DECLARE @wageTypeCount INT;

  SELECT @wageTypeCount = COUNT(*)
  FROM OPENJSON(@wageTypeNumbers);

  -- special query for single wage type
  -- better perfomance to indexed column of the wage type number
  IF (@wageTypeCount = 1)
  BEGIN
    SELECT @wageTypeNumber = CAST(value AS DECIMAL(28, 6))
    FROM OPENJSON(@wageTypeNumbers);

    SELECT TOP (100) PERCENT dbo.[WageTypeCustomResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[WageTypeResult]
      ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
    INNER JOIN dbo.[WageTypeCustomResult]
      ON dbo.[WageTypeResult].[Id] = dbo.[WageTypeCustomResult].[WageTypeResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (dbo.[WageTypeResult].[WageTypeNumber] = @wageTypeNumber)
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[WageTypeResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[WageTypeResult].[Created]
  END
  ELSE
  BEGIN
    SELECT TOP (100) PERCENT dbo.[WageTypeCustomResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[WageTypeResult]
      ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
    INNER JOIN dbo.[WageTypeCustomResult]
      ON dbo.[WageTypeResult].[Id] = dbo.[WageTypeCustomResult].[WageTypeResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (
        @wageTypeNumbers IS NULL
        OR dbo.[WageTypeResult].[WageTypeNumber] IN (
          SELECT CAST(value AS DECIMAL(28, 6))
          FROM OPENJSON(@wageTypeNumbers)
          )
        )
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[WageTypeResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[WageTypeResult].[Created]
  END
END
GO

/****** Object:  StoredProcedure [dbo].[GetWageTypeResults]    Script Date: 17.07.2023 15:01:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get employee wage type results from a time period
-- =============================================
CREATE PROCEDURE [dbo].[GetWageTypeResults]
  -- the tenant id
  @tenantId AS INT,
  -- the employee id
  @employeeId AS INT,
  -- the division id
  @divisionId AS INT = NULL,
  -- the payrun job id
  @payrunJobId AS INT = NULL,
  -- the parent payrun job id
  @parentPayrunJobId AS INT = NULL,
  -- the wage type numbers: JSON array of DECIMAL(28, 6)
  @wageTypeNumbers AS VARCHAR(MAX) = NULL,
  -- period start
  @periodStart AS DATETIME2(7) = NULL,
  -- period end
  @periodEnd AS DATETIME2(7) = NULL,
  -- payrun job status (bit mask)
  @jobStatus AS INT = NULL,
  -- the forecast name
  @forecast AS VARCHAR(128) = NULL,
  -- evaluation date
  @evaluationDate AS DATETIME2(7) = NULL
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from
  -- interfering with SELECT statements
  SET NOCOUNT ON;

  DECLARE @wageTypeNumber DECIMAL(28, 6);
  DECLARE @wageTypeCount INT;

  SELECT @wageTypeCount = COUNT(*)
  FROM OPENJSON(@wageTypeNumbers);

  -- special query for single wage type
  -- better perfomance to indexed column of the wage type number
  IF (@wageTypeCount = 1)
  BEGIN
    SELECT @wageTypeNumber = CAST(value AS DECIMAL(28, 6))
    FROM OPENJSON(@wageTypeNumbers);

    SELECT TOP (100) PERCENT dbo.[WageTypeResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[WageTypeResult]
      ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (dbo.[WageTypeResult].[WageTypeNumber] = @wageTypeNumber)
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[WageTypeResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[WageTypeResult].[Created]
  END
  ELSE
  BEGIN
    SELECT TOP (100) PERCENT dbo.[WageTypeResult].*
    FROM dbo.[PayrollResult]
    INNER JOIN dbo.[PayrunJob]
      ON dbo.[PayrollResult].[PayrunJobId] = dbo.[PayrunJob].[Id]
    INNER JOIN dbo.[WageTypeResult]
      ON dbo.[PayrollResult].[Id] = dbo.[WageTypeResult].[PayrollResultId]
    WHERE (dbo.[PayrollResult].[TenantId] = @tenantId)
      AND (dbo.[PayrollResult].[EmployeeId] = @employeeId)
      AND (
        @divisionId IS NULL
        OR dbo.[PayrollResult].[DivisionId] = @divisionId
        )
      AND (
        @payrunJobId IS NULL
        OR dbo.[PayrunJob].[Id] = @payrunJobId
        )
      AND (
        @parentPayrunJobId IS NULL
        OR dbo.[PayrunJob].[ParentJobId] = @parentPayrunJobId
        )
      AND (
        @wageTypeNumbers IS NULL
        OR dbo.[WageTypeResult].[WageTypeNumber] IN (
          SELECT CAST(value AS DECIMAL(28, 6))
          FROM OPENJSON(@wageTypeNumbers)
          )
        )
      AND (
        (
          @periodStart IS NULL
          AND @periodEnd IS NULL
          )
        OR dbo.[PayrunJob].[PeriodStart] BETWEEN @periodStart
          AND @periodEnd
        )
      AND (
        @jobStatus IS NULL
        OR dbo.[PayrunJob].[JobStatus] & @jobStatus = dbo.[PayrunJob].[JobStatus]
        )
      AND (
        [PayrunJob].[Forecast] IS NULL
        OR [PayrunJob].[Forecast] = @forecast
        )
      AND (
        @evaluationDate IS NULL
        OR dbo.[WageTypeResult].[Created] <= @evaluationDate
        )
    ORDER BY dbo.[WageTypeResult].[Created]
  END
END
GO
-- --------------------------------------------------------------------------------
-- Version.sql
-- Update Payroll Engine Database Version
-- --------------------------------------------------------------------------------

IF DB_NAME() <> 'PayrollEngine' BEGIN
  RAISERROR( 'Error: Wrong database, expecting PayrollEngine.', 16, 10 )
  RETURN
END

-- database version
DECLARE @errorID int
INSERT INTO [Version] (
	MajorVersion,
	MinorVersion,
	SubVersion,
	[Owner],
	[Description] )
VALUES (
	0,
	5,
	1,
	CURRENT_USER,
	'Payroll Engine: initial database setup' )
SET @errorID = @@ERROR
IF ( @errorID <> 0 ) BEGIN
	PRINT 'Error while updating the Payroll Engine database version.'
END
ELSE BEGIN
	PRINT 'Payroll Engine database version successfully updated to release 0.5.1'
END

