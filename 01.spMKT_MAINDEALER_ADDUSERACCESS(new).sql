USE WISE_STAGING
GO
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Untuk Add user login
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE spMKT_MAINDEALER_ADDUSERACCESS (
	--@username VARCHAR(100)
	--,@password VARCHAR(2000)
	--,@isStaff INT
	--,@isSuperUser INT
	 @passwdEcrypt nvarchar(max)
	 ,@responseCode Varchar(10) OUTPUT
	,@responseMessage Varchar(500) OUTPUT
	)
AS
BEGIN
DECLARE 
	@username VARCHAR(100)
	,@password VARCHAR(2000)
	,@isStaff INT
	,@isSuperUser INT
	
	BEGIN	 
		 SELECT
			 @username          = ADD_USERNAME
			,@password          = @passwdEcrypt  
			,@isStaff			= IS_STAFF
			,@isSuperUser		= IS_SUPERUSER
		FROM ##listRowMainDAdmin
	END
	
	IF (
			SELECT count(1)
			FROM users_user
			WHERE username = @username
			) > 0
	BEGIN
		select @responseCode= RESPONSE_CODE ,
			@responseMessage = replace(RESPONSE_MESSAGE, '[username]',@username  )
		from M_MKT_MAINDEALER_RESPONSECODE where RESPONSE_CODE='28' 
	END
	ELSE
	BEGIN
		INSERT INTO users_user (
			username
			,password
			,is_staff
			,is_superuser
			,date_joined
			)
		VALUES (
			@username
			,@password
			,@isStaff
			,@isSuperUser
			,getdate()
			)

		 select @responseCode=RESPONSE_CODE,  @responseMessage=RESPONSE_MESSAGE from M_MKT_MAINDEALER_RESPONSECODE where RESPONSE_CODE='00'
	END
END
