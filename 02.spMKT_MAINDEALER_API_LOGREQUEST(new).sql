USE [WISE_STAGING]
GO 
 
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Untuk insert Log Request API
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE [dbo].[spMKT_MAINDEALER_API_LOGREQUEST]
(
	@guid varchar(max),
	@idName VARCHAR(100),
	@parameter NVARCHAR(MAX),
	@orderIdWom VARCHAR(100)
)
AS
BEGIN
	SET NOCOUNT ON; 

	INSERT INTO T_MKT_MARKETPLACE_APILOGREQUEST (ID_NAME, ORDER_ID, PARAMETER, REQUEST_DT, RESPONSE_ID, DTM_CRT, USR_CRT)
	VALUES(@idName, @orderIdWom, @parameter, GETDATE(), @guid, GETDATE(), 'System')
	  
END