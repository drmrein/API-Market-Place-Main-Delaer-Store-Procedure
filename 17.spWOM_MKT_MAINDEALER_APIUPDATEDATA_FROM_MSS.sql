/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.1601)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [WISE_STAGING]
GO
/****** Object:  StoredProcedure [dbo].[spWOM_MKT_MAINDEALER_APIUPDATEDATA_FROM_MSS]    Script Date: 11/22/21 9:03:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 --===============================================================================================================================================================================
--||Author		: arif 																																			 
--||Create date	: 23-11-2021																																					
--||Description	: Main Procedure untuk Memproses Update data maindealer berdasarkan data kiriman dari MSS																																	 
--||Version		: v1.0.20211123																																	 
--||History		:																																								
--||----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--|| Date           | Type    | Version         | Name                        | Description                                          |Detail                                            
--||----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--|| 23-11-2021     | Create  | v1.0.20211022   | Arif    		              | BR/2021/JUL/MKT/001                                  |API Main Dealer                                          
 --===============================================================================================================================================================================
 
CREATE PROCEDURE [dbo].[spWOM_MKT_MAINDEALER_APIUPDATEDATA_FROM_MSS](@guid NVARCHAR(max),@parameterBody NVARCHAR(MAX))  
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
DECLARE @transactionId varchar(100), @orderId varchar(100),@orderIDApi varchar(100)

DECLARE @SELECT VARCHAR(MAX),@SELECTLISTX VARCHAR(MAX),@SELECTLIST VARCHAR(MAX),@listFinal VARCHAR(MAX),@listFinalX VARCHAR(MAX), @SQLSTR NVARCHAR(MAX)
DECLARE @poStatusOut varchar(100),
		@poIdPartnerOut varchar(20),
		@poHpOut varchar(24),
		@poStatusDtOut date,
		@poStatusCode varchar(100),
		@poStatusDesc varchar(100),
		@poMessage varchar(100),
		@partnerID varchar(100),
		@statusMainDealer varchar(100),
		@statusmss varchar(100),
		@statusMainDealerID int,
		@seq int
		 
IF OBJECT_ID('tempdb..##listRowMktUpdMss') IS NOT NULL DROP TABLE ##listRowMktUpdMss  
IF OBJECT_ID('tempdb..##rowParamMktUpdMss') IS NOT NULL DROP TABLE ##rowParamMktUpdMss 

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
		  
		BEGIN
			SELECT B.QUESTION_API AS [NAME]
				,	case when stringvalue ='null' then null when stringvalue = '' then null else stringvalue end as   stringvalue
				,	ROW_NUMBER() OVER (
					ORDER BY element_id
					) AS rowNum ,e.*,
			D.IS_MANDATORY,
			B.QUESTION_IDENTIFIER
			INTO #PARAM_FINAL
			FROM #PARAM A
			JOIN M_MKT_POLO_QUESTIONGROUP_D B
			ON A.NAME=B.QUESTION_API
			JOIN M_MKT_POLO_QUESTIONGROUP_H C
			ON B.M_MKT_POLO_QUESTIONGROUP_H_ID=C.M_MKT_POLO_QUESTIONGROUP_H_ID AND C.QUESTIONGROUP_NAME=@apiName
			JOIN M_MKT_POLO_QUESTION_LIST D ON B.QUESTION_IDENTIFIER=D.QUESTION_IDENTIFIER
			JOIN M_MKT_POLO_QUESTION_LABEL E ON D.M_MKT_POLO_QUESTION_LABEL_ID=E.M_MKT_POLO_QUESTION_LABEL_ID
			WHERE ValueType != 'object'			 	  

			select @transactionId=StringValue from #PARAM_FINAL where name='orderId'
			
			select @statusmss=StringValue from #PARAM_FINAL where name='statusMss'
			
			SELECT @responseID = @guid 
		 
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
		declare @validasiFlag int
		set @validasiFlag = 0

		declare @HIER varchar(50)
		
		set @HIER = case when @statusmss = 'Unassign' then '''Unassign'''+',' +'''Pending''' when @statusmss='Pending' then '''Unassign'''+',' +'''Pending''' else ''''+@statusmss+'''' end

		IF NOT EXISTS (select * from  WISE_STAGING..T_MKT_MARKETPLACE_ACQ WHERE TRANSACTION_ID=@transactionId) and @transactionId is not null
		BEGIN
			SET @processFlag = 1
			SET @validasiFlag = 1
			set @errorParamCode = '06'
		END
		ELSE IF NOT EXISTS (SELECT ID_STATUS,STATUS FROM M_MKT_MARKETPLACE_STATUS WHERE  status_mss_wise =@HIER) and @statusmss is not null
		BEGIN
			SET @processFlag = 1
			SET @validasiFlag = 1
			set @errorParamCode = '05'
		END
		
		DECLARE @resultVal CHAR(1) = 'T'
	,@nextFlag INT = 1 --1 lanjut, 0 stop
DECLARE @labelId BIGINT = '20'
DECLARE @return CHAR(1) = 'T'
	,@stringValue NVARCHAR(max)
	,@param_in_err VARCHAR(MAX)
		,@lengh_char VARCHAR(10)
		,@question_api varchar(50)
		
		/*validasi Numeric*/
		IF(@processFlag=0)
		BEGIN
		
								/*validasi Mandatory*/
								IF @return != 'F' 
								BEGIN
									DECLARE C1 CURSOR
									FOR
									SELECT M_MKT_POLO_QUESTION_LABEL_ID
										,StringValue
										,[NAME]
									FROM #PARAM_FINAL
									WHERE IS_MANDATORY = 1

									OPEN C1

									FETCH NEXT
									FROM C1
									INTO @labelId
										,@stringValue
										,@question_api

									WHILE @@FETCH_STATUS = 0
									BEGIN
										BEGIN
											EXEC [dbo].[spMKT_POLO_ValidationParamInMandatory] @labelId = @labelId
												,@value = @stringValue
												,@result = @return OUTPUT
												,@responseCode = @responseCode OUTPUT
										
											IF @return = 'F'
											BEGIN
												SET @nextFlag = 0
												SET @validasiFlag = 1
												SET @param_in_err = @question_api
												SET @responseCode = '12'
												BREAK
											END
										END

										FETCH NEXT
										FROM C1
										INTO @labelId
											,@stringValue
											,@question_api
									END

									CLOSE C1

									DEALLOCATE C1
								END

								IF @return != 'F'
								BEGIN
									DECLARE C1 CURSOR
									FOR
									SELECT M_MKT_POLO_QUESTION_LABEL_ID
										,StringValue
										,[NAME]
									FROM #PARAM_FINAL
									WHERE RESPONSE_NUMERIC IS NOT NULL

									OPEN C1

									FETCH NEXT
									FROM C1
									INTO @labelId
										,@stringValue
										,@question_api

									WHILE @@FETCH_STATUS = 0
									BEGIN
										BEGIN
											EXEC [dbo].[spMKT_POLO_ValidationParamInNumeric] @labelId = @labelId
												,@value = @stringValue
												,@result = @return OUTPUT
												,@responseCode = @responseCode OUTPUT


											IF @return = 'F'
											BEGIN
												SET @nextFlag = 0
												SET @validasiFlag = 1
												SET @param_in_err = @question_api
												BREAK
											END
										END

										FETCH NEXT
										FROM C1
										INTO @labelId
											,@stringValue
											,@question_api
									END

									CLOSE C1

									DEALLOCATE C1
								END
								
								
								/*validasi Length*/
								IF @return != 'F' 
								BEGIN
									DECLARE C1 CURSOR
									FOR
									SELECT M_MKT_POLO_QUESTION_LABEL_ID
										,StringValue
										,[NAME]
									FROM #PARAM_FINAL
									WHERE RESPONSE_LENGTH IS NOT NULL

									OPEN C1

									FETCH NEXT
									FROM C1
									INTO @labelId
										,@stringValue
										,@question_api

									WHILE @@FETCH_STATUS = 0
									BEGIN
										BEGIN
											EXEC [dbo].[spMKT_POLO_ValidationParamInLength] @labelId = @labelId
												,@value = @stringValue
												,@result = @return OUTPUT
												,@responseCode = @responseCode OUTPUT

											IF @return = 'F'
											BEGIN
												SET @nextFlag = 0
												SET @validasiFlag = 1
												SET @param_in_err = @question_api
												SELECT @lengh_char = MPLBL.MAX_LENGTH FROM WISE_STAGING.dbo.M_MKT_POLO_QUESTION_LABEL  MPLBL
												JOIN WISE_STAGING.dbo.M_MKT_POLO_QUESTION_LIST MPLIST ON MPLIST.M_MKT_POLO_QUESTION_LABEL_ID = MPLBL.M_MKT_POLO_QUESTION_LABEL_ID
												JOIN WISE_STAGING.dbo.M_MKT_POLO_QUESTIONGROUP_D MPGD ON MPGD.QUESTION_IDENTIFIER = MPLIST.QUESTION_IDENTIFIER
												WHERE MPGD.QUESTION_API = @question_api
							
												BREAK
											END
										END

										FETCH NEXT
										FROM C1
										INTO @labelId
											,@stringValue
											,@question_api
									END

									CLOSE C1

									DEALLOCATE C1
								END
		
								

								
										
								/*validasi Date*/
								IF @return != 'F' 
								BEGIN
									DECLARE C1 CURSOR
									FOR
									SELECT M_MKT_POLO_QUESTION_LABEL_ID
										,StringValue
										,[NAME]
									FROM #PARAM_FINAL
									WHERE (
											RESPONSE_DATE IS NOT NULL
											AND LTRIM(RTRIM(RESPONSE_DATE)) <> ''
											)

									OPEN C1

									FETCH NEXT
									FROM C1
									INTO @labelId
										,@stringValue
										,@question_api

									WHILE @@FETCH_STATUS = 0
									BEGIN
										BEGIN
											EXEC [dbo].[spMKT_POLO_ValidationParamInDate] @labelId = @labelId
												,@value = @stringValue
												,@result = @return OUTPUT
												,@responseCode = @responseCode OUTPUT
											IF @return = 'F'
											BEGIN
												SET @nextFlag = 0
												SET @validasiFlag = 1
												SET @param_in_err = @question_api

												BREAK
											END
										END

										FETCH NEXT
										FROM C1
										INTO @labelId
											,@stringValue
											,@question_api
									END

									CLOSE C1

									DEALLOCATE C1
								END
		

								/*validasi Email*/
								IF @return != 'F'
								BEGIN
									DECLARE C1 CURSOR
									FOR
									SELECT M_MKT_POLO_QUESTION_LABEL_ID
										,StringValue
										,[NAME]
									FROM #PARAM_FINAL
									WHERE RESPONSE_EMAIL IS NOT NULL

									OPEN C1

									FETCH NEXT
									FROM C1
									INTO @labelId
										,@stringValue
										,@question_api

									WHILE @@FETCH_STATUS = 0
									BEGIN
										BEGIN
											EXEC [dbo].[spMKT_POLO_ValidationParamInEmail] @labelId = @labelId
												,@value = @stringValue
												,@result = @return OUTPUT
												,@responseCode = @responseCode OUTPUT

											IF @return = 'F'
											BEGIN
												SET @nextFlag = 0
												SET @validasiFlag = 1
												SET @param_in_err = @question_api

												BREAK
											END
										END

										FETCH NEXT
										FROM C1
										INTO @labelId
											,@stringValue
											,@question_api
									END

									CLOSE C1

									DEALLOCATE C1
								END
								
								IF @return = 'F' 
								BEGIN
									SET @processFlag = 1
									SET @errorParamCode = @responseCode
								END 
								
		END
		
												
		/*jika prameter sudah sesuai=200*/		
		IF @processFlag = 0 and @nextFlag = 1
		BEGIN  
			--/*Execute SP Utama*/  
			BEGIN
				select @transactionId=TRANSACTION_ID,@orderId=order_id,@partnerID=PARTNER_ID from  WISE_STAGING..T_MKT_MARKETPLACE_ACQ WHERE TRANSACTION_ID=@transactionId
				
				select @statusMainDealer=STATUS,@statusMainDealerID=ID_STATUS from WISE_STAGING..M_MKT_MARKETPLACE_STATUS WHERE  status_mss_wise =@HIER

				select @seq=max(SEQUENCE) from T_MKT_MARKETPLACE_STATUS where TRANSACTION_ID=@transactionId


				UPDATE WISE_STAGING..T_MKT_MARKETPLACE_ACQ SET ID_STATUS=@statusMainDealerID,DTM_UPD=getdate(),USR_UPD='maindealer_upd_status_mss'  WHERE TRANSACTION_ID=@transactionId

				INSERT INTO WISE_STAGING..T_MKT_MARKETPLACE_STATUS (ORDER_ID,TRANSACTION_ID,PARTNER_ID,SEQUENCE,ID_STATUS,STATUS_DT,DTM_CRT,USR_CRT,STATUS_MSS_WISE)
				values(@orderId,@transactionId,@partnerID,isnull(@seq,0)+1,@statusMainDealerID,GETDATE(),GETDATE(),'maindealer_upd_status_mss',@statusmss)

				set @poStatusCode='00'

					
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
			SELECT @responseMessage = RESPONSE_DESC, @responseCode=RESPONSE_CODE
				  FROM WISE_STAGING.DBO.M_MKT_MARKETPLACE_RESPONSE WITH(NOLOCK)
				 WHERE IS_ACTIVE = '1'
				   AND RESPONSE_CODE = '00' 


			/*set json*/ 
			SET @responseJson= (select @transactionId as orderId ,@responseCode as responseCode ,@responseMessage responseMessage
								for json path, without_array_wrapper)

			/*insert log response - valid*/		
			INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, TRANSACTION_ID,RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC,PARAMETER, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT)
			VALUES (@apiName,@orderId,@transactionId, @responseCode, @responseMessage, NULL,@responseJson, GETDATE(), @responseID, GETDATE(), 'System')

			select @transactionId as orderId ,@responseCode as responseCode ,@responseMessage responseMessage
			  
			
		END
		ELSE
		BEGIN
			IF @messageCodeX = '400'
			BEGIN
				/*insert log response - invalid ParamError*/ 
				SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
				 FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
				 WHERE RESPONSE_CODE = '02' 
				 
				SET @responseMessage = 'Param Error - ' + @messageErr
				   
				/*set json*/
				SELECT  isnull(@transactionId,'') as orderId ,isnull(@responseCode,'') responseCode, isnull(@responseMessage,'') responseMessage into #ResponseJsonErr1
				SET @responseJson=''
				SET @responseJson= (select orderId ,responseCode, responseMessage from #ResponseJsonErr1
								for json path, without_array_wrapper)
									 

				INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID,TRANSACTION_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)
				VALUES (@apiName,@orderId,@transactionId, @responseCode, @responseMessage , substring(@messageErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System',@responseJson)

 
				/*set response api - invalid*/  
				SELECT * from #ResponseJsonErr1
				
			END
			ELSE IF(@validasiFlag = 1 )
			BEGIN
				/*insert log response - invalid ParamError*/ 
				SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
				  FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
				 WHERE RESPONSE_CODE = @errorParamCode 



				 if  @responseCode IN ('09','10','11','12')
				begin
					SET @responseMessage = REPLACE(@responseMessage, '[Param_IN]', @param_in_err)
					IF (SELECT CHARINDEX('[n]', @responseMessage)) <> 0
					BEGIN 
						SET @responseMessage = REPLACE(@responseMessage, '[n]', @lengh_char)
					END
				end
				
				/*set json*/
				SELECT isnull(@transactionId,'') as orderId ,isnull(@responseCode,'') responseCode, isnull(@responseMessage,'') responseMessage into #ResponseJsonErr3

				SET @responseJson=''
				SET @responseJson= (select orderId ,responseCode, responseMessage from #ResponseJsonErr3
								for json path, without_array_wrapper)
									 
									 
				 
				INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID,TRANSACTION_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)
				VALUES (@apiName,@orderId,@transactionId, @responseCode, @responseMessage , substring(@messageErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System',@responseJson)

 
				/*set response api - invalid*/  
				SELECT * from #ResponseJsonErr3
			END
			ELSE
			BEGIN
				/*set json*/
				SELECT isnull(@transactionId,'') as orderId ,isnull(@responseCode,'') responseCode, isnull(@responseMessage,'') responseMessage into #ResponseJsonErr2
				SET @responseJson=''
				SET @responseJson= (select orderId ,responseCode ,responseMessage from #ResponseJsonErr2
								for json path, without_array_wrapper)

				/*insert log response - invalid*/ 
				INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID,TRANSACTION_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)
				VALUES (@apiName,@orderId,@transactionId, @responseCode, @responseMessage, substring(@messageErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System',@responseJson)

 
				/*set response api - invalid*/  
				SELECT * from #ResponseJsonErr2 
			END
			
		END 
 
	END TRY

	BEGIN CATCH
		DECLARE @ERRMSG VARCHAR(MAX), @ERRSEVERITY INT, @ERRSTATE INT, @ERR_LINE VARCHAR(MAX), @messageSystemErr varchar(max)
		SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
		  FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
		 WHERE  RESPONSE_CODE = '01'

		SELECT @ERRMSG = ERROR_MESSAGE(), @ERRSEVERITY = ERROR_SEVERITY(), @ERRSTATE = ERROR_STATE(),@ERR_LINE=ERROR_LINE()		
		   SET @messageSystemErr=''+ISNULL(@messageX,'') +ISNULL(@ERRMSG,'')+' at Line : '+ISNULL(CAST(@ERR_LINE AS VARCHAR),'')

		/*set json*/
		SELECT isnull(@transactionId,'') as orderId,isnull(@responseCode,'') responseCode, isnull(@responseMessage,'')+' - '+substring(isnull(@messageSystemErr,''), 1,100) responseMessage,substring(isnull(@messageSystemErr,''), 1,100) errorMessage into #ResponseJsonErrOTH
		SET @responseJson=''
		SET @responseJson= (select orderId ,responseCode ,responseMessage from #ResponseJsonErrOTH
								for json path, without_array_wrapper) 

		/*insert log response - Error*/
		INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID,TRANSACTION_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT, PARAMETER)
		VALUES (@apiName,@orderId,@transactionId, @responseCode, @responseMessage, substring(@messageSystemErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System', @responseJson)

		/*set response api - error*/  
		SELECT * from #ResponseJsonErrOTH
 
	END CATCH
END
ELSE 
BEGIN
	/*insert log response - invalid*/
	 SELECT @responseMessage = RESPONSE_DESC, @responseCode=RESPONSE_CODE
				  FROM WISE_STAGING.DBO.M_MKT_MARKETPLACE_RESPONSE WITH(NOLOCK)
				 WHERE IS_ACTIVE = '1'
				   AND RESPONSE_CODE = '01'

	SET @messageErr='Parameter cannot be empty'

	SET @responseJson=''
	SET @responseJson= (select isnull(@transactionId,'') as orderId ,isnull(@responseCode,'') as responseCode ,isnull(@responseMessage,'')+' - '+substring(isnull(@messageErr,''), 1,100) responseMessage
								for json path, without_array_wrapper) 

	/*insert log response - Error*/
		INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID,TRANSACTION_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT, PARAMETER)
		VALUES (@apiName,@orderId,@transactionId, @responseCode, @responseMessage, substring(@messageSystemErr, 1,100), GETDATE(), @responseID, GETDATE(), 'System', @responseJson)
 
	/*set response api - invalid*/ 
	SELECT isnull(@transactionId,'') as orderId ,isnull(@responseCode,'') as responseCode ,isnull(@responseMessage,'')+' - '+substring(isnull(@messageErr,''), 1,100) responseMessage

END

