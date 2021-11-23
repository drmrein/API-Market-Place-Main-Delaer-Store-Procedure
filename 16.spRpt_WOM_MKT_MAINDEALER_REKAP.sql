/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.1601)
    Source Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2016
    Target Database Engine Edition : Microsoft SQL Server Enterprise Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [WISE_STAGING]
GO

/****** Object:  StoredProcedure [dbo].[spRpt_WOM_MKT_MAINDEALER_REKAP ]    Script Date: 11/22/21 9:02:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




 /*
--=======================================================================================================================================
--||Author		: Arif
--||Create date	: 23-11-2021
--||Description	: Untuk menampilkan data list rekap pada menu dashboard Main Dealer.
--|| History	: 
--|| Version	: v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description											 
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| 23-11-2021		| Create 	| v1.0.20211123		| Arif					|BR/2021/JUL/MKT/001    | API Main Dealer 
--=======================================================================================================================================
*/


CREATE PROCEDURE [dbo].[spRpt_WOM_MKT_MAINDEALER_REKAP](
@piID_PARTNER VARCHAR(100),
@piPRODUCT_TYPE VARCHAR(100),
@piSDATE DATETIME,
@piEDATE DATETIME,
@piSTATUS_ORDER INT,
@piBRANCH INT) 
AS
BEGIN
SET NOCOUNT ON

	SELECT	acq.PARTNER_ID as ID_AGENT,
			mstat.ID_STATUS,
			isnull((select ro.REF_OFFICE_ID FROM  [CONFINS].[dbo].REF_OFFICE ro where ro.OFFICE_CODE = acq.OFFICE_CODE),'') as REF_OFFICE_ID	
			INTO #LIST_DATA_ACQ 
			from T_MKT_MARKETPLACE_ACQ acq
			left join WISE_STAGING.DBO.M_MKT_MARKETPLACE_PARTNER mPartner on acq.PARTNER_ID=mPartner.ID_MARKETPLACE
			INNER JOIn (
			SELECT TMS.ORDER_ID, TMS.PARTNER_ID, TMS.ID_STATUS, TMS.[SEQUENCE], TMS.STATUS_DT,TRANSACTION_ID
			FROM T_MKT_MARKETPLACE_STATUS TMS  
			WHERE STATUS_DT=(
			select MAX(TMS_MAX.STATUS_DT) from T_MKT_MARKETPLACE_STATUS TMS_MAX WHERE TMS_MAX.ORDER_ID=TMS.ORDER_ID AND TMS_MAX.TRANSACTION_ID=TMS.TRANSACTION_ID AND TMS_MAX.PARTNER_ID=TMS.PARTNER_ID
			GROUP BY TMS_MAX.ORDER_ID, TMS_MAX.TRANSACTION_ID, TMS_MAX.PARTNER_ID)
				) as temp on acq.ORDER_ID=temp.ORDER_ID and acq.PARTNER_ID=temp.PARTNER_ID AND temp.TRANSACTION_ID=acq.TRANSACTION_ID
			LEFT JOIN  M_MKT_MARKETPLACE_STATUS as mstat on temp.ID_STATUS=mstat.ID_STATUS	
			where (acq.PARTNER_ID=@piID_PARTNER or ('ALL'=@piID_PARTNER)) and
			(LTRIM(RTRIM(acq.PRODUCT_TYPE_DESC))=@piPRODUCT_TYPE or ('ALL'=@piPRODUCT_TYPE))
			and acq.ORDER_DT is not null
			and (FORMAT(acq.ORDER_DT, 'yyyy-MM-dd') between @piSDATE and @piEDATE)
			AND (acq.ID_STATUS=@piSTATUS_ORDER or (0 = @piSTATUS_ORDER))
			and acq.SOURCE_DATA='Main_Dealer'

	select * 
	into #tempfinal
	from #LIST_DATA_ACQ
	where (REF_OFFICE_ID = @piBRANCH or (0 = @piBRANCH))

	DECLARE @RECEIVED int,
	@SURVEY int,
	@PROGRESS int,
	@APPROVE int,
	@REJECT int,
	@CANCELWISE int,
	@CANCELMSS int,
	@PO int,
	@CAIR int,
	@FAILED int    

	select @RECEIVED= isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=1
	select @SURVEY = isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=2
	select @PROGRESS =  isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=3
	select @APPROVE = isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=4
	select @REJECT =  isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=5
	select @CANCELWISE =  isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=6
	select @CANCELMSS =  isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=7
	select @PO = isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=8
	select @CAIR =  isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=9
	select @FAILED =  isnull(COUNT(ID_AGENT),0) from #tempfinal where ID_STATUS=10
	
	select @RECEIVED as received, @SURVEY as survey,@PROGRESS as approveProgress, @APPROVE as  approved ,@REJECT as reject,@CANCELWISE as cancelWise,@CANCELMSS as cancelMss, @PO as po,	@CAIR as cair,@FAILED as failed

END

GO


