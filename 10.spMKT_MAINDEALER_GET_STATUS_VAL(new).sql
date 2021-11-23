USE WISE_STAGING
GO
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Validasi untuk API Get Status
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE spMKT_MAINDEALER_GET_STATUS_VAL(@guid NVARCHAR(max),@parameterBody NVARCHAR(MAX))  
AS  

CREATE TABLE #RESPONSE_VAL (responseMessage VARCHAR(max), responseCode VARCHAR(3))
CREATE TABLE #RESPONSE_EXEC ( isSuccess VARCHAR(100),errorMsg VARCHAR(MAX), transactionId varchar(100))
CREATE TABLE #TEMP_REFERANTORX(REFERANTOR_CODE1 VARCHAR(100), REFERANTOR_NAME1 VARCHAR(100), REFERANTOR_CODE2 VARCHAR(100), REFERANTOR_NAME2 VARCHAR(100))

DECLARE @apiName VARCHAR(200)
	, @messageCodeX NVARCHAR(MAX)
	, @messageX NVARCHAR(MAX)
	, @messageErr NVARCHAR(MAX)
	, @responseID VARCHAR(500) 
	, @responseCode NVARCHAR(MAX)
	, @responseMessage NVARCHAR(MAX)
	, @execSP VARCHAR(100)
	, @processFlag INT =0/*1=ERROR, 0=NEXTSTEP*/
	, @sqlCmd NVARCHAR(MAX)
	, @sqlCmd2 NVARCHAR(MAX)
	, @taskId varchar(100)
	, @responseJson NVARCHAR(max)  

/*Declare Response Code*/
DECLARE @successCode varchar(3),@errorParamCode varchar(3),@errorSystemCode varchar(3)
DECLARE @REFERANTOR_CODE VARCHAR(100) , @REFERANTOR_NAME VARCHAR(100)  
DECLARE @transactionId varchar(100), @orderID varchar(100)

DECLARE @SELECT VARCHAR(MAX),@SELECTLISTX VARCHAR(MAX),@SELECTLIST VARCHAR(MAX),@listFinal VARCHAR(MAX),@listFinalX VARCHAR(MAX), @SQLSTR NVARCHAR(MAX)
DECLARE	@poStatusOut varchar(100),
		@poIdPartnerOut varchar(20),
		@poStatusCode varchar(100),
		@poMessage varchar(100),
		@poNoPOOut varchar(50),
		@poTglPOOut varchar(20),
		@poDPOut varchar(100),
		@poTenorOut varchar(100),
		@poOrderId varchar(100),
		@poDealerName varchar(200),
		@pofullName varchar(200),
		@poAgrmntNo varchar(50),
		@poInstalmentAmt varchar(100),
		@poTransactionId varchar(100),
		@partnerID varchar(100) 
		 
IF OBJECT_ID('tempdb..##listRowMainDStatChk') IS NOT NULL DROP TABLE ##listRowMainDStatChk  
IF OBJECT_ID('tempdb..##rowParamMainDStatChk') IS NOT NULL DROP TABLE ##rowParamMainDStatChk 

/*Param tidak boleh null*/
IF @parameterBody IS NULL
BEGIN
	SET @processFlag = 1
END

