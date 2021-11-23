USE WISE_STAGING
GO
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Untuk Mendapatkan detaul response dari table master
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE spMKT_MAINDEALER_GETRESPONSEMSG(@responseCode varchar(100))
AS 
BEGIN
SELECT RESPONSE_CODE responseCode,RESPONSE_MESSAGE responseMessage FROM M_MKT_MAINDEALER_RESPONSECODE WHERE RESPONSE_CODE=@responseCode
END

/*
	exec spMKT_MAINDEALER_GETRESPONSEMSG '71'
*/