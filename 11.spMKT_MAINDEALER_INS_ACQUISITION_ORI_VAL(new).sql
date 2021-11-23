USE WISE_STAGING
GO
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Validasi API New Lead
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE spMKT_MAINDEALER_INS_ACQUISITION_ORI_VAL(@guid NVARCHAR(max),@parameterBody NVARCHAR(MAX))  
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
	, @mtType VARCHAR(100)='Api Feedback Main Dealer'

/*Declare Response Code*/
DECLARE @successCode varchar(3),@errorParamCode varchar(3),@errorSystemCode varchar(3)
DECLARE @REFERANTOR_CODE VARCHAR(100) , @REFERANTOR_NAME VARCHAR(100)  
DECLARE @transactionId varchar(100), @orderID varchar(100)

DECLARE	@poRESP_CODE varchar(30),@poRESP_DESC varchar(100),@poRESP_TRANSACTION_ID varchar(30)
DECLARE @SELECT VARCHAR(MAX),@SELECTLISTX VARCHAR(MAX),@SELECTLIST VARCHAR(MAX),@listFinal VARCHAR(MAX),@listFinalX VARCHAR(MAX), @SQLSTR NVARCHAR(MAX)

SELECT @successCode=PARAMETER_VALUE FROM M_MKT_POLO_PARAMETER WHERE PARAMETER_ID ='POLO_RESPCODE_SUCCESS'
SELECT @errorParamCode=PARAMETER_VALUE FROM M_MKT_POLO_PARAMETER WHERE PARAMETER_ID ='POLO_RESPCODE_UPDDATA_ERRPARAM'
SELECT @errorSystemCode=PARAMETER_VALUE FROM M_MKT_POLO_PARAMETER WHERE PARAMETER_ID ='POLO_RESPCODE_UPDDATA_ERRSYS'


