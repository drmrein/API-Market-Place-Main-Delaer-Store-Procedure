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
/****** Object:  StoredProcedure [dbo].[spRpt_WOM_MKT_MAINDEALER_EXPORT]    Script Date: 11/22/21 9:00:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
--=======================================================================================================================================
--||Author		: Arif
--||Create date	: 23-11-2021
--||Description	: Untuk mengexport data yang ada pada menu dashboard Main Dealer untuk provide report funnel main dealer
--|| History	: 
--|| Version	: v1.0.20211123
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| Date			| Type		| Version			| Name					|No Project				| Description											 
--||-------------------------------------------------------------------------------------------------------------------------------------
--|| 23-11-2021		| Create 	| v1.0.20211123		| Arif					|BR/2021/JUL/MKT/001    | API Main Dealer 
--=======================================================================================================================================
*/


CREATE PROCEDURE [dbo].[spRpt_WOM_MKT_MAINDEALER_EXPORT](
@piID_PARTNER VARCHAR(100),
@piPRODUCT_TYPE VARCHAR(100),
@piSDATE DATETIME,
@piEDATE DATETIME,
@piSTATUS_ORDER INT,
@piBRANCH INT) 
AS
BEGIN
SET NOCOUNT ON


SELECT 	acq.ORDER_ID as acq_ORDER_ID,
			isnull(acq.PARTNER_ID,'') as ID_AGENT,
			isnull(mPartner.NAME_MARKETPLACE,'') as NAMA_AGENT,
			isnull(acq.FULL_NAME,'') as NAMA_CALON_PEMINJAMAN,
			isnull(acq.MODEL_DESC,'') as MODEL_DESC,
			isnull(acq.PRODUCT_TYPE_DESC,'') as PRODUCT_TYPE,
			isnull(acq.FINANCE_AMOUNT,0) as FINANCE_AMOUNT,
			mstat.STATUS as [STATUS],
			cast((FORMAT(temp.STATUS_DT, 'yyyy-MM-dd HH:mm:ss')) as varchar(20)) as TGL_STATUS,	
			isnull((select orx.office_region_name from CONFINS.dbo.REF_OFFICE ro
			join		   CONFINS.dbo.REF_OFFICE_AREA roa on  ro.REF_OFFICE_AREA_ID = roa.REF_OFFICE_AREA_ID
			join		   CONFINS.dbo.OFFICE_REGION_MBR_X ormx on roa.REF_OFFICE_AREA_ID = ormx.REF_OFFICE_AREA_ID
			join		   CONFINS.dbo.OFFICE_REGION_X orx on ormx.OFFICE_REGION_X_ID =orx.office_region_x_id
			where ro.REF_OFFICE_ID=(select ro.REF_OFFICE_id FROM  [CONFINS].[dbo].REF_OFFICE ro where ro.OFFICE_CODE =  acq.OFFICE_CODE)
			),'') as REGION,
			isnull((select ro.OFFICE_NAME FROM  [CONFINS].[dbo].REF_OFFICE ro where ro.OFFICE_CODE = acq.OFFICE_CODE),'') as CABANG,
			isnull(ACQ.AGRMNT_NO,'') as AGRMNT_NO,
			isnull(ACQ.PO_NO,'') as PO_NO,
			isnull(cast((FORMAT(ACQ.PO_DATE, 'yyyy-MM-dd HH:mm:ss')) as varchar(20)),'') as PO_DATE,	
			isnull(ACQ.PO_DP,0) as PO_DP,
			isnull(ACQ.PO_TENOR,0) as PO_TENOR,
			isnull(ACQ.INSTALMENT_AMT,0) as INSTALMENT_AMT,
			isnull((select ro.REF_OFFICE_ID FROM  [CONFINS].[dbo].REF_OFFICE ro where ro.OFFICE_CODE = acq.OFFICE_CODE),'') as REF_OFFICE_ID,
			mstat.ID_STATUS
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
			
			SELECT * FROM #LIST_DATA_ACQ
			WHERE  (REF_OFFICE_ID = @piBRANCH or (0 = @piBRANCH))
			order by ID_AGENT,acq_ORDER_ID,ID_STATUS
	
END

