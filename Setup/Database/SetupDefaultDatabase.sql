-- --------------------------------------------------------------------------------
-- CreateDefaultDatabase.sql
-- --------------------------------------------------------------------------------

-- select root
USE master
GO

-- check database
DECLARE @dbname nvarchar(128)
SET @dbname = N'PayrollEngine'
IF EXISTS ( SELECT name FROM master.dbo.sysdatabases WHERE name = N'PayrollEngine') BEGIN
  RAISERROR( 'Error: Database PayrollEngine already exists.', 16, 10 )
  RETURN
END

-- data file path
DECLARE @DefaultDataPath varchar(max)
SET @DefaultDataPath = (SELECT CONVERT(varchar(max), SERVERPROPERTY('INSTANCEDEFAULTDATAPATH')))
DECLARE @DefaultLogPath varchar(max)
SET @DefaultLogPath = (SELECT CONVERT(varchar(max), SERVERPROPERTY('INSTANCEDEFAULTLOGPATH')))

-- create database
DECLARE @sql nvarchar(MAX)
DECLARE @error int
SET @error = -1;
SELECT @sql = 'CREATE DATABASE [PayrollEngine] ON PRIMARY ( ' +
			    'NAME = PayrollEngine, ' +
                'FILENAME = ''' + @DefaultDataPath + 'PayrollEngine.mdf'', SIZE = 167872KB, MAXSIZE = UNLIMITED, FILEGROWTH = 16384KB ) ' +
			    'LOG ON ( ' +
			    'NAME = PayrollEngineLog, ' +
			    'FILENAME = ''' + @DefaultLogPath + 'PayrollEngine_log.ldf'', SIZE = 2048KB, MAXSIZE = 2048GB, FILEGROWTH = 16384KB ) ' +
			    'COLLATE SQL_Latin1_General_CP1_CS_AS;'
EXEC (@sql)
PRINT @sql
SET @error = @@ERROR
IF ( @error <> 0 ) BEGIN
	PRINT 'Error while updating the database version.'
END
ELSE BEGIN
	PRINT 'Database PayrollEngine successfully created'
END

GO

-- test new database
IF NOT EXISTS ( SELECT name FROM master.dbo.sysdatabases WHERE name = N'PayrollEngine') BEGIN
  RAISERROR( 'Error: Database PayrollEngine not created.', 16, 10 )
  RETURN
END

-- use the new database
USE [PayrollEngine]