IF @processFlag = 0
BEGIN
	BEGIN TRY
		/*CREATE LOg REQUEST*/
		SELECT *
		INTO #PARAM
		FROM fnMKT_POLO_parseJSON(@parameterBody)
		
		SELECT @apiName = stringvalue  FROM #PARAM WHERE UPPER([NAME]) ='IDNAME'
		SELECT @taskId = stringvalue FROM #PARAM WHERE UPPER([NAME]) ='TASKID'
		SELECT @orderID = stringvalue FROM #PARAM WHERE UPPER([NAME]) ='orderIdDealer'
		SELECT @partnerID = stringvalue FROM #PARAM WHERE UPPER([NAME]) ='delaerID'
		  
		BEGIN
			SELECT	E.QUESTION_CODE
				,	B.QUESTION_API AS [NAME]
				,	stringvalue
				,	ROW_NUMBER() OVER (
					ORDER BY element_id
					) AS rowNum 
			INTO #PARAM_FINAL
			FROM #PARAM A
			JOIN M_MKT_POLO_QUESTIONGROUP_D B
			ON A.NAME=B.QUESTION_API
			JOIN M_MKT_POLO_QUESTIONGROUP_H C
			ON B.M_MKT_POLO_QUESTIONGROUP_H_ID=C.M_MKT_POLO_QUESTIONGROUP_H_ID AND C.QUESTIONGROUP_NAME=@apiName
			JOIN M_MKT_POLO_QUESTION_LIST D ON B.QUESTION_IDENTIFIER=D.QUESTION_IDENTIFIER
			JOIN M_MKT_POLO_QUESTION_LABEL E ON D.M_MKT_POLO_QUESTION_LABEL_ID=E.M_MKT_POLO_QUESTION_LABEL_ID
			WHERE ValueType != 'object'			 	  

			--SELECT @responseID = newid() 
			SELECT @responseID = @guid 


			BEGIN 
				/*mendapatkan nilai dalam bentuk row*/
				SELECT  QUESTION_CODE ,rowNum into #tempList FROM #PARAM_FINAL
				SELECT @selectList=''
				SELECT @selectList=@selectList + QUESTION_CODE + ', '	
				FROM #tempList  		 
				SELECT @listFinal= substring(@selectList,0, convert(int,len(@selectList)-0))
				
				set @sqlStr=
				' SELECT '+@listFinal+' INTO ##listRowMainDStatChk FROM (SELECT STRINGVALUE, [QUESTION_CODE] FROM #PARAM_FINAL) D
				PIVOT (MAX(STRINGVALUE) FOR [QUESTION_CODE] IN  ('+@listFinal+')) x ' 	
		 
				EXEC SP_EXECUTESQL @sqlStr 			 
			END  
	  
		 
			/*validasi parameter*/
			INSERT INTO #RESPONSE_VAL
			EXEC [dbo].[spMKT_POLO_VALIDATIONLABEL] @parameterBody, NULL, NULL
		 
			SELECT @messageCodeX = responseCode, @messageX = responseMessage
			FROM #RESPONSE_VAL 

			IF @messageCodeX != '200'
			BEGIN
				/*Jika parameter tidak sesuai, proses akan di stop*/
				SET @processFlag = 1
				SET @messageErr=@messageX
			END
		END
		

		/*jika prameter sudah sesuai=200*/		
		IF @processFlag = 0
		BEGIN  

			/*Execute SP Utama*/  
			BEGIN
				EXEC spMKT_MAINDEALER_GET_STATUS
				@poStatusOut = @poStatusOut OUTPUT,
				@poIdPartnerOut = @poIdPartnerOut OUTPUT,
				@poStatusCode = @poStatusCode OUTPUT,
				@poMessage = @poMessage OUTPUT,
				@poNoPOOut = @poNoPOOut OUTPUT,
				@poTglPOOut = @poTglPOOut OUTPUT,
				@poDPOut = @poDPOut OUTPUT,
				@poTenorOut = @poTenorOut OUTPUT,
				@poOrderId = @poOrderId OUTPUT,
				@poDealerName = @poDealerName OUTPUT,
				@pofullName = @pofullName OUTPUT,
				@poAgrmntNo = @poAgrmntNo OUTPUT,
				@poInstalmentAmt = @poInstalmentAmt OUTPUT,
				@poTransactionId = @poTransactionId OUTPUT 
				
				SELECT	ISNULL(@poStatusOut,'') as 'statusOrder',
						ISNULL(@poIdPartnerOut,'') as 'dealerId',
						ISNULL(@orderID ,'')as 'orderIdDealer', 
						ISNULL(@poStatusCode,'') as 'responseCode', 
						ISNULL(@poMessage,'') as 'responseMessage',
						ISNULL(@poNoPOOut,'') as 'poNo',
						ISNULL(@poTglPOOut,'') as 'poDate',
						ISNULL(@poDPOut,'') as 'poDp',
						ISNULL(@poTenorOut,'') as 'poTenor', 
						ISNULL(@poDealerName,'') as 'dealerName',
						ISNULL(@pofullName,'') as 'fullName',
						ISNULL(@poAgrmntNo,'') as 'agrmntNo',
						ISNULL(@poInstalmentAmt,'') as 'instalmentAmt',
						ISNULL(@poTransactionId,'') as 'orderId'
				INTO ##rowParamMainDStatChk 
			END

			/*Set Flag, 0=Lanjut, 1=Stop*/
			IF @poStatusCode='00'
			BEGIN  
				SET @processFlag = 0 
			END
			ELSE
			BEGIN 

				SET @processFlag = 1  
			END
		END 
	 
		IF  @processFlag = 0
		BEGIN
			/*set json*/ 
			SET @responseJson= (select responseCode, responseMessage , orderIdDealer, orderId, dealerId, dealerName, fullName, statusOrder, agrmntNo, poNo, poDate, poDp, poTenor, instalmentAmt
								from ##rowParamMainDStatChk
								for json path, without_array_wrapper)   

			/*insert log response - valid*/ 
			INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, TRANSACTION_ID,RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC,PARAMETER, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT)
			VALUES (@apiName,@orderID,NULL, @poStatusCode, @poMessage, NULL,@responseJson, GETDATE(), @responseID, GETDATE(), 'System')
			   
			/*set response api - valid*/ 
			select responseCode, responseMessage , orderIdDealer, orderId, dealerId, dealerName, fullName, statusOrder, agrmntNo, poNo, poDate, poDp, poTenor, instalmentAmt from ##rowParamMainDStatChk
		END
		ELSE
		BEGIN
			IF @messageCodeX = '400'
			BEGIN
				/*insert log response - invalid ParamError*/ 
				SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
				  FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
				 WHERE RESPONSE_CODE = '02'

				/*set json*/
				SELECT @responseCode responseCode, 'Param Error - '+substring(isnull(@messageErr,''), 1,100) responseMessage,substring(@messageErr, 1,100) errorMessage, @orderID orderIdDealer, ''orderId,@partnerID dealerId, ''dealerName, ''fullName, ''statusOrder, ''agrmntNo, ''poNo, ''poDate, ''dP, ''tenor, ''instalmentAmt into #ResponseJsonErr1
				SET @responseJson=''
				SET @responseJson= (select * from #ResponseJsonErr1
									for json path, without_array_wrapper)	
									 

				INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)
				VALUES (@apiName,@orderID, @responseCode, @responseMessage , substring(@messageErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System',@responseJson)

 
				/*set response api - invalid*/  
				SELECT * from #ResponseJsonErr1
				--select @partnerID partnerID, @orderID orderID, ''phoneNo, ''statusCode, ''statusDesc, ''statusDate, ''poNo,'' poDate, ''dp, ''tenor 
			END
			ELSE
			BEGIN
				/*set json*/
				SELECT @poStatusCode responseCode, @poMessage responseMessage,substring(@messageErr, 1,100) errorMessage, @orderID orderIdDealer, ''orderId,@partnerID dealerId, ''dealerName, ''fullName, ''statusOrder, ''agrmntNo, ''poNo, ''poDate, ''poDp, ''poTenor, ''instalmentAmt into #ResponseJsonErr2
				SET @responseJson=''
				SET @responseJson= (select * from #ResponseJsonErr2
									for json path, without_array_wrapper)

				/*insert log response - invalid*/ 
				INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)
				VALUES (@apiName,@orderID, @poStatusCode, @poMessage, substring(@messageErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System',@responseJson)

 
				/*set response api - invalid*/  
				SELECT * from #ResponseJsonErr2 
				--select @partnerID partnerID, @orderID orderID, ''phoneNo, ''statusCode, ''statusDesc, ''statusDate, ''poNo,'' poDate, ''dp, ''tenor   
			END
			
		END 
 
	END TRY

	BEGIN CATCH
		DECLARE @ERRMSG VARCHAR(MAX), @ERRSEVERITY INT, @ERRSTATE INT, @ERR_LINE VARCHAR(MAX), @messageSystemErr varchar(max)
		SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
		  FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
		 WHERE RESPONSE_CODE = '30'

		SELECT @ERRMSG = ERROR_MESSAGE(), @ERRSEVERITY = ERROR_SEVERITY(), @ERRSTATE = ERROR_STATE(),@ERR_LINE=ERROR_LINE()		
		   SET @messageSystemErr='Error : '+ISNULL(@messageX,'') +ISNULL(@ERRMSG,'')+' at Line : '+ISNULL(CAST(@ERR_LINE AS VARCHAR),'')

		/*set json*/
		SELECT @responseCode responseCode, @responseMessage  responseMessage,substring(@messageSystemErr, 1,100) errorMessage, @orderID orderIdDealer, ''orderId,@partnerID dealerId, ''dealerName, ''fullName, ''statusOrder, ''agrmntNo, ''poNo, ''poDate, ''poDp, ''poTenor, ''instalmentAmt into #ResponseJsonErrOTH
		SET @responseJson=''
		SET @responseJson= (select * from #ResponseJsonErrOTH
							for json path, without_array_wrapper) 

		/*insert log response - Error*/
		INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT, PARAMETER)
		VALUES (@apiName,@orderID, @responseCode, @responseMessage, substring(@messageSystemErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System', @responseJson)

		/*set response api - error*/  
		SELECT * from #ResponseJsonErrOTH
		--select @partnerID partnerID, @orderID orderID, ''phoneNo, ''statusCode, ''statusDesc, ''statusDate, ''poNo,'' poDate, ''dp, ''tenor   
 
	END CATCH
END
ELSE 
BEGIN
	/*insert log response - invalid*/
	 SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
				  FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
				 WHERE RESPONSE_CODE = '30'

	SET @messageErr='Parameter cannot be empty'
 
	/*set response api - invalid*/ 
	SELECT @responseCode responseCode, @responseMessage  responseMessage,@messageErr errorMessage, @orderID orderIdDealer, @orderID orderIdDealer, ''orderId,@partnerID dealerId, ''dealerName, ''fullName, ''statusOrder, ''agrmntNo, ''poNo, ''poDate, ''poDp, ''poTenor, ''instalmentAmt 
	--select @partnerID partnerID, @orderID orderID, ''phoneNo, ''statusCode, ''statusDesc, ''statusDate, ''poNo,'' poDate, ''dp, ''tenor  

END

