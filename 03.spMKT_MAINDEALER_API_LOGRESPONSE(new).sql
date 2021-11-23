USE WISE_STAGING
GO
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Untuk Insert Response log
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE [dbo].[spMKT_MAINDEALER_API_LOGRESPONSE]  
(  
 @idName VARCHAR(100),  
 @orderIdWom VARCHAR(100),   
 @orderId VARCHAR(100), 
 @responseCode VARCHAR(3),  
 @responseMsg VARCHAR(1000),  
 @errorDesc VARCHAR(1000),  
 @responseId VARCHAR(100),  
 @paramBody NVARCHAR(MAX)  
)  
AS  
BEGIN  
 SET NOCOUNT ON;  
  
 INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME, ORDER_ID,TRANSACTION_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)  
 VALUES (@idName, @orderIdWom,@orderId, @responseCode, @responseMsg, @errorDesc, GETDATE(), @responseId, GETDATE(), 'System',@paramBody)  
END