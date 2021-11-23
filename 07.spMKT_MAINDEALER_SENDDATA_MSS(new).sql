USE [WISE_STAGING]
GO 
--=======================================================================================================================================
--||Author		: Juanda Nico Hasibuan
--||Create date	: 23-11-2021
--||Description	: Pupulate data untuk dikirim ke mss
--|| History	: 
--|| Version    : v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description												 
--||-------------------------------------------------------------------------------------------------------------------------------------- 
--|| 23-11-2021		| Create 	| v1.0.20211123		| Juanda Nico Hasibuan	|BR/2021/JUL/MKT/001    | API Marketplace & Main Dealer - Phase Main Dealer​
--======================================================================================================================================= 
CREATE PROCEDURE [dbo].[spMKT_MAINDEALER_SEND_TO_MSS]
	@orderId VARCHAR(100),
	@guid NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @selectQuery nvarchar(max)
	DECLARE @columnList varchar(max)
	DECLARE @jsonParam NVARCHAR(max), @apiName VARCHAR(100)='maindealer_send_data_mss'
	IF OBJECT_ID('tempdb..##DataMainDToMSS') IS NOT NULL DROP TABLE ##DataMainDToMSS  
	SET @columnList = STUFF((SELECT ', ' + 
		(CASE 
			WHEN Li.ANSWER_TYPE = 'EXPRESSION' THEN Li.LOV  
			ELSE La.QUESTION_CODE
		END
		) + ' AS [' + D.QUESTION_API + ']'
		FROM M_MKT_POLO_QUESTIONGROUP_D D
			JOIN M_MKT_POLO_QUESTION_LIST Li ON Li.QUESTION_IDENTIFIER = D.QUESTION_IDENTIFIER AND Li.IS_ACTIVE = 1
			JOIN M_MKT_POLO_QUESTION_LABEL La ON La.M_MKT_POLO_QUESTION_LABEL_ID = Li.M_MKT_POLO_QUESTION_LABEL_ID
			JOIN M_MKT_POLO_QUESTIONGROUP_H H ON H.M_MKT_POLO_QUESTIONGROUP_H_ID = D.M_MKT_POLO_QUESTIONGROUP_H_ID AND H.IS_ACTIVE = 1
		WHERE H.QUESTIONGROUP_NAME = @apiName
		ORDER BY d.SEQUENCE asc
		FOR XML PATH('')), 1, 1, '') 

	SET @selectQuery = N'
		SELECT ' + @columnList + N'
		INTO ##DataMainDToMSS
		FROM T_MKT_MARKETPLACE_ACQ ACQ
		LEFT JOIN M_MKT_MARKETPLACE_PARTNER PART
		ON PART.ID_MARKETPLACE=ACQ.PARTNER_ID
		WHERE TRANSACTION_ID = ''' + @orderId + ''''

	EXEC sp_executesql @selectQuery
	 
	SELECT * FROM ##DataMainDToMSS

	DROP table ##DataMainDToMSS
END

/*
EXEC spMKT_MAINDEALER_SEND_TO_MSS 'MD0000057','999'


*/
