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
/****** Object:  StoredProcedure [dbo].[spWOM_MKT_MAINDEALER_APIUPDATEDATA_FROM_MSSWISE]    Script Date: 11/22/21 9:04:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 --===============================================================================================================================================================================
--||Author		: arif 																																			 
--||Create date	: 23-11-2021																																					
--||Description	: Procedure untuk Menenentkan Stored Procedure Update maindealer berdasarkan data kiriman dari WISE dan MSS 																																	 
--||Version		: v1.0.20211123																																	 
--||History		:																																								
--||----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--|| Date           | Type    | Version         | Name                        | Description                                          |Detail                                            
--||----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--|| 23-11-2021     | Create  | v1.0.20211123   | Arif    		              | BR/2021/JUL/MKT/001                                  |API Main Dealer                                          
 --===============================================================================================================================================================================
 
CREATE PROCEDURE [dbo].[spWOM_MKT_MAINDEALER_APIUPDATEDATA_FROM_MSSWISE] (@guid nvarchar(max),@parameterBody NVARCHAR(MAX))  
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
  
	IF nullif(@apiName,'null') is null
	BEGIN  
		SET @flag='F'  
		SET @messageErr='idName is required'  
		set @responseCode = '02'
	END  

	if LEN(@apiName)=0
	BEGIN  
		SET @flag='F'  
		SET @messageErr='idName is mandatory'  
		set @responseCode = '12'
	END 
    
	IF @flag='T'
	BEGIN
		IF (select count(1) from M_MKT_POLO_PARAMETER where PARAMETER_ID=@apiName ) = 0  OR (select count(1) from M_MKT_POLO_QUESTIONGROUP_H where QUESTIONGROUP_NAME=@apiName ) = 0   
		BEGIN  
			SET @flag='F'  
			SET @messageErr='idName is not registered'
			set @responseCode = '02'  
		END  
	END

  
	IF @flag='F'  
	BEGIN  
		SELECT @responseMessage = RESPONSE_MESSAGE, @responseCode=RESPONSE_CODE
		FROM WISE_STAGING.DBO.M_MKT_MAINDEALER_RESPONSECODE WITH(NOLOCK)
		where RESPONSE_CODE = @responseCode   
		if @responseCode ='02'
		begin
			set @responseMessage =  'Param Error '+' - '+@messageErr
		end
		else
		begin
			set @responseMessage =  'Error - idName is mandatory'
		end
		SELECT @orderID orderId ,@responseCode 'responseCode', @responseMessage 'responseMessage' INTO #responseJsonErrPrm   
		SET @responseJson= (SELECT * FROM #responseJsonErrPrm FOR JSON AUTO, without_array_wrapper)     
  
		INSERT INTO T_MKT_MARKETPLACE_APILOGRESPONSE (ID_NAME,ORDER_ID,TRANSACTION_ID, RESPONSE_CODE, RESPONSE_MESSAGE, ERROR_DESC, RESPONSE_DT, RESPONSE_ID, DTM_CRT, USR_CRT,PARAMETER)  
		VALUES (@apiName,null,@orderID, @responseCode,  @responseMessage, '', GETDATE(), @responseID, GETDATE(), 'System',@responseJson)  
   
		/*set response api - Error Param*/   
		SELECT @orderID orderId,@responseCode 'responseCode',@responseMessage responseMessage, '' errorMessage  
	END    
 
	IF @flag='T'   
	BEGIN  
		SET @sqlCmd ='EXEC '+@execSP +' '''+@guid+''''+', '''+@parameterBody+''''      
		EXEC SP_EXECUTESQL @sqlCmd   
	END    
    
   
END  
 /*  
   
 EXEC spWOM_MKT_MAINDEALER_APIUPDATEDATA_FROM_MSSWISE 
  '9999919','{
    "idName":"s",
    "orderId":"MD129384",
    "statusMss":"Pending"
}'  
   
  
 */
 
 
 --select * from T_MKT_MARKETPLACE_APILOGREQUEST order by REQUEST_DT desc 
