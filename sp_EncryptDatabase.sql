USE [master]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE  or alter  PROCEDURE [dbo].[sp_EncryptDatabase] @DatabaseName SYSNAME = NULL, @ServerCert NVARCHAR(100) = NULL, @MasterKeyPassword NVARCHAR(60) = NULL, @SetupOnly INT = 0, @Progress NVARCHAR(50) = NULL, @Report INT = 0, @Help INT = 0
AS

BEGIN
	SET NOCOUNT ON
	IF (@DatabaseName IS NOT NULL AND LEFT(@DatabaseName, 1) = '[' and RIGHT (@DatabaseName, 1) = ']')
	BEGIN
	PRINT 'Adjusting database name to fit expected format...'
	SET @DatabaseName = (SELECT REPLACE(@DatabaseName, '[', ''))
	SET @DatabaseName = (SELECT REPLACE(@DatabaseName, ']', ''))
	END

	IF(@ServerCert IS NOT NULL AND LEFT(@ServerCert, 1) <> '[' and RIGHT (@ServerCert, 1) <> ']')
	BEGIN
		SET @ServerCert = '[' + @ServerCert + ']'
	END

	IF(@SetupOnly = 1 AND @MasterKeyPassword IS NOT NULL AND @ServerCert IS NULL)
	BEGIN
		PRINT 'Creating the master key...'
		

		DECLARE @cmdSetupOnly NVARCHAR(100) = N'USE [master] CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''' + @MasterKeyPassword + ''''
		EXEC sp_executesql @cmdSetupOnly

		PRINT 'Master key created...'

		PRINT 'Creating server certificate...'
		DECLARE @ServerNameSetupOnly sysname
		SET @ServerNameSetupOnly = @@SERVERNAME 
		IF @ServerNameSetupOnly like '%\%'
		BEGIN
			SET @ServerNameSetupOnly = REPLACE(@@SERVERNAME,'\','_')
		END
		SET @ServerCert = '[' + @ServerNameSetupOnly + '_TDE_CERT]'
		DECLARE @sqlSetupOnly NVARCHAR(200) = N'USE [master] CREATE CERTIFICATE ' + @ServerCert + ' WITH SUBJECT = ''Database_Encryption'''

		EXEC sp_executesql @sqlSetupOnly

		PRINT 'Server certificate created...'
		
	END


	ELSE IF(@SetupOnly = 1 AND @MasterKeyPassword IS NOT NULL AND @ServerCert IS NOT NULL)
	BEGIN
		PRINT 'Creating the master key...'
		

		DECLARE @cmdSetupOnly2 NVARCHAR(100) = N'USE [master] CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''' + @MasterKeyPassword + ''''
		EXEC sp_executesql @cmdSetupOnly2

		PRINT 'Master key created...'

		PRINT 'Creating server certificate...'
		
		
		IF @ServerCert like '%\%'
		BEGIN
			SET @ServerCert = REPLACE(@ServerCert,'\','_')
			PRINT 'Changed the supplied ''\'' to ''_'' to prevent issues backing up the cert to a file path...'
		END
		
		DECLARE @sqlSetupOnly2 NVARCHAR(200) = N'USE [master] CREATE CERTIFICATE ' + @ServerCert + ' WITH SUBJECT = ''Database_Encryption'''

		EXEC sp_executesql @sqlSetupOnly2

		PRINT 'Server certificate created...'
		
	END


	ELSE IF(@SetupOnly = 1 AND @MasterKeyPassword IS NULL AND @ServerCert IS NOT NULL)
	BEGIN
		
		PRINT 'Creating server certificate...'

		IF @ServerCert like '%\%'
		BEGIN
			SET @ServerCert = REPLACE(@ServerCert,'\','_')
			PRINT 'Changed the supplied ''\'' to ''_'' to prevent issues backing up the cert to a file path...'
		END
		
		DECLARE @sqlSetupOnly3 NVARCHAR(200) = N'USE [master] CREATE CERTIFICATE ' + @ServerCert + ' WITH SUBJECT = ''Database_Encryption'''

		EXEC sp_executesql @sqlSetupOnly3

		PRINT 'Server certificate created...'
		
	END

	ELSE IF(@SetupOnly = 1 AND @MasterKeyPassword IS NULL AND @ServerCert IS NULL AND EXISTS (SELECT TOP 1 * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##'))
	 
	BEGIN
		PRINT 'Master key already exists...'
		PRINT 'Creating server certificate...'
		DECLARE @ServerNameSetupOnly4 sysname
		
		SET @ServerNameSetupOnly4 = @@SERVERNAME 
		IF @ServerNameSetupOnly4 like '%\%'
		BEGIN
			SET @ServerNameSetupOnly4 = REPLACE(@@SERVERNAME,'\','_')
		END
		SET @ServerCert = @ServerNameSetupOnly4 + '_TDE_CERT'
		
		
		IF EXISTS(SELECT name from sys.certificates WHERE name = @ServerCert)
		BEGIN	
		SET @ServerCert = '['+@ServerCert + '_' + REPLACE(REPLACE(CAST(GETDATE() as nvarchar),' ','_'),':','')+']'
		END	
	
		IF (LEFT(@ServerCert, 1) <> '[' and RIGHT (@ServerCert, 1) <> ']')
		BEGIN
		SET @ServerCert = '['+@ServerCert+']'
		END
		DECLARE @sqlSetupOnly4 NVARCHAR(200) = N'USE [master] CREATE CERTIFICATE ' + @ServerCert + ' WITH SUBJECT = ''Database_Encryption'''

		EXEC sp_executesql @sqlSetupOnly4

		PRINT 'Server certificate created...'
	END

	IF OBJECT_ID('tempdb..#tblTempCertCheck') IS NOT NULL DROP TABLE #tblTempCertCheck

	SELECT * INTO #tblTempCertCheck
	FROM sys.certificates
	WHERE sys.certificates.name NOT LIKE '##MS_%'
	DECLARE @Rows1 INT = NULL
	SET @Rows1 = (SELECT COUNT(*) FROM #tblTempCertCheck)
	--select * from #tblTempCertCheck
	IF (NOT EXISTS(SELECT TOP 1 * FROM #tblTempCertCheck) AND @DatabaseName IS NOT NULL AND @MasterKeyPassword IS NULL)

	BEGIN
		PRINT 'It looks like you are setting up TDE from net new. You must first supply a password for the @MasterKeyPassword parameter...'
		PRINT 'Also, if you would just like to set up the Master Key and Server Certificate, use the @SetupOnly = 1 parameter along with the @MasterKeyPassword parameter.'
		PRINT 'Pass in the @ServerCert parameter if you would like to specify a server cert name or leave it blank to have one generated for you.'
	END

	ELSE IF (NOT EXISTS(SELECT TOP 1 * FROM #tblTempCertCheck) AND @DatabaseName IS NOT NULL AND @MasterKeyPassword IS NOT NULL)
		BEGIN
		PRINT 'The table is empty, running certificate creation process...'
		
		PRINT 'Creating the master key...'
		

		DECLARE @cmd NVARCHAR(100) = N'USE [master] CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''' + @MasterKeyPassword + ''''
		EXEC sp_executesql @cmd

		PRINT 'Master key created...'

		PRINT 'Creating server certificate...'
		DECLARE @ServerName sysname
		SET @ServerName = @@SERVERNAME 
		IF @ServerName LIKE '%\%'
		BEGIN
			SET @ServerName = REPLACE(@ServerName, '\', '_')
			PRINT 'Changed the supplied ''\'' to ''_'' to prevent issues backing up the cert to a file path...'
		END
		SET @ServerCert = '[' + @ServerName + '_TDE_CERT]'
		DECLARE @sql NVARCHAR(200) = N'USE [master] CREATE CERTIFICATE ' + @ServerCert + ' WITH SUBJECT = ''Database_Encryption'''

		EXEC sp_executesql @sql

		PRINT 'Server certificate created...'
		END

	ELSE IF (EXISTS(SELECT TOP 1 * FROM #tblTempCertCheck) AND @DatabaseName IS NOT NULL AND @MasterKeyPassword IS NOT NULL)
	BEGIN
		PRINT 'It looks like a master key and a certificate have already been set up here. You should be able to just pass the database name and exclude the password.'
	END

	
	ELSE IF (@Rows1 = 1 AND @DatabaseName IS NOT NULL AND @MasterKeyPassword IS NULL)
		BEGIN
		PRINT 'The table is not empty, using existing certificate...'
		SET @ServerCert = (SELECT + '[' + [name] + ']' from sys.certificates WHERE sys.certificates.name NOT LIKE '##MS_%')
		END

	ELSE IF (@Rows1 > 1 AND @DatabaseName IS NOT NULL AND @MasterKeyPassword IS NULL AND @ServerCert IS NULL)
	BEGIN
		PRINT 'It looks like more than one TDE cert exists, you need to specify which one you want to use. You can get the existing certificates' + CHAR(13)+CHAR(10) + 'by running sp_EncryptDatabase @Report = 1. Then, pass in the database name into the @DatabaseName parameter along with the desired certificate name into the @ServerCert parameter...'
	END

	IF (@DatabaseName IS NOT NULL AND @ServerCert IS NOT NULL)
	BEGIN
	PRINT 'Now encrypting [' + @DatabaseName + ']...'
	DECLARE @sql2 NVARCHAR(200) = N'USE [' + @DatabaseName + '] CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE ' + @ServerCert + ''

	EXEC sp_executesql @sql2

	

	PRINT 'Now setting encryption to ON for database [' + @DatabaseName + ']...'

	DECLARE @sql3 NVARCHAR(200) = N'ALTER DATABASE [' + @DatabaseName + ']' + ' SET ENCRYPTION ON'
	EXEC sp_executesql @sql3
	END

	ELSE IF (@DatabaseName IS NULL AND @Report = 0 AND @Progress IS NULL AND @Help = 0)
	BEGIN
	PRINT 'You must supply a database to encrypt or view a report of database encryption status. Run sp_EncryptDatabase @Help = 1 for more information.'
	END

	IF (@Report = 1)
	BEGIN
	-- this provides the list of certificates
	SELECT * FROM sys.certificates
	WHERE [name] NOT LIKE '##MS_%'
	
	-- this provides the list of databases (encryption_state = 3) is encrypted
	--SELECT DB_NAME(database_id) AS EncryptedDatabases, * FROM sys.dm_database_encryption_keys
	--WHERE encryption_state = 3
	--AND DB_Name(database_id) <> 'tempdb'

	-- this provides the list of databases (encryption_state = 3) is encrypted
		select
		EncryptedDatabases = d.name,
		dek.encryptor_type as EncryptoinType,
		EncryptedByCert = c.name
	from master.sys.dm_database_encryption_keys dek
	left join master.sys.certificates c
	on dek.encryptor_thumbprint = c.thumbprint
	inner join master.sys.databases d
	on dek.database_id = d.database_id
	where d.name <> 'tempdb'
	and encryption_state = 3

	--Getting unencrypted databases
	SELECT DB_NAME(database_id) AS UnencryptedDatabases FROM sys.databases WHERE is_encrypted <> 1 AND is_read_only <> 1

	END

	ELSE IF (@Report > 1)
	BEGIN
	PRINT 'A valid input for the @Report parameter was not supplied...'
	END

	IF (@Progress IN (0,1,2,3,4,5,6))
	BEGIN
	SELECT d.name DatabaseName
              ,(CASE ISNULL(de.encryption_state,0)
                     WHEN 0 THEN 'No Encryption'
                     WHEN 1 THEN 'Unencrypted'
                     WHEN 2 THEN 'Encryption in Progress'
                     WHEN 3 THEN 'Encrypted'
                     WHEN 4 THEN 'Key Change in Progress'
                     WHEN 5 THEN 'Decryption in Progress'
                     WHEN 6 THEN 'Encryption Key change in Progress' END) AS EncryptionStatus
              ,de.percent_complete
			FROM
			master.sys.databases d
			LEFT OUTER JOIN master.sys.dm_database_encryption_keys de ON de.database_id = d.database_id
			where de.encryption_state = @Progress
	END

	ELSE IF (@Progress > 6 OR @Progress < 0)
	BEGIN
		PRINT 'That is not a valid input for the @Progress parameter...'
	END

	IF (@Help = 1)

	BEGIN
		PRINT 'Parameter Description:'
		PRINT '@DatabaseName - This takes in a desired database that you would like to encrypt.'
		PRINT '@ServerCert - Pass in a name of the certificate you would like to create. If nothing is supplied, a certificate name will be generated for you.'
		PRINT '@MasterKeyPassword - You must supply this parameter if a Master Key has not been created yet.'
		PRINT '@Progress - See the status of your encryption progress. You can pass in the following numbers to see different statuses:
				0 = No Encryption
				1 = Unencrypted
				2 = Encryption in Progress
				3 = Encrypted
				4 = Key Change In Progress
				5 = Decryption In Progress
				6 = Encryption Key change in Progress'
		PRINT '@Report - Get detailed information about server certificates, encrypted databases, unencrypted databases, and other related information.'
		PRINT '@SetupOnly - This will only set up the Master Key and the Server Certificate. If there is already a Master Key created, you do not need to supply a @MasterKeyPassword parameter.' + CHAR(13)+CHAR(10) + 'You also do not need to supply a @ServerCert parameter if you would like a certificate name generated for you.'
	END

	ELSE IF (@Help <> 0 AND @Help <> 1)
	BEGIN
	PRINT 'That is not a valid input for the @Help parameter. Use @Help = 1 for more details about this procedure.'
	END
END
GO


