  USE WISE_STAGING
  GO
--=======================================================================================================================================
--|| Author		: Juanda Nico Hasibuan
--|| Create date	: 23-11-2021
--|| Description	: Main Process pada API Maindealer
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
 
CREATE PROCEDURE [dbo].[spMKT_MAINDEALER_MAINGATE] (@guid nvarchar(max),@parameterBody NVARCHAR(MAX))  
AS  
  
DECLARE @apiName VARCHAR(200)   
 , @execSP VARCHAR(100)   
 , @sqlCmd NVARCHAR(MAX)   
 , @taskId varchar(100)  
 , @jsonString nvarchar(max)  
 , @messageErr NVARCHAR(MAX)  
 , @responseID VARCHAR(500)  =@guid
 , @responseCode NVARCHAR(MAX)  
 , @responseMessage NVARCHAR(MAX)  
 , @responseJson NVARCHAR(max)  
 , @flag char(1)='T'  
  
/*Declare Transform JSON*/   
DECLARE @SELECTLIST VARCHAR(MAX),@listFinal varchar(max),@sqlStr nvarchar(max)  
DECLARE @successCode varchar(3),@errorParamCode varchar(3),@errorSystemCode varchar(3) , @errorParamSucesErr varchar(3)    
DECLARE @countErr int=0, @countData int=0, @selisih int   
DECLARE @jsonError varchar(max)    
DECLARE @orderID varchar(100) 
  
BEGIN   
 
	select top 1  value as jsonString  
	  into #jsonString  
	  From openJson (@parameterBody)  
	select @jsonString = jsonString from #jsonString   

	SELECT *  
	  INTO #PARAM  
	  FROM fnMKT_POLO_parseJSON(@parameterBody)   
  
	SELECT Top 1 @apiName = stringvalue  FROM #PARAM WHERE UPPER([NAME]) ='IDNAME'  
	SELECT Top 1 @orderID = stringvalue  FROM #PARAM WHERE UPPER([NAME]) ='ORDERID'  
  
	SELECT @execSP = PARAMETER_VALUE  
	  FROM M_MKT_POLO_PARAMETER  
	 WHERE PARAMETER_ID = @apiName  
  
	IF LEN(@apiName)=0 OR nullif(@apiName,'null') is null
	BEGIN  
		SET @flag='F'  
		SET @messageErr='IDNAME is required'  
	END  
    
	IF @flag='T'
	BEGIN
		IF (select count(1) from M_MKT_POLO_PARAMETER where PARAMETER_ID=@apiName ) = 0  
			OR (select count(1) from M_MKT_POLO_QUESTIONGROUP_H where QUESTIONGROUP_NAME=@apiName ) = 0   
		BEGIN  
			SET @flag='F'  
			SET @messageErr='IDNAME is not registered'  
		END  
	END
  
	IF @flag='F'  
	BEGIN  
		SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
		FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
		WHERE RESPONSE_CODE = '30'   
  
		SELECT @responseCode 'responseCode', @responseMessage+' - '+@messageErr 'responseMessage' INTO #responseJsonErrPrm   
		SET @responseJson= (SELECT * FROM #responseJsonErrPrm FOR JSON AUTO, without_array_wrapper)     
  
		INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)  
		VALUES (@apiName,@orderID, @responseCode, @responseMessage, @messageErr, GETDATE(), @responseID, GETDATE(), 'System',@responseJson)  
   
		/*set response api - Error Param*/   
		SELECT @responseCode 'responseCode', @responseMessage+' - '+@messageErr 'responseMessage' , @messageErr errorMessage  
	END    
 
	IF @flag='T'   
	BEGIN  
		SET @sqlCmd ='EXEC '+@execSP +' '''+@guid+''''+', '''+@parameterBody+''''      
		EXEC SP_EXECUTESQL @sqlCmd   
	END    
    
   
END  
 /*  
   
 EXEC spMKT_POLO_MAINGATE  '999999',
 '{
    "idName": "maindealer_cust_acquisition",
    "orderIdDealer": "WHN000053",
    "dealerId": "00007",
    "idNo": "3520064908910001",
    "fullName": "Elisa Yuliana",
    "birthPlace": "Tangerang",
    "birthDate": "1991-09-08",
    "surveyAddr": "Jalan Kebon Baru no.93",
    "surveyRT": "002",
    "surveyRW": "006",
    "surveyProvince": "BANTEN",
    "surveyCity": "KAB-Tangerang",
    "surveySubDistrict": "Cikupa",
    "surveyVillage": "Talaga Sari",
    "surveyZipcode": "15710",
    "legalAddr": "Jalan Rajasa No.109",
    "legalRt": "002",
    "legalRw": "006",
    "legalProvince": "BANTEN",
    "legalCity": "KAB-Tangerang",
    "legalSubDistrict": "Curug",
    "legalVilage": "Curug Kulon",
    "legalZipcode": "15810",
    "mobilePhone": "085775786850",
    "motherName": "SekarSari"
}'
  
 */    
  
    