IF OBJECT_ID('tempdb..##listRow5A0C6F48MainD') IS NOT NULL DROP TABLE ##listRow5A0C6F48MainD 
IF OBJECT_ID('tempdb..##rowParamMainD') IS NOT NULL DROP TABLE ##rowParamMainD 

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
		SELECT @orderID = stringvalue FROM #PARAM WHERE UPPER([NAME]) ='ORDERIDDEALER'

		BEGIN
			IF(SELECT COUNT(1) from M_MKT_POLO_QUESTIONGROUP_H where QUESTIONGROUP_NAME =@apiName )=0
			BEGIN
				SET @processFlag=1
				SET @messageCodeX = '400'
				SET @messageErr ='idName is not registered'
			END
		END
		  
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
				' SELECT '+@listFinal+' INTO ##listRow5A0C6F48MainD FROM (SELECT STRINGVALUE, [QUESTION_CODE] FROM #PARAM_FINAL) D
				PIVOT (MAX(STRINGVALUE) FOR [QUESTION_CODE] IN  ('+@listFinal+')) x ' 		 		
				EXEC SP_EXECUTESQL @sqlStr 			 
			END  
			
			BEGIN 
				/*mendapatkan nilai dalam bentuk row param*/
				SELECT  QUESTION_CODE ,NAME QUESTION_API,rowNum into #tempList2 FROM #PARAM_FINAL
				SELECT @selectList=''
				SELECT @selectListX=''
				SELECT @selectList=@selectList + QUESTION_CODE+' AS '+QUESTION_API + ', '	
				FROM #tempList2  
				SELECT @selectListX=@selectListX + QUESTION_CODE + ', '	
				FROM #tempList2 		 
				SELECT @listFinal= substring(@selectList,0, convert(int,len(@selectList)-0))
				SELECT @listFinalX= substring(@selectListX,0, convert(int,len(@selectListX)-0))

				set @sqlStr=
				' SELECT '+@listFinal+' INTO ##rowParamMainD FROM (SELECT STRINGVALUE, [QUESTION_CODE] FROM #PARAM_FINAL) D
				PIVOT (MAX(STRINGVALUE) FOR [QUESTION_CODE] IN  ('+@listFinalX+')) x ' 		 		
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
				EXEC spMKT_MAINDEALER_INS_ACQUISITION_ORI
					@piSourceData = 'Main_Dealer',
					@poRESP_CODE = @poRESP_CODE OUTPUT,
					@poRESP_DESC = @poRESP_DESC OUTPUT,
					@poRESP_TRANSACTION_ID = @poRESP_TRANSACTION_ID OUTPUT 
			END

			/*Set Flag, 0=Lanjut, 1=Stop*/
			IF @poRESP_CODE='00'
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
			SELECT @poRESP_CODE responseCode, @poRESP_DESC responseMessage, @orderID orderIdDealer, @poRESP_TRANSACTION_ID orderId, @mtType mtType into #ResponseJsonSCC
	

			SET @responseJson= (SELECT * FROM #ResponseJsonSCC FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)   

			/*insert log response - valid*/ 
			INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, TRANSACTION_ID,RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC,PARAMETER, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT)
			VALUES (@apiName,@orderID,@poRESP_TRANSACTION_ID, @poRESP_CODE, @poRESP_DESC, NULL,@responseJson, GETDATE(), @responseID, GETDATE(), 'System')
			  

			/*set response api - valid*/ 
			SELECT * from #ResponseJsonSCC
			select * from ##rowParamMainD
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
				SELECT @responseCode responseCode, 'Param Error - '+@messageErr+'' responseMessage,substring(@messageErr, 1,100) errorMessage,@orderID orderIdDealer,'' orderId, @mtType mtType  into #ResponseJsonErr1
				SET @responseJson=''
				SET @responseJson= (select *
									from #ResponseJsonErr1
									for json path, without_array_wrapper)
									 

				INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)
				VALUES (@apiName,@orderID, @responseCode, @responseMessage , substring(@messageErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System',@responseJson)

 
				/*set response api - invalid*/  
				SELECT * from #ResponseJsonErr1
				select * from ##rowParamMainD 
			END
			ELSE
			BEGIN
				/*set json*/
				--SELECT @poRESP_CODE responseCode, @poRESP_DESC+' - '+substring(isnull(@messageErr,''), 1,100) responseMessage,substring(@messageErr, 1,100) errorMessage,@orderID orderIdDealer,'' orderId, @mtType mtType into #ResponseJsonErr2
				SELECT @poRESP_CODE responseCode, @poRESP_DESC responseMessage,substring(@messageErr, 1,100) errorMessage,@orderID orderIdDealer,'' orderId, @mtType mtType into #ResponseJsonErr2
				SET @responseJson=''
				SET @responseJson= (select* 
									from #ResponseJsonErr2
									for json path, without_array_wrapper)

				/*insert log response - invalid*/ 
				INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)
				VALUES (@apiName,@orderID, @poRESP_CODE, @poRESP_DESC, substring(@messageErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System',@responseJson)

 
				/*set response api - invalid*/  
				SELECT * from #ResponseJsonErr2 
				select * from ##rowParamMainD 
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
		--SELECT @responseCode responseCode, @responseMessage+' - '+substring(@messageSystemErr, 1,100) responseMessage,substring(@messageSystemErr, 1,100) errorMessage,@orderID orderIdDealer,'' orderId, @mtType mtType into #ResponseJsonErrOTH
		SELECT @responseCode responseCode, @responseMessage responseMessage,substring(@messageSystemErr, 1,100) errorMessage,@orderID orderIdDealer,'' orderId, @mtType mtType into #ResponseJsonErrOTH
		SET @responseJson=''
		SET @responseJson= (select *
							from #ResponseJsonErrOTH
							for json path, without_array_wrapper) 

		/*insert log response - Error*/
		INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT, PARAMETER)
		VALUES (@apiName,@orderID, @responseCode, @responseMessage, substring(@messageSystemErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System', @responseJson)

		/*set response api - error*/  
		SELECT * from #ResponseJsonErrOTH
		select * from ##rowParamMainD  
 
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
	--SELECT @responseCode responseCode, @responseMessage+' - '+substring(isnull(@messageErr,''), 1,100) responseMessage,@messageErr errorMessage,@orderID orderIdDealer,'' orderId, @mtType mtType
	SELECT @responseCode responseCode, @responseMessage  responseMessage,@messageErr errorMessage,@orderID orderIdDealer,'' orderId, @mtType mtType
	select * from ##rowParamMainD 


END

