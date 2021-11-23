USE WISE_STAGING
GO
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Untuk mendapatkan data config sftp 
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE spMKT_MAINDEALER_LOAD_CONFIG_SFTP
AS 
BEGIN
	SELECT
	(SELECT  PARAMETER_VALUE FROM CONFINS.dbo.Mst_file_parameter WITH (NOLOCK) WHERE PARAMETER_NAME = 'SFTP_PASSWORD_HOST_MARKETPLACE' ) as sftpPassword
	,(SELECT  PARAMETER_VALUE FROM CONFINS.dbo.Mst_file_parameter WITH (NOLOCK) WHERE PARAMETER_NAME = 'SFTP_USER_HOST_MARKETPLACE' ) as sftpUsername
	,(SELECT  PARAMETER_VALUE FROM CONFINS.dbo.Mst_file_parameter WITH (NOLOCK) WHERE PARAMETER_NAME = 'SFTP_PORT_HOST_MARKETPLACE' ) as sftpPort
	,(SELECT  PARAMETER_VALUE FROM CONFINS.dbo.Mst_file_parameter WITH (NOLOCK) WHERE PARAMETER_NAME = 'SFTP_HOST_MARKETPLACE' ) as sftpHost
	,(SELECT  PARAMETER_VALUE FROM CONFINS.dbo.Mst_file_parameter WITH (NOLOCK) WHERE PARAMETER_NAME = 'PATH_LOG_ERROR_MARKETPLACE' ) as sftpPathLogError
	,(SELECT  PARAMETER_VALUE FROM CONFINS.dbo.Mst_file_parameter WITH (NOLOCK) WHERE PARAMETER_NAME = 'PATH_LOG_TEMP_FILE_MARKETPLACE' ) as sftpPathLogTempError

END
/*
UPDATE A
set PARAMETER_VALUE='media\marketplace'
FROM CONFINS.dbo.Mst_file_parameter a
where PARAMETER_NAME='PATH_LOG_TEMP_FILE_MARKETPLACE'


*/


 /*exec spmkt_marketplace_load_config_sftp*/