USE WISE_STAGING
GO
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Update status jika tidak lolos validasi saat send data ke mss
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 

CREATE PROCEDURE spMKT_MAINDEALER_UPDATE_STATUS_FAILED(@piIdName varchar(100), @piOrderId varchar(100) )
AS
BEGIN


	declare @IdStatus varchar(100)='10'
	,@i2_SEQUENCE  INT , @ORDER_ID varchar(100), @TRANSACTION_ID varchar(100), @PARTNER_ID varchar(100)
	
	/*Update Failed*/
	BEGIN
		Update a
		set id_status=@IdStatus
		from T_MKT_MARKETPLACE_ACQ a 
		where a.transaction_id=@piOrderId
	END


	/*Update Failed*/
	BEGIN
  
		select @ORDER_ID=order_id 
			 , @PARTNER_ID=PARTNER_ID 
		from T_MKT_MARKETPLACE_ACQ WITH (NOLOCK)
		where TRANSACTION_ID=@piOrderId

		SELECT @i2_SEQUENCE =  MAX(SEQUENCE)+1
		FROM T_MKT_MARKETPLACE_STATUS
		WHERE TRANSACTION_ID=@piOrderId 
	    
		INSERT INTO WISE_STAGING.DBO.T_MKT_MARKETPLACE_STATUS 
		(ORDER_ID, TRANSACTION_ID, PARTNER_ID, SEQUENCE, ID_STATUS, STATUS_DT, DTM_CRT, USR_CRT, DTM_UPD, USR_UPD)
		VALUES
		(@ORDER_ID, @piOrderId, @PARTNER_ID, @i2_SEQUENCE, @IdStatus, GETDATE(), GETDATE(), @piIdName, NULL, NULL)
	END

END
