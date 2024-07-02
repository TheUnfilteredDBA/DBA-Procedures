USE master
GO

CREATE OR ALTER PROCEDURE sp_BackupTDECert @CertificateName NVARCHAR(200) = NULL, @BackupFolderPath NVARCHAR(300) = NULL, @EncryptionPassword NVARCHAR(200) = NULL, @Report INT = 0
AS

BEGIN
	SET NOCOUNT ON
	--Put certificate name in correct format
	IF(@CertificateName IS NOT NULL AND LEFT(@CertificateName, 1) <> '[' and RIGHT (@CertificateName, 1) <> ']')
	BEGIN
		SET @CertificateName = '[' + @CertificateName + ']'
	END

	IF (@CertificateName IS NOT NULL AND @BackupFolderPath IS NOT NULL AND @EncryptionPassword IS NOT NULL)
	BEGIN

		
		PRINT 'Beginning backup process of ' + @CertificateName + '...'
		
		
		DECLARE @cmdBackup NVARCHAR(500)
		SET @cmdBackup = N'USE [master] BACKUP CERTIFICATE ' + @CertificateName + ' TO FILE = ' + '''' + @BackupFolderPath + '\' + @CertificateName + REPLACE(REPLACE(CAST(GETDATE() AS NVARCHAR(50)), ' ', ''), ':', '') + '.cer''' + ' WITH PRIVATE KEY (FILE = ' + '''' + @BackupFolderPath + '\' + @CertificateName + REPLACE(REPLACE(CAST(GETDATE() AS NVARCHAR(50)), ' ', ''), ':', '') + '.pvk'', ENCRYPTION BY PASSWORD = ' + '''' + @EncryptionPassword + ''')'
		
		EXEC sp_executesql @cmdBackup

		PRINT 'The TDE certificate ' + @Certificatename + ' along with its private key has been backed up successfully to the folder path ' + @BackupFolderPath + ' using the Encryption Password provided...'
	END

	ELSE IF (@Report <> 1)
	BEGIN
		PRINT 'One or more supplied parameters are missing...'
	END

	IF (@Report = 1)
	BEGIN
		SELECT [name] AS CertificateName, [certificate_id] AS CertificateID, [start_date] AS StartDate, [expiry_date] AS ExpiryDate
		, [pvt_key_last_backup_date] AS PrivateKeyLastBackupDate FROM sys.certificates
		WHERE [name] NOT LIKE '##MS_%'
	END

END
