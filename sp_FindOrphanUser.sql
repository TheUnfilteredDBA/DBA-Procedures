USE [master]
GO

CREATE OR ALTER PROCEDURE sp_FindOrphanUser @DatabaseName sysname = NULL
AS

BEGIN

IF (@DatabaseName IS NOT NULL AND LEFT(@DatabaseName, 1) = '[' and RIGHT (@DatabaseName, 1) = ']')
	BEGIN
	PRINT 'Adjusting database name to fit expected format...'
	SET @DatabaseName = (SELECT REPLACE(@DatabaseName, '[', ''))
	SET @DatabaseName = (SELECT REPLACE(@DatabaseName, ']', ''))
	END

DECLARE @command varchar(4000)

IF (@DatabaseName IS NOT NULL)
BEGIN
	DECLARE @exec nvarchar(max) = QUOTENAME(@DatabaseName) + N'.sys.sp_executesql',
        @sql  nvarchar(max) = N'BEGIN
		INSERT INTO #tblTempOrphan
		SELECT DISTINCT @@SERVERNAME, @DatabaseName as DatabaseName, dp.name AS [User], dp.sid, dp.type_desc, dp.authentication_type_desc, ''['' + dp.name + ''] is an orphan user in the '' + ''['' + @DatabaseName +  ''] database.'' + '' This means that they do not have a corresponding server login. The orphan user should be repaired or dropped.'' AS [Report], ''CREATE LOGIN ['' + dp.name + ''] WITH PASSWORD = '''' '''' / FROM WINDOWS '' + '' USE ['' + @DatabaseName + ''] ALTER USER ['' + dp.name + ''] WITH Login = ['' + dp.name + '']''as [repair_orphan_user], ''USE ['' + @DatabaseName + ''] DROP USER ['' + dp.name + '']'' as [drop_orphan_user]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphan3
		SELECT ''USE '' + ''['' + @DatabaseName + ''] '' + ''EXEC sp_change_users_login ''' + '''UPDATE_ONE''' + ''','''''' + dp.name + '''''','''''' + sp.name + '''''''' AS [link_to_existing_login]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid <> sp.sid
		and dp.name COLLATE DATABASE_DEFAULT = sp.name COLLATE DATABASE_DEFAULT
		where dp.is_fixed_role = 0 and sp.is_fixed_role = 0
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphan5
		SELECT dp.name AS [DB User], s.name AS [Schema], ''USE ['' + @DatabaseName + ''] ALTER AUTHORIZATION ON SCHEMA::['' + s.name + ''] TO [dbo]'' AS AlterAuthorization
		FROM sys.database_principals AS dp
		JOIN sys.schemas s ON s.principal_id = dp.principal_id
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')
		and s.name <> ''dbo''
	END';
	
	
	IF OBJECT_ID('tempdb..#tblTempOrphan') IS NOT NULL DROP TABLE #tblTempOrphan
	IF OBJECT_ID('tempdb..#tblTempOrphan3') IS NOT NULL DROP TABLE #tblTempOrphan3
	IF OBJECT_ID('tempdb..#tblTempOrphan3') IS NOT NULL DROP TABLE #tblTempOrphan5
	CREATE TABLE #tblTempOrphan ([ComputerName] varchar (100),  [DatabaseName] varchar(100), [User] varchar(100), [sid] varbinary(100), [type_desc] varchar(100), [authentication_type_desc] varchar(100), [Report] varchar (300), [repair_orphan_user] varchar(200), [drop_orphan_user] varchar(200))
	CREATE TABLE #tblTempOrphan3 ([link_to_existing_login] varchar(200))
	CREATE TABLE #tblTempOrphan5 ([DB User] varchar(100), [Schema] varchar (100), [AlterAuthorization] varchar (200))
	EXEC @exec @sql, N'@DatabaseName sysname', @DatabaseName;
	DELETE FROM #tblTempOrphan
	WHERE [User] = 'dbo'
	SELECT *
	FROM #tblTempOrphan
	ORDER BY DatabaseName
	DROP TABLE #tblTempOrphan

	DECLARE @Rows1 INT = NULL
	SET @Rows1 = (SELECT COUNT(*) FROM #tblTempOrphan3)

	IF(@Rows1 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphan3
		DROP TABLE #tblTempOrphan3
	END
	IF OBJECT_ID('tempdb..#tblTempOrphan3') IS NOT NULL DROP TABLE #tblTempOrphan3


	DECLARE @Rows3 INT = NULL
	SET @Rows3 = (SELECT COUNT(*) FROM #tblTempOrphan5)

	IF(@Rows3 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphan5
		DROP TABLE #tblTempOrphan5
	END
	IF OBJECT_ID('tempdb..#tblTempOrphan5') IS NOT NULL DROP TABLE #tblTempOrphan5
	
END	
ELSE 
BEGIN
	SELECT @command = 
	'USE [?]
	BEGIN
		INSERT INTO #tblTempOrphan2
		SELECT DISTINCT @@SERVERNAME, ''?'' as DatabaseName, dp.name AS [User], dp.sid, dp.type_desc, dp.authentication_type_desc, ''['' + dp.name + ''] is an orphan user in the ['' + ''?'' +  ''] database.'' + '' This means that they do not have a corresponding server login. The orphan user should be repaired or dropped.'' AS [Report], ''CREATE LOGIN ['' + dp.name + ''] WITH PASSWORD = '''' '''' / FROM WINDOWS '' + '' USE ['' + ''?'' + ''] ALTER USER ['' + dp.name + ''] WITH Login = ['' + dp.name + '']''as [repair_orphan_user], ''USE ['' + ''?'' + ''] DROP USER ['' + dp.name + '']'' as [drop_orphan_user]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphan4
		SELECT ''USE '' + ''['' + ''?'' + ''] '' + ''EXEC sp_change_users_login ''' + '''UPDATE_ONE''' + ''','''''' + dp.name + '''''','''''' + sp.name + '''''''' AS [link_to_existing_login]
		FROM sys.database_principals AS dp
		LEFT JOIN sys.server_principals AS sp
		on dp.sid <> sp.sid
		and dp.name COLLATE DATABASE_DEFAULT = sp.name COLLATE DATABASE_DEFAULT
		where dp.is_fixed_role = 0 and sp.is_fixed_role = 0
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')

		INSERT INTO #tblTempOrphan6
		SELECT dp.name AS [DB User], s.name AS [Schema], ''USE ['' + ''?'' + ''] ALTER AUTHORIZATION ON SCHEMA::['' + s.name + ''] TO [dbo]'' AS AlterAuthorization
		FROM sys.database_principals AS dp
		JOIN sys.schemas s ON s.principal_id = dp.principal_id
		LEFT JOIN sys.server_principals AS sp
		on dp.sid = sp.sid
		WHERE
		sp.sid IS NULL
		and dp.authentication_type_desc in (''INSTANCE'', ''WINDOWS'')
		and dp.type_desc in (''SQL_USER'', ''WINDOWS_GROUP'', ''WINDOWS_USER'')
		and s.name <> ''dbo''
	END'



	IF OBJECT_ID('tempdb..#tblTempOrphan2') IS NOT NULL DROP TABLE #tblTempOrphan
	IF OBJECT_ID('tempdb..#tblTempOrphan4') IS NOT NULL DROP TABLE #tblTempOrphan4
	IF OBJECT_ID('tempdb..#tblTempOrphan6') IS NOT NULL DROP TABLE #tblTempOrphan6
	CREATE TABLE #tblTempOrphan2 ([ComputerName] varchar (100),  [DatabaseName] varchar(100), [User] varchar(100), [sid] varbinary(100), [type_desc] varchar(100), [authentication_type_desc] varchar(100), [Report] varchar (300), [repair_orphan_user] varchar(200), [drop_orphan_user] varchar(200))
	CREATE TABLE #tblTempOrphan4 ([link_to_existing_login] varchar(200))
	CREATE TABLE #tblTempOrphan6 ([DB User] varchar(100), [Schema] varchar (100), [AlterAuthorization] varchar (200))
	--EXEC sp_MSforeachdb @command
	EXEC sp_MSforeachdb @command
	DELETE FROM #tblTempOrphan2
	WHERE [User] = 'dbo'
	SELECT *
	FROM #tblTempOrphan2
	ORDER BY DatabaseName
	DROP TABLE #tblTempOrphan2

	DECLARE @Rows2 INT = NULL
	SET @Rows2 = (SELECT COUNT(*) FROM #tblTempOrphan4)

	IF(@Rows2 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphan4
		DROP TABLE #tblTempOrphan4
	END
	IF OBJECT_ID('tempdb..#tblTempOrphan4') IS NOT NULL DROP TABLE #tblTempOrphan4

	DECLARE @Rows4 INT = NULL
	SET @Rows4 = (SELECT COUNT(*) FROM #tblTempOrphan6)

	IF(@Rows4 > 0)
	BEGIN
		SELECT *
		FROM #tblTempOrphan6
		DROP TABLE #tblTempOrphan6
	END
	IF OBJECT_ID('tempdb..#tblTempOrphan6') IS NOT NULL DROP TABLE #tblTempOrphan6
END


	

END
