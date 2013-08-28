PROCEDURE POReceiptCalculation:
/*----------------------------------------------------------------------------
Purpose:       Look for all Purchase receipts and returns. 
               Look for invoices, if available use them for the cost
               else use the Prucahse price. Also, look go logistics charges.
               Create value for all elements belonging to the cost set.
               Create an adjusted trgl_det and glt_det in case there is a 
               difference between the standard cost and calculated cost.
 
Parameters:
          Input - Item Number
                  Item Product Line
                  Item PM code
                  Site
                  Site Entity
                  Start Date
                  End Date
                  isAdjustmentMode (Complete or Adjustment )
                  Base Currency
                  Statutory Currency
                  StatISFallBack
                  Base Cost Set
                  Statutory Cost Set
                  Base Cost Set OID
                  Statutory Cost Set OID
                  Current Cost Calculation Period
                  Previous Cost Calculation Period  
                  Use Supplier Invoice Cost Only
                  Transcounter
                  Dataset(tapipostingdataiswithsaf)
 
    Input/Ouput - Dataset(pcdscal)
                  Dataset(tApiPostingSaf)
                  temp-table ttSafStrEntGLCCPrj
 
 
Exceptions:
Conditions:
       Pre:   NONE
      Post:   NONE
Notes:
History:
----------------------------------------------------------------------------*/
 
   define input  parameter pItemNumber          as character  no-undo.
   define input  parameter pItemProdLine        as character  no-undo.
   define input  parameter pItem_pm_code        as character  no-undo.
   define input  parameter pSite                as character  no-undo.
   define input  parameter pSiteEntity          as character  no-undo.
   define input  parameter pStartDate           as date       no-undo.
   define input  parameter pEndDate             as date       no-undo.
   define input  parameter pGlcStart            as date       no-undo.
   define input  parameter pGlcEnd              as date       no-undo.
   define input  parameter pPCCostMethod        as character  no-undo.
   define input  parameter pisAdjustmentMode	as logical    no-undo.
   define input  parameter pBaseCurrency	as character  no-undo.
   define input  parameter pStatCurrency	as character  no-undo.
   define input  parameter pStatIsFallBack      as logical    no-undo.
   define input  parameter pBaseCostSet     	as character  no-undo.
   define input  parameter pStatCostSet     	as character  no-undo.
   define input  parameter pBaseCostSetOID
   				       like cs_mstr.oid_cs_mstr no-undo.
   define input  parameter pStatCostSetOID
   					      like cs_mstr.oid_cs_mstr	no-undo.
   define input  parameter pCostCalcPeriodOID 
                                like glccp_det.oid_glccp_det	no-undo.
   define input  parameter pPrevCostCalcPeriodOID 
   				         like glccp_det.oid_glccp_det  no-undo.
   define input  parameter pPrevPeriodBaseCostSet as character no-undo.
   define input  parameter pPrevPeriodStatCostSet as character no-undo.
   define input  parameter pPrevPeriodBaseCostSetOID 
   			             like cs_mstr.oid_cs_mstr 	no-undo.
   define input  parameter pPrevPeriodStatCostSetOID 
   			             like cs_mstr.oid_cs_mstr 	no-undo.	                             
   define input  parameter pusing_supp_consign	as logical    no-undo.
   define input  parameter pin_gl_set like in_mstr.in_gl_set 	no-undo.
   define input  parameter pin_gl_cost_site	
   				        like in_mstr.in_gl_cost_site  no-undo.
   define input  parameter picc_gl_set	
   				      like icc_ctrl.icc_gl_set 	no-undo.
   define input  parameter psimcostset like in_mstr.in_gl_set 	no-undo.				      
   define input parameter pUseInvoiceCostOnly as logical no-undo.
   define input  parameter ppc_calc_daybook  like glt_dy_code    no-undo.
   define input  parameter ppc_daybook_desc  like dy_desc        no-undo.
   define input  parameter pmr_daybook       like glt_dy_code    no-undo.
   define input  parameter pmr_daybook_desc  like dy_desc        no-undo.
   define input  parameter pglmir_yn      like mfc_logical      no-undo.
   define input-output parameter pTranscounter  as integer    no-undo.
   define input-output parameter dataset for pcdscal.
   define input parameter        dataset for tapipostingdataiswithsaf.
   define input-output parameter dataset for tApiPostingSaf.
   define input-output parameter table for ttSafStrEntGLCCPrj.
 
 
   /* Local Variable Definitions */
   define variable lProject           	like pvod_det.pvod_project  no-undo.
   define variable lInvoiceAmt         	like trgl_det.trgl_gl_amt   no-undo.
   define variable lInvoiceplusTaxAmt  	like trgl_det.trgl_gl_amt   no-undo.
   define variable lUnitCost           	like tr_hist.tr_price       no-undo.
   define variable lAPMatchPrice       	like tr_hist.tr_price       no-undo.
   define variable lInvoiceExist       	like mfc_logical            no-undo.
   define variable lLogInvoiceExist       like mfc_logical          no-undo.
   define variable lLogisticsAccruAmount
   				    like pvod_det.pvod_vouchered_amt	no-undo.
   define variable lLogisticsVouchAmount  
   			      like pvod_det.pvod_vouchered_amt	no-undo.
   define variable lLogisticsTotalAmount  
   			           like pvod_det.pvod_vouchered_amt   no-undo.
   define variable lop_recno            as recid                      no-undo.
   define variable lStdSubAmount          like opgl_det.opgl_gl_amt   no-undo.
   define variable lSubAmount             like opgl_det.opgl_gl_amt   no-undo.
   define variable line_tax             like trgl_det.trgl_gl_amt     no-undo.
   define variable NRline_tax           like trgl_det.trgl_gl_amt     no-undo.
   define variable negPOline_tax        like trgl_det.trgl_gl_amt     no-undo.
   define variable luseWIPAcct            like mfc_logical            no-undo.
 
   define variable lInvLocationOID          like locd_det.oid_locd_det no-undo.   
 
   /* Logisitic Accounting Material Category cost total */
   define variable lLAMtlCatAccrucsttot	like spt_det.spt_cst_ll   no-undo.
 
   /* Logisitic Accounting Material Category cost total */
   define variable lLAMtlCatVouchcsttot like spt_det.spt_cst_ll no-undo.
 
   /* Logisitic Accounting Overhead Category cost total */
   define variable lLAOvhCatAccrucsttot like spt_det.spt_cst_ll  	no-undo.
 
   /* Logisitic Accounting Overhead Category cost total */
   define variable lLAOvhCatVouchcsttot like spt_det.spt_cst_ll 	no-undo.
 
   /* Logisitic Accounting Burden Category cost total */
   define variable lLABdnCatAccrucsttot like spt_det.spt_cst_ll 	no-undo.
 
   /* Logisitic Accounting Burden Category cost total */
   define variable lLABdnCatVouchcsttot like spt_det.spt_cst_ll 	no-undo.
 
   /* Logisitic Accounting SubContract Category cost total */
   define variable lLASubCatAccrucsttot like spt_det.spt_cst_ll 	no-undo.
 
   /* Logisitic Accounting SubContract Category cost total */
   define variable lLASubCatVouchcsttot like spt_det.spt_cst_ll 	no-undo.
 
   /* Logisitic Accounting Labor Category cost total */
   define variable lLALbrCatAccrucsttot like spt_det.spt_cst_ll 	no-undo.
 
   /* Logisitic Accounting Labor Category cost total */
   define variable lLALbrCatVouchcsttot like spt_det.spt_cst_ll 	no-undo.
 
   define variable l_lcVouchMatchPrice  like pvod_vouchered_amt   no-undo.
   define variable l_lcAccruMatchPrice  like pvod_vouchered_amt   no-undo.
   define variable l_mtl_std            like tr_hist.tr_mtl_std   no-undo.
   define variable l_ErrorNumber        as   integer              no-undo.
 
   define variable msgString            as character format "x(120)"    no-undo.
   define variable taxTransactionType   as character                    no-undo.
   define variable logisticsChargeAmount  as decimal                    no-undo.
   define variable nonlogchgmatcatamount  as decimal                    no-undo.
 
   define variable llastrcptforreceiver       like mfc_logical          no-undo.
   define variable lacd_internal_key_ref as character           no-undo.
   define variable dcol                  as character initial "::".
   define variable post_LAtaxamt           as decimal       no-undo.
   define variable post_LAtaxrecov_amt           as decimal       no-undo.
   define variable l_postLATaxNonRecovAmt        as decimal       no-undo.
   define variable l_prevpdPCOvhAmt              as decimal       no-undo. 
 
   /* Buffer Definition */
   define buffer tr_hist             for tr_hist.
   define buffer btr_hist             for tr_hist.  
   define buffer pvo_mstr            for pvo_mstr.
   define buffer pvod_det            for pvod_det.
   define buffer wo_mstr             for wo_mstr.
   define buffer wr_route            for wr_route.
   define buffer pod_det             for pod_det.
   define buffer wopm_det            for wopm_det.
   define buffer wopr_det            for wopr_det.
   define buffer op_hist             for op_hist.
   define buffer vd_mstr             for vd_mstr.
   define buffer lc_mstr             for lc_mstr.
   define buffer spt_det             for spt_det.
   define buffer sc_mstr             for sc_mstr.
   define buffer lacd_det            for lacd_det.
   define buffer lacod_det           for lacod_det.
   define buffer lgd_mstr            for lgd_mstr.
   define buffer lgdd_det            for lgdd_det.
 
   do on error undo, return error {&GENERAL-APP-EXCEPT}:
 
      for each tr_hist no-lock
         where tr_hist.tr_domain = global_domain
         and   tr_hist.tr_part           = pItemNumber
         and   tr_hist.tr_effdate       >= pStartDate
         and   tr_hist.tr_effdate       <= pEndDate
         and  (tr_hist.tr_type           = "RCT-PO"  or
               tr_hist.tr_type           = "ISS-PRV" or
               tr_hist.tr_type           = "RCT-LA")
         and   tr_hist.tr_site           = pSite:

         empty temp-table tt-neg-pocostinfo.
 
          /* MEMO ITEMS ARE NOT CONSIDERED
             FOR PERIODIC COST CALCULATION */
         if tr_hist.tr_ship_type <> "" and 
            tr_hist.tr_ship_type <> "S" 
         then next.
 
         if ( (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc < 0)) 
         then next.
 
         if can-find (first btr_hist 
            where btr_hist.tr_domain = global_domain
            and   btr_hist.tr_part   = tr_hist.tr_part
            and   btr_hist.tr_effdate = tr_hist.tr_effdate
            and   btr_hist.tr_lot     = tr_hist.tr_lot
            and   btr_hist.tr_trnbr   = tr_hist.tr_trnbr)
         then assign llastrcptforreceiver = No.
         else assign llastrcptforreceiver = Yes.
 
         for first vd_mstr no-lock
             where vd_mstr.vd_domain = global_domain
               and vd_mstr.vd_addr   = tr_hist.tr_addr:
         end.  /* first vd_mstr */
 
         for first pod_det no-lock
             where pod_det.pod_domain = global_domain
               and pod_det.pod_nbr    = tr_hist.tr_nbr
               and pod_det.pod_line   = tr_hist.tr_line:
            lProject = pod_det.pod_project.  
         end.  /* first pod_det */
         if not available pod_det then lProject = "".
 
         if (tr_hist.tr_qty_loc <> 0  or
            tr_hist.tr_type = "RCT-LA" )
         then do:
 
            /* This check will tell us to use WIP account or */
            /* COP account when using kanban                 */
            if tr_ship_type = "S"
            then do:
               {us/px/pxrun.i &PROC  = 'checkForKanbanWIPSupermarket'
                        &PROGRAM='pccalxr1.p'
                        &HANDLE = ph_pccalxr1
                        &PARAM = "(input tr_hist.tr_trnbr /* Transaction # */ ,
                                   output luseWIPAcct)"
                        &NOAPPERROR=true
                        &CATCHERROR=true}
               if return-value <> {&SUCCESS-RESULT}
               then return error {&APP-ERROR-RESULT}.
            end.
 
            /* FETCH THE COST OF PRODUCTION ACCOUNT */
            {us/bbi/gprun.i ""glactdft.p""
                      "(input ""WO_COP_ACCT"",
                        input pItemProdLine,
                        input pSite,
                        input """",
                        input """",
                        input no,
                        output dftCOPAcct,
                        output dftCOPSub,
                        output dftCOPCC)"}
 
            /* FETCH THE WIP ACCOUNT */
            {us/bbi/gprun.i ""glactdft.p""
                      "(input ""WO_WIP_ACCT"",
                        input pItemProdLine,
                        input pSite,
                        input """",
                        input """",
                        input no,
                        output dftWIPAcct,
                        output dftWIPSub,
                        output dftWIPCC)"}
 
            /* PURCHASE PRICE VARIANCE ACCOUNT DETAIL */
            {us/bbi/gprun.i ""glactdft.p""
                      "(input ""PO_PPV_ACCT"",
                        input pItemProdLine,
                        input pSite,
                        input if available vd_mstr then
                              vd_mstr.vd_type else """",
                        input """",
                        input no,
                        output dftPPVAcct,
                        output dftPPVSub,
                        output dftPPVCC)"}
 
            /* AP RATE VARIANCE ACCOUNT DETAIL */
            {us/bbi/gprun.i ""glactdft.p""
                      "(input ""PO_APVR_ACCT"",
                        input pItemProdLine,
                        input pSite,
                        input if available vd_mstr then
                              vd_mstr.vd_type else """",
                        input """",
                        input no,
                        output dftAPVRAcct,
                        output dftAPVRSub,
                        output dftAPVRCC)"}
 
            /* PUR ACCT ACCOUNT DETAIL */
            {us/bbi/gprun.i ""glactdft.p""
                      "(input ""PO_PUR_ACCT"",
                        input pItemProdLine,
                        input pSite,
                        input if available vd_mstr then
                              vd_mstr.vd_type else """",
                        input """",
                        input no,
                        output dftPURAcct,
                        output dftPURSub,
                        output dftPURCC)"}
 
            /* PUR OVH ACCOUNT DETAIL */
            {us/bbi/gprun.i ""glactdft.p""
                      "(input ""PO_OVH_ACCT"",
                        input pItemProdLine,
                        input pSite,
                        input if available vd_mstr then
                              vd_mstr.vd_type else """",
                        input """",
                        input no,
                        output dftOVHAcct,
                        output dftOVHSub,
                        output dftOVHCC)"}
 
            /* PUR RCPT ACCOUNT DETAIL */
            {us/bbi/gprun.i ""glactdft.p""
                      "(input ""PO_RCPT_ACCT"",
                        input pItemProdLine,
                        input pSite,
                        input if available vd_mstr then
                              vd_mstr.vd_type else """",
                        input """",
                        input no,
                        output dftRcptAcct,
                        output dftRcptSub,
                        output dftRcptCC)"}
 
            /* INVENTORY ACCOUNT DETAIL */
            {us/px/pxrun.i &PROC  = 'getInventoryAccount'
                     &PARAM = "(input 'INV_ACCT',
                                input pItemNumber,
                                input pSite,
                                input tr_hist.tr_loc,
                                output dftInvAcct,
                                output dftInvSub,
                                output dftInvCC)"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
            if return-value <> {&SUCCESS-RESULT}
            then return error {&APP-ERROR-RESULT}.
 
            /* BELOW CODE USE THE INVOICE COST,IF INVOICE EXISTS
               ELSE USE THE PO RECEIPT COST FOR RECEIPT AMOUNT
               CALCULATION       */
            assign
               lInvoiceExist     = no
               llogInvoiceExist  = no
               lInvoiceAmt       = 0
               lUnitCost         = 0
               lLogisticsVouchAmount  = 0
               lLogisticsAccruAmount  = 0
               lLogisticsTotalAmount  = 0
               lLAMtlCatAccrucsttot   = 0
               lLAMtlCatVouchcsttot   = 0
               lLALbrCatAccrucsttot   = 0
               lLALbrCatVouchcsttot   = 0
               lLABdnCatAccrucsttot   = 0
               lLABdnCatVouchcsttot   = 0
               lLAOvhCatAccrucsttot   = 0
               lLAOvhCatVouchcsttot   = 0
               lLASubCatAccrucsttot   = 0
               lLASubCatVouchcsttot   = 0
               logisticsChargeAmount = 0
               nonlogchgmatcatamount = 0
               line_tax               = 0
               NRline_tax            = 0
               l_lcVouchMatchPrice    = 0
               l_lcAccruMatchPrice    = 0
               l_mtl_std              = 0
               l_ErrorNumber          = 0.
            for first prh_hist no-lock
               where prh_hist.prh_domain = global_domain
                 and prh_hist.prh_receiver = tr_hist.tr_lot
                 and prh_hist.prh_line     = tr_hist.tr_line:
            end.    
 
            /* Get Invoice cost and Logistic Accounting cost */
            for each pvo_mstr 
               where pvo_mstr.pvo_domain            = global_domain
                 and pvo_mstr.pvo_order             = tr_hist.tr_nbr
                 and pvo_mstr.pvo_internal_ref      = tr_hist.tr_lot
                 and pvo_mstr.pvo_order_type        = {&TYPE_PO}
                 and pvo_mstr.pvo_internal_ref_type = {&TYPE_POReceiver}
            no-lock: 
 
               vcProxyCompanyCode = pSiteEntity.
 
               for each pvod_det 
                  where pvod_det.pvod_domain     = global_domain
                    and pvod_det.pvod_id         = pvo_mstr.pvo_id
                    and pvod_det.pvod_order      = tr_hist.tr_nbr
                    and pvod_det.pvod_order_line = tr_hist.tr_line
               no-lock:
 
                  if pvo_mstr.pvo_lc_charge = ""
                  then do:
                     assign
                        iipvoid     = pvod_det.pvod_id
                        iipvolineid = pvod_det.pvod_id_line
                        lProject    = pvod_det.pvod_project.
 
                     /* API CALLS */
                     {proxy/bapmatching/apigetapmatchinglnbypvorun.i}
 
                     if oiReturnStatus < 0
                     then do:
                        /*Start qflib.p - QAD Financials
                          Library running persistently*/
                        run mfairunh.p 
                           (input 'qflib.p',
                            input '?', output hQADFinancialsLib)
                        no-error.
                        run processErrors in hQADFinancialsLib
                           (input table tFcMessages by-reference, input 3).
                        return error {&APP-ERROR-RESULT}.
                     end.
 
 
                     for each tAPMatchingLnByPvo no-lock
                        where ttAPMatchingDate >= pGlcStart
                          and ttAPMatchingDate <= pGlcEnd:
 
                        lAPMatchPrice = 0.
 
                        if tcAPMatchingStatus = "CANCEL"
                        then
                           next.
 
                        if available prh_hist
                        and prh_hist.prh_curr <> pBaseCurrency
                        then do:
                            /* Get Base Currency Price to compare */
                           {us/px/pxrun.i &PROC='mc-curr-conv'
                              &PROGRAM='mcpl.p'
                              &HANDLE = ph_mcpl
                              &PARAM="(input prh_hist.prh_curr,
                                       input pBaseCurrency,
                                       input prh_hist.prh_ex_rate,
                                       input prh_hist.prh_ex_rate2,
                                       input (tdAPMatchingLnMatchUnitPrice - tdAPMatchingLnTaxARRecTaxTC),
                                       input false,
                                       output lAPMatchPrice,
                                       output l_ErrorNumber)" }
                           if l_ErrorNumber <> 0
                           then do:
                              {us/bbi/pxmsg.i &MSGNUM=l_ErrorNumber &ERRORLEVEL=2}
                              return error {&APP-ERROR-RESULT}.
                           end. /* IF l_ErrorNumber <> 0 */
                        end. 
                        else lAPMatchPrice = tdAPMatchingLnMatchUnitPrice.
 
                        assign
                              lUnitCost = lUnitCost 
                                        + ( lAPMatchPrice * 
                                           (1 / if available prh_hist
                                                then prh_hist.prh_um_conv
                                                else 1)  )
                              lInvoiceExist = yes.
                        leave.
 
                     end.   /* for each tAPMatchingLnByPvo */
                  end.     /* pvo_lc_charge = "" */
                  else do: /* Get Logistic accounting cost for non matched 
                            * from Fin*/
                     for first lc_mstr no-lock
                        where lc_mstr.lc_domain  = global_domain
                          and lc_mstr.lc_charge  = pvo_mstr.pvo_lc_charge:
                        for first vd_mstr no-lock
                           where vd_mstr.vd_domain = global_domain
                             and vd_mstr.vd_addr   = tr_hist.tr_addr:
                        end.  /* first vd_mstr */
                         /* Get the category information for the element */
                        for first sc_mstr no-lock
                           where sc_mstr.sc_domain = global_domain
                             and sc_mstr.sc_sim    = pBaseCostSet
                             and sc_mstr.sc_element = lc_mstr.lc_element:
                        end.
                        if available sc_mstr 
                        then do:
                           if sc_mstr.sc_category = {&MATERIAL-CATEGORY} then
                           assign
                              lLAMtlCatVouchCsttot = lLAMtlCatVouchCsttot
                                                   + pvod_det.pvod_vouchered_amt
                              lLAMtlCatAccruCsttot = lLAMtlCatAccruCsttot
                                                   + pvod_det.pvod_accrued_amt.
                           if sc_mstr.sc_category = {&LABOR-CATEGORY} then
                           assign
                              lLALbrCatVouchCsttot = lLALbrCatVouchCsttot 
                                                   + pvod_det.pvod_vouchered_amt
                              lLALbrCatAccruCsttot = lLALbrCatAccruCsttot 
                                                   + pvod_det.pvod_accrued_amt.
                           if sc_mstr.sc_category = {&BURDEN-CATEGORY} then
                           assign
                              lLABdnCatVouchCsttot = lLABdnCatVouchCsttot 
                                                   + pvod_det.pvod_vouchered_amt
                              lLABdnCatAccruCsttot = lLABdnCatAccruCsttot 
                                                   + pvod_det.pvod_accrued_amt.
                           if sc_mstr.sc_category = {&OVERHEAD-CATEGORY} then
                           assign
                              lLAOvhCatVouchCsttot = lLAOvhCatVouchCsttot 
                                                   + pvod_det.pvod_vouchered_amt
                              lLAOvhCatAccruCsttot = lLAOvhCatAccruCsttot 
                                                   + pvod_det.pvod_accrued_amt.
                           if sc_mstr.sc_category = {&SUBCONTRACT-CATEGORY} then
                           assign
                              lLASubCatVouchCsttot = lLASubCatVouchCsttot 
                                                   + pvod_det.pvod_vouchered_amt
                              lLASubCatAccruCsttot = lLASubCatAccruCsttot 
                                                   + pvod_det.pvod_accrued_amt.
                        end. /* if avail sc_mstr */
 
                        if pvo_mstr.pvo_curr <> pBaseCurrency
                        then do:
                           /* GET BASE CURRENCY PRICE TO COMPARE */
                           {us/px/pxrun.i 
                              &PROC    = 'getCurrencyConversionAmtRoundingOptional'
                              &PARAM   = "(input pvo_mstr.pvo_curr ,
                                           input pBaseCurrency  ,
                                           input pStatiSFallBack ,
                                           input tr_hist.tr_effdate,
                                           input pvod_det.pvod_vouchered_amt,
                                           input False /* Rounding */,
                                           output l_lcVouchMatchPrice)"
                              &NOAPPERROR=true
                              &CATCHERROR=true}
                           if return-value <> {&SUCCESS-RESULT} 
                           then 
                              return error {&APP-ERROR-RESULT}.
 
                           /* GET BASE CURRENCY PRICE TO COMPARE */
                           {us/px/pxrun.i 
                              &PROC    = 'getCurrencyConversionAmtRoundingOptional'
                              &PARAM   = "(input pvo_mstr.pvo_curr ,
                                           input pBaseCurrency  ,
                                           input pStatiSFallBack ,
                                           input tr_hist.tr_effdate,
                                           input pvod_det.pvod_accrued_amt,
                                           input False /* Rounding */,
                                           output l_lcAccruMatchPrice)"
                              &NOAPPERROR=true
                              &CATCHERROR=true}
                           if return-value <> {&SUCCESS-RESULT} 
                           then 
                              return error {&APP-ERROR-RESULT}.
                        end. /* IF pvo_mstr.pvo_curr <> pBaseCurrency */
                        else
                           assign 
                              l_lcVouchMatchPrice = pvod_det.pvod_vouchered_amt
                              l_lcAccruMatchPrice = pvod_det.pvod_accrued_amt.
 
                        /* If Use Supplier Invoice Cost Only is yes, always use vouchered  *
                         * logistical charge; else if invoiced logistical charge           *
                         *(pvod_vouchered_amt) not zero, use invoiced logistical charge    *
                         * else use accrued logistical charges (pvod_det.pvod_accrued_amt) */                           
                        if pUseInvoiceCostOnly = no 
                        then do:	
                        /*  If vouchered logistical charge is not zero,use invoiced *
               			     *  logistical charge else use  accrued logistcal charges  */
                            if l_lcVouchMatchPrice <> 0 then
                               assign logisticsChargeAmount = l_lcVouchMatchPrice.  
                            else
                               assign logisticsChargeAmount = l_lcAccruMatchPrice.
 
                        end. /* If pUseInvoiceCostOnly = no */
                        else /* If pUseInvoiceCostOnly = yes */
                        do:		
                            /* If invoice found, use vouchered logistical charge *
                             * else set to zero                                  */
                            if lInvoiceExist = yes then
                               logisticsChargeAmount = l_lcVouchMatchPrice.
                            else
                               logisticsChargeAmount = 0.
 
                        end. /* If pUseInvoiceCostOnly = no */
                        /* Get the variance account for Logistic charge */
                        /* RETRIEVE PP VARIANCE ACCOUNT */
			                  
			                  {us/bbi/gprun.i ""laglacct.p""
                           "(input ""{&TYPE_PO}"",
                             input ""POPRICEVAR"",
                             input lc_mstr.lc_charge,
                             input """",
                             input pSite,
                             input if available vd_mstr then
                                   vd_mstr.vd_type else """",
                             input """",
                             output dftLAPPVAcct,
                             output dftLAPPVSub,
                             output dftLAPPVCC)"}
                         if return-value <> {&SUCCESS-RESULT}
                         then return error {&APP-ERROR-RESULT}.                        
                        /* RETRIEVE VARIANCE ACCOUNT */
                        {us/bbi/gprun.i ""laglacct.p""
                        "(input ""{&TYPE_PO}"",
                          input ""VARIANCE"",
                          input lc_mstr.lc_charge,
                          input """",
                          input pSite,
                          input if available vd_mstr 
                                then
                                   vd_mstr.vd_type 
                                else 
                                   """",
                          input """",
                          output l_dftLAVARAcct,
                          output l_dftLAVARSub,
                          output l_dftLAVARCC)"}
                         if return-value <> {&SUCCESS-RESULT}
                         then 
                            return error {&APP-ERROR-RESULT}.
                        /* Apart from Base 5 category elements 
                         * Material, Labor, Burden, Overhead and 
                         * Sub contract                               */
                        /* For this we have to find the standard cost 
                         *  for other elements for LC                 */
                        /* If pccost method is FIFO and Qty is negative *
                         * Then make it to act like issue               */
                        if ( pPCCostMethod = "WAVG" or
                             (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0)) 
                        then do:
                           if can-find (first spt_det no-lock
                              where spt_det.spt_domain     = global_domain
                                and spt_det.spt_site       = pin_gl_cost_site
                                and spt_det.spt_sim        = psimcostset
                                and spt_det.spt_part       = pItemNumber
                                and spt_det.spt_element    = lc_mstr.lc_element)
                           then for each spt_det no-lock
                           where spt_det.spt_domain     = global_domain
                             and spt_det.spt_site       = pin_gl_cost_site
                                and spt_det.spt_sim        = psimcostset
                                and spt_det.spt_part       = pItemNumber
                                and spt_det.spt_element    = lc_mstr.lc_element
                                and (logisticsChargeAmount - (tr_hist.tr_qty_loc * 
                                    (spt_det.spt_cst_tl    + spt_det.spt_cst_ll))) <> 0:    
                              {us/px/pxrun.i 
                              &PROC  = 'createTransactionDetail'
                              &PARAM = "(input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPAcct
                                               else dftCOPAcct)
                                         else dftInvAcct,
                                         input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPSub 
                                               else dftCOPSub)
                                         else dftInvSub,
                                         input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPCC 
                                               else dftCOPCC)
                                         else dftInvCC,
                                         input dftLAPPVAcct,
                                         input dftLAPPVSub,
                                         input dftLAPPVCC,
                                         input lProject,
                                         input ( logisticsChargeAmount
                                                - ( tr_hist.tr_qty_loc 
                                         * ( spt_det.spt_cst_tl + spt_det.spt_cst_ll ))) 
                                         /* BASE CURRENCY AMOUNT */ ,
                                         input 0  
                                         /* STATUTORY CURRENCY AMOUNT */,
                                         input recid(tr_hist) ,
                                         input pEndDate,
                                         input pBaseCostset,
                                         input pStatCostset,
                                         input pBaseCurrency,
                                         input pStatCurrency,
                                         input pStatIsFallBack,
                                         input pSiteEntity,
                                         input ppc_calc_daybook,
                                         input ppc_daybook_desc,
                                         input pmr_daybook,
                                         input pmr_daybook_desc,
                                         input pglmir_yn,
                                         input dataset tapipostingdataiswithsaf
                                                       by-reference,
                                         input-output dataset tapipostingsaf
                                                              by-reference,
                                         input-output table ttSafStrEntGLCCPrj
                                                              by-reference )"
                                 &NOAPPERROR=true
                                 &CATCHERROR=true}
                              if return-value <> {&SUCCESS-RESULT}
                              then return error {&APP-ERROR-RESULT}.
                              end.
                           else do:      
                              if (pin_gl_set <> "")  then
                              for each spt_det no-lock
                           where spt_det.spt_domain     = global_domain
                             and spt_det.spt_site       = pin_gl_cost_site
                                and spt_det.spt_sim        = pin_gl_Set
                             and spt_det.spt_part       = pItemNumber
                             and spt_det.spt_element    = lc_mstr.lc_element
                             and (logisticsChargeAmount - (tr_hist.tr_qty_loc * 
                                 (spt_det.spt_cst_tl    + spt_det.spt_cst_ll))) <> 0:    
 
                              /* IF SUPPLIER INVOICE (l_lcVouchMatchPrice = 0) IS NOT CREATED */
                              /* FOR LA CHARGES THEN WE WILL POST ANY VARIANCE AT THE */
                              /* TIME OF RECEIPT TO PPV ACCOUNT */
                           {us/px/pxrun.i 
                              &PROC  = 'createTransactionDetail'
                              &PARAM = "(input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPAcct
                                               else dftCOPAcct)
                                         else dftInvAcct,
                                         input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPSub 
                                               else dftCOPSub)
                                         else dftInvSub,
                                         input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPCC 
                                               else dftCOPCC)
                                         else dftInvCC,
                                         input dftLAPPVAcct,
                                         input dftLAPPVSub,
                                         input dftLAPPVCC,
                                         input lProject,
                                            input (if l_lcVouchMatchPrice <> 0 then 
                                                      (l_lcAccruMatchPrice - (tr_hist.tr_qty_loc 
                                                                           * (spt_det.spt_cst_tl 
                                                                           + spt_det.spt_cst_ll)))
                                                   else 
                                                      (logisticsChargeAmount - (tr_hist.tr_qty_loc 
                                                                             * (spt_det.spt_cst_tl 
                                                                             + spt_det.spt_cst_ll))))
                                            /* BASE CURRENCY AMOUNT */ ,
                                            input 0  
                                            /* STATUTORY CURRENCY AMOUNT */,
                                            input recid(tr_hist) ,
                                            input pEndDate,
                                            input pBaseCostset,
                                            input pStatCostset,
                                            input pBaseCurrency,
                                            input pStatCurrency,
                                            input pStatIsFallBack,
                                            input pSiteEntity,
                                            input ppc_calc_daybook,
                                            input ppc_daybook_desc,
                                            input pmr_daybook,
                                            input pmr_daybook_desc,
                                            input pglmir_yn,
                                            input dataset tapipostingdataiswithsaf
                                                          by-reference,
                                            input-output dataset tapipostingsaf
                                                                 by-reference,
                                            input-output table ttSafStrEntGLCCPrj
                                                                 by-reference )"
                                 &NOAPPERROR=true
                                 &CATCHERROR=true}
                                 if return-value <> {&SUCCESS-RESULT}
                                 then return error {&APP-ERROR-RESULT}.
                              end.
                              else if (picc_gl_set <> "")  
                              then for each spt_det no-lock
                              where spt_det.spt_domain     = global_domain
                                and spt_det.spt_site       = pin_gl_cost_site
                                and spt_det.spt_sim        = picc_gl_set
                                and spt_det.spt_part       = pItemNumber
                                and spt_det.spt_element    = lc_mstr.lc_element
                                and (logisticsChargeAmount - (tr_hist.tr_qty_loc * 
                                    (spt_det.spt_cst_tl    + spt_det.spt_cst_ll))) <> 0:    
                              /* IF SUPPLIER INVOICE (l_lcVouchMatchPrice = 0) IS NOT CREATED */
                              /* FOR LA CHARGES THEN WE WILL POST ANY VARIANCE AT THE */
                              /* TIME OF RECEIPT TO PPV ACCOUNT */
                              {us/px/pxrun.i 
                                 &PROC  = 'createTransactionDetail'
                                 &PARAM = "(input if tr_ship_type = 'S' 
                                            then (if luseWIPAcct 
                                                  then dftWIPAcct
                                                  else dftCOPAcct)
                                            else dftInvAcct,
                                            input if tr_ship_type = 'S' 
                                            then (if luseWIPAcct 
                                                  then dftWIPSub 
                                                  else dftCOPSub)
                                            else dftInvSub,
                                            input if tr_ship_type = 'S' 
                                            then (if luseWIPAcct 
                                                  then dftWIPCC 
                                                  else dftCOPCC)
                                            else dftInvCC,
                                            input dftLAPPVAcct,
                                            input dftLAPPVSub,
                                            input dftLAPPVCC,
                                            input lProject,
                                            input (if l_lcVouchMatchPrice <> 0 then 
                                                      (l_lcAccruMatchPrice - (tr_hist.tr_qty_loc 
                                         * ( spt_det.spt_cst_tl 
                                         + spt_det.spt_cst_ll ))) 
                                                   else 
                                                      (logisticsChargeAmount - (tr_hist.tr_qty_loc 
                                                                             * (spt_det.spt_cst_tl 
                                                                             + spt_det.spt_cst_ll)))) 
                                         /* BASE CURRENCY AMOUNT */ ,
                                         input 0  
                                         /* STATUTORY CURRENCY AMOUNT */,
                                         input recid(tr_hist) ,
                                         input pEndDate,
                                         input pBaseCostset,
                                         input pStatCostset,
                                         input pBaseCurrency,
                                         input pStatCurrency,
                                         input pStatIsFallBack,
                                         input pSiteEntity,
                                         input ppc_calc_daybook,
                                         input ppc_daybook_desc,
                                         input pmr_daybook,
                                         input pmr_daybook_desc,
                                         input pglmir_yn,                                         
                                         input dataset tapipostingdataiswithsaf
                                                       by-reference,
                                         input-output dataset tapipostingsaf
                                                              by-reference,
                                         input-output table ttSafStrEntGLCCPrj
                                                              by-reference )"
                              &NOAPPERROR=true
                              &CATCHERROR=true}
                              if return-value <> {&SUCCESS-RESULT}
                              then return error {&APP-ERROR-RESULT}.
                           end. 
			   end. /* if not avail sim cost set */ 
                        end. /* if pPCCostMethod = "WAVG" */
 
                        /* IF SUPPLIER INVOICE IS CREATED FOR LA CHARGES */
                        /* THEN WE WILL POST VARIANCE TO LA VARIANCE ACCOUNT */
                        /* LA CHARGES WILL NOT CREATE AN AP RATE VARIANCE */
                        if l_lcVouchMatchPrice <> 0 and
                          (l_lcVouchMatchPrice 
                           - l_lcAccruMatchPrice) <> 0 
                        then do:
                           {us/px/pxrun.i 
                              &PROC  = 'createTransactionDetail'
                              &PARAM = "(input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPAcct
                                               else dftCOPAcct)
                                         else dftInvAcct,
                                         input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPSub 
                                               else dftCOPSub)
                                         else dftInvSub,
                                         input if tr_ship_type = 'S' 
                                         then (if luseWIPAcct 
                                               then dftWIPCC 
                                               else dftCOPCC)
                                         else dftInvCC,
                                         input l_dftLAVARAcct,
                                         input l_dftLAVARSub,
                                         input l_dftLAVARCC,
                                         input lProject,
                                         input (l_lcVouchMatchPrice 
                                                - l_lcAccruMatchPrice) 
                                         /* BASE CURRENCY AMOUNT */ ,
                                         input 0  
                                         /* STATUTORY CURRENCY AMOUNT */,
                                         input recid(tr_hist) ,
                                         input pEndDate,
                                         input pBaseCostset,
                                         input pStatCostset,
                                         input pBaseCurrency,
                                         input pStatCurrency,
                                         input pStatIsFallBack,
                                         input pSiteEntity,
                                         input ppc_calc_daybook,
                                         input ppc_daybook_desc,
                                         input pmr_daybook,
                                         input pmr_daybook_desc,
                                         input pglmir_yn,                                         
                                         input dataset tapipostingdataiswithsaf
                                                       by-reference,
                                         input-output dataset tapipostingsaf
                                                              by-reference,
                                         input-output table ttSafStrEntGLCCPrj
                                                              by-reference )"
                              &NOAPPERROR=true
                              &CATCHERROR=true}
                           if return-value <> {&SUCCESS-RESULT}
                           then return error {&APP-ERROR-RESULT}.
                        end.
 
                        /* SUM UP THE LOGISTICS CHARGE AMOUNT
                           AGAINST THE COST ELEMENT THAT HAS BEEN MAPPED
                           TO THE LOGISTICS CHARGE CODE */
 
                        /* save the tt-CostElementInfor for this item,costset */	   
                        if logisticsChargeAmount <> 0 and
                           ( pPCCostMethod = "WAVG" or
                             (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0))
                        then do:
                           {us/px/pxrun.i 
                             &PROC    = 'updateCostElementInfo'
                             &PARAM   = "(input pBaseCostSet,
                                        input pStatCostSet,
                                        input pBaseCurrency,
                                 				input pStatCurrency,
				                                input pStatIsFallBack,
                                        input tr_hist.tr_effdate,
                                        input pSite,
                                        input pItemNumber,
                                        input lc_mstr.lc_element,
                                        input logisticsChargeAmount, /*THIS LEVEL*/
                                        input 0 /*LOWER LEVEL*/ )"
                           &NOAPPERROR=true
                           &CATCHERROR=true}
 
                           if return-value <> {&SUCCESS-RESULT}
                           then return error {&APP-ERROR-RESULT}.
 
						            end.  /* if logisticsChargeAmount <> 0 */
 
                        /* Since with current developement we are only 
                           allowing element on material, overhead category 
                           we only total up for material/Overhead category  */
                        if available sc_mstr 
                        then do:
                           assign
                           lLogisticsVouchAmount = lLogisticsVouchAmount 
                                                 + l_lcVouchMatchPrice
                           lLogisticsAccruAmount = lLogisticsAccruAmount 
                                                 + l_lcAccruMatchPrice
                           lLogisticsTotalAmount = lLogisticsTotalAmount +
                                                   logisticsChargeAmount.
                        end. /* avail sc_mstr */                           
 
                     end.   /* first lc_mstr */
                  end.   /* else do             */
               end.     /* each pvod_det       */
            end.       /* each pvo_mstr       */
 
            /* THIS BLOCK OF CODE IF FOR REVERSING LA CHARGES */
            /* WHEN ITEM ELEMENT IS NON ZERO BUT PO LA AMT IS ZERO */
            /* SINCE THERE IS NO PVO_MSTR RECORD CREATED FOR SUCH CASES */
            /* WE WILL USE THIS LOGIC FOR REVERSING THE LA CHARGES */
            /* LOOP ON CHARGES DETAIL*/
            for each lacd_det
                where lacd_det.lacd_domain            = global_domain
                and   lacd_det.lacd_internal_ref      = tr_hist.tr_nbr
                and   lacd_det.lacd_shipfrom          = tr_hist.tr_addr
                and   lacd_det.lacd_internal_ref_type = {&TYPE_PO}
            no-lock:
               for first lc_mstr
                  where lc_domain = global_domain 
                  and   lc_charge = lacd_lc_charge
               no-lock: 
               end. /* FOR FIRST lc_mstr */
 
               if not available lc_mstr 
               then 
                  next.
 
               if not can-find(first pvo_mstr
                                  where pvo_mstr.pvo_domain            = global_domain
                                  and   pvo_mstr.pvo_order             = tr_hist.tr_nbr
                                  and   pvo_mstr.pvo_internal_ref      = tr_hist.tr_lot
                                  and   pvo_mstr.pvo_order_type        = {&TYPE_PO}
                                  and   pvo_mstr.pvo_internal_ref_type = {&TYPE_POReceiver}
                                  and   pvo_mstr.pvo_lc_charge         = lacd_lc_charge) 
               then do:
                  /* RETRIEVE VARIANCE ACCOUNT */
                  {us/bbi/gprun.i ""laglacct.p""
                                    "(input ""{&TYPE_PO}"",
                                      input ""POPRICEVAR"",
                                      input lc_mstr.lc_charge,
                                      input """",
                                      input pSite,
                                      input if available vd_mstr 
                                            then
                                               vd_mstr.vd_type 
                                            else 
                                               """",
                                      input """",
                                      output dftLAPPVAcct,
                                      output dftLAPPVSub,
                                      output dftLAPPVCC)"}
                  if return-value <> {&SUCCESS-RESULT}
                  then 
                     return error {&APP-ERROR-RESULT}.                        
 
                  if ( pPCCostMethod = "WAVG" or
                       (pPCCostMethod <> "WAVG" 
                          and tr_hist.tr_qty_loc > 0)) 
                  then do:
                     if (pin_gl_set <> "")  
                     then
                        for each spt_det no-lock
                           where spt_det.spt_domain     = global_domain
                           and   spt_det.spt_site       = pin_gl_cost_site
                           and   spt_det.spt_sim        = pin_gl_Set
                           and   spt_det.spt_part       = pItemNumber
                           and   spt_det.spt_element    = lc_mstr.lc_element
                           and   (spt_det.spt_cst_tl    + spt_det.spt_cst_ll) <> 0:
                           {us/px/pxrun.i 
                              &PROC  = 'createTransactionDetail'
                              &PARAM = "(input if tr_ship_type = 'S' 
                                         then 
                                            (if luseWIPAcct 
                                             then 
                                                dftWIPAcct
                                             else 
                                                dftCOPAcct)
                                         else 
                                            dftInvAcct,
                                         input if tr_ship_type = 'S' 
                                         then 
                                            (if luseWIPAcct 
                                             then 
                                                dftWIPSub 
                                             else 
                                                dftCOPSub)
                                         else 
                                            dftInvSub,
                                         input if tr_ship_type = 'S' 
                                         then 
                                            (if luseWIPAcct 
                                             then 
                                                dftWIPCC 
                                             else 
                                                dftCOPCC)
                                         else 
                                            dftInvCC,
                                         input dftLAPPVAcct,
                                         input dftLAPPVSub,
                                         input dftLAPPVCC,
                                         input lProject,
                                         input ( 0
                                                - ( tr_hist.tr_qty_loc 
                                         * ( spt_det.spt_cst_tl + spt_det.spt_cst_ll ))) 
                                         /* BASE CURRENCY AMOUNT */ ,
                                         input 0  
                                         /* STATUTORY CURRENCY AMOUNT */,
                                         input recid(tr_hist) ,
                                         input pEndDate,
                                         input pBaseCostset,
                                         input pStatCostset,
                                         input pBaseCurrency,
                                         input pStatCurrency,
                                         input pStatIsFallBack,
                                         input pSiteEntity,
                                         input ppc_calc_daybook,
                                         input ppc_daybook_desc,
                                         input pmr_daybook,
                                         input pmr_daybook_desc,
                                         input pglmir_yn,
                                         input dataset tapipostingdataiswithsaf
                                                       by-reference,
                                         input-output dataset tapipostingsaf
                                                              by-reference,
                                         input-output table ttSafStrEntGLCCPrj
                                                              by-reference )"
                              &NOAPPERROR=true
                              &CATCHERROR=true}
                              if return-value <> {&SUCCESS-RESULT}
                              then return error {&APP-ERROR-RESULT}.
                        end. /* FOR EACH spt_det */
                     else if (picc_gl_set <> "")  
                     then 
                        for each spt_det no-lock
                           where spt_det.spt_domain     = global_domain
                             and spt_det.spt_site       = pin_gl_cost_site
                             and spt_det.spt_sim        = picc_gl_set
                             and spt_det.spt_part       = pItemNumber
                             and spt_det.spt_element    = lc_mstr.lc_element
                             and (spt_det.spt_cst_tl    + spt_det.spt_cst_ll) <> 0:    
                           {us/px/pxrun.i 
                              &PROC  = 'createTransactionDetail'
                              &PARAM = "(input if tr_ship_type = 'S' 
                                         then 
                                            (if luseWIPAcct 
                                             then 
                                                dftWIPAcct
                                             else 
                                                dftCOPAcct)
                                         else 
                                            dftInvAcct,
                                         input if tr_ship_type = 'S' 
                                         then 
                                            (if luseWIPAcct 
                                             then 
                                                dftWIPSub 
                                             else 
                                                dftCOPSub)
                                         else 
                                            dftInvSub,
                                         input if tr_ship_type = 'S' 
                                         then 
                                            (if luseWIPAcct 
                                             then 
                                                dftWIPCC 
                                             else 
                                                dftCOPCC)
                                         else 
                                            dftInvCC,
                                         input dftLAPPVAcct,
                                         input dftLAPPVSub,
                                         input dftLAPPVCC,
                                         input lProject,
                                         input ( 0
                                                - ( tr_hist.tr_qty_loc 
                                         * ( spt_det.spt_cst_tl 
                                         + spt_det.spt_cst_ll ))) 
                                         /* BASE CURRENCY AMOUNT */ ,
                                         input 0  
                                         /* STATUTORY CURRENCY AMOUNT */,
                                         input recid(tr_hist) ,
                                         input pEndDate,
                                         input pBaseCostset,
                                         input pStatCostset,
                                         input pBaseCurrency,
                                         input pStatCurrency,
                                         input pStatIsFallBack,
                                         input pSiteEntity,
                                         input ppc_calc_daybook,
                                         input ppc_daybook_desc,
                                         input pmr_daybook,
                                         input pmr_daybook_desc,
                                         input pglmir_yn,                                         
                                         input dataset tapipostingdataiswithsaf
                                                       by-reference,
                                         input-output dataset tapipostingsaf
                                                              by-reference,
                                         input-output table ttSafStrEntGLCCPrj
                                                              by-reference )"
                              &NOAPPERROR=true
                              &CATCHERROR=true}
                           if return-value <> {&SUCCESS-RESULT}
                           then 
                              return error {&APP-ERROR-RESULT}.
                        end. /* FOR EACH spt_det */
                  end. /* IF pPCCostMethod = "WAVG" */
 
                  if ((pPCCostMethod <> "WAVG" 
                  and tr_hist.tr_qty_loc < 0)) 
                  then do:
                     for each tt-neg-pocostinfo no-lock:
                        for each spt_det no-lock
                           where spt_det.spt_domain     = global_domain
                             and spt_det.spt_site       = psite
                             and spt_det.spt_sim        = tt-neg-basecostset
                             and spt_det.spt_part       = pItemNumber
                             and spt_det.spt_element    = lc_mstr.lc_element
                             and (spt_det.spt_cst_tl    + spt_det.spt_cst_ll) <> 0:
                           {us/px/pxrun.i 
                           &PROC  = 'createTransactionDetail'
                           &PARAM = "(input if tr_ship_type = 'S' 
                                      then 
                                         (if luseWIPAcct 
                                          then 
                                             dftWIPAcct
                                          else 
                                             dftCOPAcct)
                                      else 
                                         dftInvAcct,
                                      input if tr_ship_type = 'S' 
                                      then 
                                         (if luseWIPAcct 
                                          then 
                                             dftWIPSub 
                                          else 
                                             dftCOPSub)
                                      else 
                                         dftInvSub,
                                      input if tr_ship_type = 'S' 
                                      then 
                                         (if luseWIPAcct 
                                          then 
                                             dftWIPCC 
                                          else 
                                             dftCOPCC)
                                      else 
                                         dftInvCC,
                                      input dftLAPPVAcct,
                                      input dftLAPPVSub,
                                      input dftLAPPVCC,
                                      input lProject,
                                      input (0
                                             - ( tt-neg-trpolocqty 
                                      * ( spt_det.spt_cst_tl + spt_det.spt_cst_ll ))) 
                                      /* BASE CURRENCY AMOUNT */ ,
                                      input 0  
                                      /* STATUTORY CURRENCY AMOUNT */,
                                      input recid(tr_hist) ,
                                      input pEndDate,
                                      input pBaseCostset,
                                      input pStatCostset,
                                      input pBaseCurrency,
                                      input pStatCurrency,
                                      input pStatIsFallBack,
                                      input pSiteEntity,
                                      input ppc_calc_daybook,
                                      input ppc_daybook_desc,
                                      input pmr_daybook,
                                      input pmr_daybook_desc,
                                      input pglmir_yn,
                                      input dataset tapipostingdataiswithsaf
                                                    by-reference,
                                      input-output dataset tapipostingsaf
                                                           by-reference,
                                      input-output table ttSafStrEntGLCCPrj
                                                           by-reference )"
                           &NOAPPERROR=true
                           &CATCHERROR=true}
                           if return-value <> {&SUCCESS-RESULT}
                           then 
                              return error {&APP-ERROR-RESULT}.
                        end. /* FOR EACH spt_det */
                     end. /* FOR EACH tt-neg-pocostinfo */
                  end. /* IF ((pPCCostMethod <> "WAVG" AND tr_hist.tr_qty_loc < 0)) */  
               end. /* IF NOT CAN-FIND(FIRST pvo_mstr) */
            end. /* FOR EACH lacd_det */
            /* Get Legal Document Logistic Accounting cost */
            if tr_hist.tr_type = "RCT-LA"
            then do:
               for first lgdd_det 
                  where lgdd_det.oid_lgd_mstr = tr_hist.oid_lgd_mstr
                    and lgdd_det.lgdd_line    = tr_hist.tr_line
               no-lock:
                  for first lgd_mstr no-lock
                     where lgd_mstr.oid_lgd_mstr = tr_hist.oid_lgd_mstr:
                  end.
                  if not avail lgd_mstr
                  then next.
                  assign lacd_internal_key_ref = lgdd_det.lgdd_nbr + dcol +
                             lgd_mstr.lgd_shipfrom + dcol +
                             string(year(lgd_mstr.lgd_effdate),"9999") +
                             string(month(lgd_mstr.lgd_effdate),"9999") +
                             string(day(lgd_mstr.lgd_effdate),"99") + dcol +
                             lgdd_det.lgdd_order + dcol +
                             string(lgdd_det.lgdd_line,">>9") + dcol +
                             string(lgdd_det.lgdd_order_line,">>9").
                  for each pvo_mstr 
                     where pvo_mstr.pvo_domain            = global_domain
                       and pvo_mstr.pvo_order             = tr_hist.tr_nbr
                       and pvo_mstr.pvo_internal_ref      = lacd_internal_key_ref
                       and pvo_mstr.pvo_order_type        = {&TYPE_PO}
                       and pvo_mstr.pvo_internal_ref_type = {&TYPE_LGDDNUMBER}
                  no-lock: 
                     vcProxyCompanyCode = pSiteEntity.
                     for each pvod_det 
                        where pvod_det.pvod_domain     = global_domain
                          and pvod_det.pvod_id         = pvo_mstr.pvo_id
                          and pvod_det.pvod_order      = tr_hist.tr_nbr
                          and pvod_det.pvod_order_line = tr_hist.tr_line
                     no-lock:
                        if pvo_mstr.pvo_lc_charge = lgdd_det.lgdd_order
                        then do: /* Get Logistic accounting cost for non matched 
                                  * from Fin*/
                           for first lc_mstr no-lock
                              where lc_mstr.lc_domain  = global_domain
                                and lc_mstr.lc_charge  = pvo_mstr.pvo_lc_charge:
                              for first vd_mstr no-lock
                                 where vd_mstr.vd_domain = global_domain
                                   and vd_mstr.vd_addr   = tr_hist.tr_addr:
                              end.  /* first vd_mstr */
                               /* Get the category information for the element */
                              for first sc_mstr no-lock
                                 where sc_mstr.sc_domain = global_domain
                                   and sc_mstr.sc_sim    = pBaseCostSet
                                   and sc_mstr.sc_element = lc_mstr.lc_element:
                              end.
                              if available sc_mstr 
                              then do:
                                 if sc_mstr.sc_category = {&MATERIAL-CATEGORY} then
                                 assign
                                    lLAMtlCatVouchCsttot = lLAMtlCatVouchCsttot
                                                         + pvod_det.pvod_vouchered_amt
                                    lLAMtlCatAccruCsttot = lLAMtlCatAccruCsttot
                                                         + pvod_det.pvod_accrued_amt.
                                 if sc_mstr.sc_category = {&LABOR-CATEGORY} then
                                 assign
                                    lLALbrCatVouchCsttot = lLALbrCatVouchCsttot 
                                                         + pvod_det.pvod_vouchered_amt
                                    lLALbrCatAccruCsttot = lLALbrCatAccruCsttot 
                                                         + pvod_det.pvod_accrued_amt.
                                 if sc_mstr.sc_category = {&BURDEN-CATEGORY} then
                                 assign
                                    lLABdnCatVouchCsttot = lLABdnCatVouchCsttot 
                                                         + pvod_det.pvod_vouchered_amt
                                    lLABdnCatAccruCsttot = lLABdnCatAccruCsttot 
                                                         + pvod_det.pvod_accrued_amt.
                                 if sc_mstr.sc_category = {&OVERHEAD-CATEGORY} then
                                 assign
                                    lLAOvhCatVouchCsttot = lLAOvhCatVouchCsttot 
                                                         + pvod_det.pvod_vouchered_amt
                                    lLAOvhCatAccruCsttot = lLAOvhCatAccruCsttot 
                                                         + pvod_det.pvod_accrued_amt.
                                 if sc_mstr.sc_category = {&SUBCONTRACT-CATEGORY} then
                                 assign
                                    lLASubCatVouchCsttot = lLASubCatVouchCsttot 
                                                         + pvod_det.pvod_vouchered_amt
                                    lLASubCatAccruCsttot = lLASubCatAccruCsttot 
                                                         + pvod_det.pvod_accrued_amt.
                              end. /* if avail sc_mstr */
                              if pvo_mstr.pvo_curr <> pBaseCurrency
                              then do:
                                 /* GET BASE CURRENCY PRICE TO COMPARE */
                                 {us/px/pxrun.i 
                                    &PROC    = 'getCurrencyConversionAmtRoundingOptional'
                                    &PARAM   = "(input pvo_mstr.pvo_curr ,
                                                 input pBaseCurrency  ,
                                                 input pStatiSFallBack ,
                                                 input tr_hist.tr_effdate,
                                                 input pvod_det.pvod_vouchered_amt,
                                                 input False /* Rounding */,
                                                 output l_lcVouchMatchPrice)"
                                    &NOAPPERROR=true
                                    &CATCHERROR=true}
                                 if return-value <> {&SUCCESS-RESULT} 
                                 then 
                                    return error {&APP-ERROR-RESULT}.
                                 /* GET BASE CURRENCY PRICE TO COMPARE */
                                 {us/px/pxrun.i 
                                    &PROC    = 'getCurrencyConversionAmtRoundingOptional'
                                    &PARAM   = "(input pvo_mstr.pvo_curr ,
                                                 input pBaseCurrency  ,
                                                 input pStatiSFallBack ,
                                                 input tr_hist.tr_effdate,
                                                 input pvod_det.pvod_accrued_amt,
                                                 input False /* Rounding */,
                                                 output l_lcAccruMatchPrice)"
                                    &NOAPPERROR=true
                                    &CATCHERROR=true}
                                 if return-value <> {&SUCCESS-RESULT} 
                                 then 
                                    return error {&APP-ERROR-RESULT}.
                              end. /* IF pvo_mstr.pvo_curr <> pBaseCurrency */
                              else
                                 assign 
                                    l_lcVouchMatchPrice = pvod_det.pvod_vouchered_amt
                                    l_lcAccruMatchPrice = pvod_det.pvod_accrued_amt.
                              /* If Use Supplier Invoice Cost Only is yes, always use vouchered  *
                               * logistical charge; else if invoiced logistical charge           *
                               *(pvod_vouchered_amt) not zero, use invoiced logistical charge    *
                               * else use accrued logistical charges (pvod_det.pvod_accrued_amt) */                           
                              if pUseInvoiceCostOnly = no 
                              then do:	
                              /*  If vouchered logistical charge is not zero,use invoiced *
                     			     *  logistical charge else use  accrued logistcal charges  */
                                  if l_lcVouchMatchPrice <> 0 then
                                     assign logisticsChargeAmount = l_lcVouchMatchPrice.  
                                  else
                                     assign logisticsChargeAmount = l_lcAccruMatchPrice.
                              end. /* If pUseInvoiceCostOnly = no */
                              else /* If pUseInvoiceCostOnly = yes */
                              do:		
                                  /* If invoice found, use vouchered logistical charge *
                                   * else set to zero                                  */
                                  if lInvoiceExist = yes then
                                     logisticsChargeAmount = l_lcVouchMatchPrice.
                                  else
                                     logisticsChargeAmount = 0.
                              end. /* If pUseInvoiceCostOnly = no */
                              /* Get the variance account for Logistic charge */
                              /* RETRIEVE VARIANCE ACCOUNT */
      			                  {us/bbi/gprun.i ""laglacct.p""
                                 "(input ""{&TYPE_PO}"",
                                   input ""POPRICEVAR"",
                                   input lc_mstr.lc_charge,
                                   input """",
                                   input pSite,
                                   input if available vd_mstr then
                                         vd_mstr.vd_type else """",
                                   input """",
                                   output dftLAPPVAcct,
                                   output dftLAPPVSub,
                                   output dftLAPPVCC)"}
                               if return-value <> {&SUCCESS-RESULT}
                               then return error {&APP-ERROR-RESULT}.                        
                              /* Apart from Base 5 category elements 
                               * Material, Labor, Burden, Overhead and 
                               * Sub contract                               */
                              /* For this we have to find the standard cost 
                               *  for other elements for LC                 */
                              /* If pccost method is FIFO and Qty is negative *
                               * Then make it to act like issue               */
                              if ( pPCCostMethod = "WAVG" or
                                   (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0)) 
                              then do:
                                 if (pin_gl_set <> "")  then
                                 for each spt_det no-lock
                                 where spt_det.spt_domain     = global_domain
                                   and spt_det.spt_site       = pin_gl_cost_site
                                   and spt_det.spt_sim        = pin_gl_Set
                                   and spt_det.spt_part       = pItemNumber
                                   and spt_det.spt_element    = lc_mstr.lc_element
                                   and (logisticsChargeAmount - (tr_hist.tr_qty_loc * 
                                       (spt_det.spt_cst_tl    + spt_det.spt_cst_ll))) <> 0:    
                                 {us/px/pxrun.i 
                                    &PROC  = 'createTransactionDetail'
                                    &PARAM = "(input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPAcct
                                                     else dftCOPAcct)
                                               else dftInvAcct,
                                               input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPSub 
                                                     else dftCOPSub)
                                               else dftInvSub,
                                               input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPCC 
                                                     else dftCOPCC)
                                               else dftInvCC,
                                               input dftLAPPVAcct,
                                               input dftLAPPVSub,
                                               input dftLAPPVCC,
                                               input lProject,
                                               input ( logisticsChargeAmount
                                                      - ( tr_hist.tr_qty_loc 
                                               * ( spt_det.spt_cst_tl + spt_det.spt_cst_ll ))) 
                                               /* BASE CURRENCY AMOUNT */ ,
                                               input 0  
                                               /* STATUTORY CURRENCY AMOUNT */,
                                               input recid(tr_hist) ,
                                               input pEndDate,
                                               input pBaseCostset,
                                               input pStatCostset,
                                               input pBaseCurrency,
                                               input pStatCurrency,
                                               input pStatIsFallBack,
                                               input pSiteEntity,
                                               input ppc_calc_daybook,
                                               input ppc_daybook_desc,
                                               input pmr_daybook,
                                               input pmr_daybook_desc,
                                               input pglmir_yn,
                                               input dataset tapipostingdataiswithsaf
                                                             by-reference,
                                               input-output dataset tapipostingsaf
                                                                    by-reference,
                                               input-output table ttSafStrEntGLCCPrj
                                                                    by-reference )"
                                    &NOAPPERROR=true
                                    &CATCHERROR=true}
                                    if return-value <> {&SUCCESS-RESULT}
                                    then return error {&APP-ERROR-RESULT}.
                                 end.
                                 else if (picc_gl_set <> "")  
                                 then for each spt_det no-lock
                                 where spt_det.spt_domain     = global_domain
                                   and spt_det.spt_site       = pin_gl_cost_site
                                   and spt_det.spt_sim        = picc_gl_set
                                   and spt_det.spt_part       = pItemNumber
                                   and spt_det.spt_element    = lc_mstr.lc_element
                                   and (logisticsChargeAmount - (tr_hist.tr_qty_loc * 
                                       (spt_det.spt_cst_tl    + spt_det.spt_cst_ll))) <> 0:    
                                 {us/px/pxrun.i 
                                    &PROC  = 'createTransactionDetail'
                                    &PARAM = "(input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPAcct
                                                     else dftCOPAcct)
                                               else dftInvAcct,
                                               input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPSub 
                                                     else dftCOPSub)
                                               else dftInvSub,
                                               input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPCC 
                                                     else dftCOPCC)
                                               else dftInvCC,
                                               input dftLAPPVAcct,
                                               input dftLAPPVSub,
                                               input dftLAPPVCC,
                                               input lProject,
                                               input ( logisticsChargeAmount
                                                      - ( tr_hist.tr_qty_loc 
                                               * ( spt_det.spt_cst_tl 
                                               + spt_det.spt_cst_ll ))) 
                                               /* BASE CURRENCY AMOUNT */ ,
                                               input 0  
                                               /* STATUTORY CURRENCY AMOUNT */,
                                               input recid(tr_hist) ,
                                               input pEndDate,
                                               input pBaseCostset,
                                               input pStatCostset,
                                               input pBaseCurrency,
                                               input pStatCurrency,
                                               input pStatIsFallBack,
                                               input pSiteEntity,
                                               input ppc_calc_daybook,
                                               input ppc_daybook_desc,
                                               input pmr_daybook,
                                               input pmr_daybook_desc,
                                               input pglmir_yn,                                         
                                               input dataset tapipostingdataiswithsaf
                                                             by-reference,
                                               input-output dataset tapipostingsaf
                                                                    by-reference,
                                               input-output table ttSafStrEntGLCCPrj
                                                                    by-reference )"
                                    &NOAPPERROR=true
                                    &CATCHERROR=true}
                                 if return-value <> {&SUCCESS-RESULT}
                                 then return error {&APP-ERROR-RESULT}.
                                 end. 
                              end. /* if pPCCostMethod = "WAVG" */
                              /* Create AP rate variance if any */
                              if l_lcVouchMatchPrice <> 0 and
                                (l_lcVouchMatchPrice 
                                 - l_lcAccruMatchPrice) <> 0 
                              then do:
                                 {us/px/pxrun.i 
                                    &PROC  = 'createTransactionDetail'
                                    &PARAM = "(input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPAcct
                                                     else dftCOPAcct)
                                               else dftInvAcct,
                                               input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPSub 
                                                     else dftCOPSub)
                                               else dftInvSub,
                                               input if tr_ship_type = 'S' 
                                               then (if luseWIPAcct 
                                                     then dftWIPCC 
                                                     else dftCOPCC)
                                               else dftInvCC,
                                               input dftAPVRAcct,
                                               input dftAPVRSub,
                                               input dftAPVRCC,
                                               input lProject,
                                               input (l_lcVouchMatchPrice 
                                                      - l_lcAccruMatchPrice) 
                                               /* BASE CURRENCY AMOUNT */ ,
                                               input 0  
                                               /* STATUTORY CURRENCY AMOUNT */,
                                               input recid(tr_hist) ,
                                               input pEndDate,
                                               input pBaseCostset,
                                               input pStatCostset,
                                               input pBaseCurrency,
                                               input pStatCurrency,
                                               input pStatIsFallBack,
                                               input pSiteEntity,
                                               input ppc_calc_daybook,
                                               input ppc_daybook_desc,
                                               input pmr_daybook,
                                               input pmr_daybook_desc,
                                               input pglmir_yn,                                         
                                               input dataset tapipostingdataiswithsaf
                                                             by-reference,
                                               input-output dataset tapipostingsaf
                                                                    by-reference,
                                               input-output table ttSafStrEntGLCCPrj
                                                                    by-reference )"
                                    &NOAPPERROR=true
                                    &CATCHERROR=true}
                                 if return-value <> {&SUCCESS-RESULT}
                                 then return error {&APP-ERROR-RESULT}.
                              end.
                              /* Add the non-recoverable tax to the logistics amount */
                              
                              {us/gp/gprunp.i "soldxr" "p" "DateFormatToYMD"}
                              for each tx2d_det where tx2d_domain  = global_domain
                                 and tx2d_ref     = (lgd_mstr.lgd_shipfrom + "," + lgd_mstr.lgd_nbr
                                                    + "," + string(lgd_mstr.lgd_effdate) )
                                 and tx2d_tr_type = "30" 
                                 and tx2d_line = tr_hist.tr_line no-lock
                                 
                              break by tx2d_tax_code
                                    by tx2d_line:
                            
                                 accumulate tx2d_tax_amt (sub-total by tx2d_line).
                                 accumulate tx2d_cur_recov_amt (sub-total by tx2d_line).
                                 
                                 if last-of(tx2d_line) then do:
                                    post_LAtaxamt = accum sub-total by tx2d_line tx2d_tax_amt.
                                    post_LAtaxrecov_amt = accum sub-total by tx2d_line tx2d_cur_recov_amt.
                                    l_postLATaxNonRecovAmt = post_LAtaxamt - post_LAtaxrecov_amt.
                                    {us/px/pxrun.i 
                                          &PROC  = 'createTransactionDetail'
                                          &PARAM = "(input if tr_ship_type = 'S' 
                                                     then (if luseWIPAcct 
                                                           then dftWIPAcct
                                                           else dftCOPAcct)
                                                     else dftInvAcct,
                                                     input if tr_ship_type = 'S' 
                                                     then (if luseWIPAcct 
                                                           then dftWIPSub 
                                                           else dftCOPSub)
                                                     else dftInvSub,
                                                     input if tr_ship_type = 'S' 
                                                     then (if luseWIPAcct 
                                                           then dftWIPCC 
                                                           else dftCOPCC)
                                                     else dftInvCC,
                                                     input dftLAPPVAcct,
                                                     input dftLAPPVSub,
                                                     input dftLAPPVCC,
                                                     input lProject,
                                                     input (if tx2d_tax_in = no 
                                                            then 
                                                               post_LAtaxamt - post_LAtaxrecov_amt
                                                            else
                                                               ((post_LAtaxamt - l_postLATaxNonRecovAmt) * -1)) 
                                                     /* BASE CURRENCY AMOUNT */ ,
                                                     input 0  
                                                     /* STATUTORY CURRENCY AMOUNT */,
                                                     input recid(tr_hist) ,
                                                     input pEndDate,
                                                     input pBaseCostset,
                                                     input pStatCostset,
                                                     input pBaseCurrency,
                                                     input pStatCurrency,
                                                     input pStatIsFallBack,
                                                     input pSiteEntity,
                                                     input ppc_calc_daybook,
                                                     input ppc_daybook_desc,
                                                     input pmr_daybook,
                                                     input pmr_daybook_desc,
                                                     input pglmir_yn,                                         
                                                     input dataset tapipostingdataiswithsaf
                                                                   by-reference,
                                                     input-output dataset tapipostingsaf
                                                                          by-reference,
                                                     input-output table ttSafStrEntGLCCPrj
                                                                          by-reference )"
                                          &NOAPPERROR=true
                                          &CATCHERROR=true}
                                    if return-value <> {&SUCCESS-RESULT}
                                    then return error {&APP-ERROR-RESULT}.
                                    if tx2d_tax_in = no 
                                    then 
                                       logisticsChargeAmount = logisticsChargeAmount + (post_LAtaxamt - post_LAtaxrecov_amt).
                                    else
                                       logisticsChargeAmount = logisticsChargeAmount - (post_LAtaxamt - l_postLATaxNonRecovAmt).
                                 end.      
                              end.      
                               {us/gp/gprunp.i "soldxr" "p" "RevertDateFormat"}
                                     
                                     
                              /* SUM UP THE LOGISTICS CHARGE AMOUNT
                                 AGAINST THE COST ELEMENT THAT HAS BEEN MAPPED
                                 TO THE LOGISTICS CHARGE CODE */
                              /* save the tt-CostElementInfor for this item,costset */	   
                              if logisticsChargeAmount <> 0 and
                                 ( pPCCostMethod = "WAVG" or
                                   (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0))
                              then do:
                                 {us/px/pxrun.i 
                                   &PROC    = 'updateCostElementInfo'
                                   &PARAM   = "(input pBaseCostSet,
                                              input pStatCostSet,
                                              input pBaseCurrency,
                                       				input pStatCurrency,
      				                                input pStatIsFallBack,
                                              input tr_hist.tr_effdate,
                                              input pSite,
                                              input pItemNumber,
                                              input lc_mstr.lc_element,
                                              input logisticsChargeAmount, /*THIS LEVEL*/
                                              input 0 /*LOWER LEVEL*/ )"
                                 &NOAPPERROR=true
                                 &CATCHERROR=true}
                                 if return-value <> {&SUCCESS-RESULT}
                                 then return error {&APP-ERROR-RESULT}.
      			                  end.  /* if logisticsChargeAmount <> 0 */
                              /* Since with current developement we are only 
                                 allowing element on material, overhead category 
                                 we only total up for material/Overhead category  */
                              if available sc_mstr 
                              then do:
                                 assign
                                 lLogisticsVouchAmount = lLogisticsVouchAmount 
                                                       + l_lcVouchMatchPrice
                                 lLogisticsAccruAmount = lLogisticsAccruAmount 
                                                       + l_lcAccruMatchPrice
                                 lLogisticsTotalAmount = lLogisticsTotalAmount +
                                                         logisticsChargeAmount.
                              end. /* avail sc_mstr */                           
                           end.   /* first lc_mstr */
                        end.   /* else do             */
                     end.     /* each pvod_det       */
                  end.       /* each pvo_mstr       */
               end. /* For first Lgdd_det */
            end. /* If tr_type = "RCT-LA"  */
            /* PURCHASE PRICE VARIANCE WILL EXIST IF THERE IS ANY DIFFERENCE  */
            /* BETWEEN l_total_cost AND l_base_amt OR PO IS CREATED WITH      */
            /* NON-RECOVERABLE TAX ACCRUED AT RECEIPT.                        */
            /* EXCHANGE ROUNDING WILL EXIST WHEN l_total_cost IS EQUAL TO     */
            /* l_base_amt AND IF THERE IS VARIANCE DUE TO CURRENCY CONVERSION */
            /* OR EXCHANGE RATE DIFFERENCE BETWEEN PO AND RECEIPT.            */
 
            /* 1. CALCULATE THE PURCHASE PRICE VARIANCE USING UNROUNDED      */
            /*    GL MATERIAL COST AND THE PO PRICE USING FORMULA:           */
            /*    (a) WHEN LOGISTICS ACCOUNTING = No.                        */
            /*    [(Total GL Cost - Overhead cost) * Qty] - [PO Cost * Qty]. */
            /*    (b) WHEN LOGISTICS ACCOUNTING = Yes.                       */
            /*   (Total GL Cost - Overhead Cost - Logistics Charges  * Qty]  */
            /*    - [PO Cost * Qty].                                         */
            /* 2. WHEN DEFAULT PO COST <> PO COST, AND COSTING ENV IS NOT    */
            /*    AVERAGE CALCULATE PPV USING THE FORMULA:                   */
            /*    gl_amt[3] = l_ppv_amt + line_tax.                          */
            /* 3. WHEN DEFAULT PO COST = PO COST CALCULATE THE EXCHANGE      */
            /*    ROUNDING VARIANCE USING THE FORMULA:                       */
            /*    gl_amt[5] = l_excrv_amt.                                   */
            /* Tax Type                            */
            /**  20  Purchase Order
               *  21  Purchase Order Receipt
               *  22  AP Voucher
               *  23  PO Receipts Relief (makes sure that sum 21, 22, 23 
                                          represents total taxes on purchases 
                                          through vouchering )
               *  24  PO Shipper Maintenance
               *  25  PO Return to Supplier
               *  26  Logistics Accounting - PO Fiscal Receipts
               *  27  Logistics Accounting - PO Receipts Activities
               *  28  Logistics Accounting - PO Receipts Relief
               *  29  AP Payment Check (Discount at Payment)
               *  30  legal document
               *  32  Recurring Voucher                                      */
 
            if (tr_hist.tr_type = 'RCT-PO' or 
               tr_hist.tr_type = 'RCT-LA')
            then do:	 
               if pUseInvoiceCostOnly = yes 
               then do:
                  if lInvoiceExist = yes then
                     taxTransactionType = "30". /* Legal document tax */
                  else
                     taxTransactionType = "". 
               end. /* pUseInvoiceCostOnly = yes */
               else
                  taxTransactionType = "21".  /* Regular PO tax */
            end.
            else
               taxTransactionType = "25".  /* PO return tax */  
 
             /* Get rounding method of currency */
            {us/px/pxrun.i &PROC='mc-get-rnd-mthd'
               &PROGRAM='mcpl.p'
               &HANDLE = ph_mcpl
               &PARAM="(input tr_hist.tr_curr,
                        output lglrndmthd,
                        output l_ErrorNumber)"}
 
            if l_ErrorNumber <> 0
            then return error {&APP-ERROR-RESULT}.
            for first lgd_mstr no-lock
               where lgd_mstr.oid_lgd_mstr = tr_hist.oid_lgd_mstr:
            end.
            if taxTransactionType <> "" 
            then do:
              {us/px/pxrun.i 
                 &PROC  = 'GetPOLineTaxInfo'
                 &PROGRAM='pccalxr1.p'
                 &HANDLE = ph_pccalxr1
                 &PARAM = "(input llastrcptforreceiver,
                     input taxTransactionType /* Tax type */ ,
                          input if taxTransactionType = '30'
                                then if avail lgd_mstr 
                                     then (lgd_mstr.lgd_shipfrom + ',' + lgd_mstr.lgd_nbr
                                           + ',' + string(lgd_mstr.lgd_effdate))
                                     else ''
                                else tr_hist.tr_lot,
                          input tr_hist.tr_nbr,
                          input tr_hist.tr_line,
                          input pusing_supp_consign,
                          input if available pod_det 
                                then pod_det.pod_consignment 
                                else No, /* Is Conisgnment */
                          input if available pod_det 
                                then pod_det.pod_consignment 
                                else No, /* is usage */
                          input if avail prh_hist
                             then if tr_hist.tr_um <> prh_hist.prh_um
                                then (prh_hist.prh_rcvd * prh_hist.prh_um_conv)
                                else prh_hist.prh_rcvd
                                else 0,
                          input tr_hist.tr_qty_loc,
                          input pBaseCurrency ,
                          input tr_hist.tr_curr,
                          input tr_hist.tr_ex_rate,
                          input tr_hist.tr_ex_rate2,
                          input if available pod_det 
                                then pod_det.pod_type
                                else '',
                          input lglrndmthd,
                          output line_tax,
                          output NRline_tax)"
                      &NOAPPERROR=true
                      &CATCHERROR=true}
 
                if return-value <> {&SUCCESS-RESULT}
                then return error {&APP-ERROR-RESULT}.
            end. /* if taxTransactionType <> "" */
            else do:				 
               /* Use Supplier Invoice Cost is yes, but no invoice found *
                * set taxt to zero                                       */
               assign line_tax = 0
                      NRline_tax = 0.
            end.	  
 
            /* ONLY USE INVOICE AMOUNT FOR TRANSACTIONS <> RCT-LA    */
            /* SINCE THE LOGISTICS CHARGE AMOUNT IS ALREADY TAKEN IN */
            /* lLogisticsTotalAmount VARIABLE                        */
            if tr_hist.tr_type <> "RCT-LA"
            then do:

               if lInvoiceExist 
               then do:
    
                  lInvoiceAmt = tr_hist.tr_qty_loc * lUnitCost.
               end. /* Invoice is found */
               else /* invoice is not found */
               do:
                  /* if Use Invoice Cost Only is yes and no invoice found, display a warning */
                  if pUseInvoiceCostOnly = yes 
                  then do:
                     /* Use Supplier Invoice Cost is yes, but no invoice found for PO #  */
                    {us/bbi/pxmsg.i &MSGNUM=12085 &MSGARG1=tr_hist.tr_nbr &ERRORLEVEL=1 &MSGBUFFER = msgString}	  
                     display msgString skip with frame a width 132 no-label. 
    
                     /* set item cost to zero  */
                     lInvoiceAmt = 0.
                  end. /* if pUseInvoiceCostOnly = yes */
                  else 
    
                     lInvoiceAmt = tr_hist.tr_qty_loc * tr_hist.tr_price.
               end.   /* invoice is not found */
            end. /* IF tr_hist.tr_type <> "RCT-LA" */
            
            /* Add the overhead cost coming from previous period PC cost *
             * this is a requirement for Brazil                          */        
            if pPCCostMethod = "WAVG"
            then do:
               assign l_prevpdPCOvhAmt = 0.
               for each tt-spt_det no-lock
                  where tt-spt_det.spt_domain     = global_domain
                    and tt-spt_det.spt_site       = tr_hist.tr_site
                    and tt-spt_det.spt_sim        = pPrevPeriodBaseCostSet
                    and tt-spt_det.spt_part       = pItemNumber:
                  for first sc_mstr no-lock
                     where sc_mstr.sc_domain = global_domain
                       and sc_mstr.sc_sim = pPrevPeriodBaseCostSet
                       and sc_mstr.sc_element = tt-spt_det.spt_element
                       and sc_mstr.sc_category = {&OVERHEAD-CATEGORY}
                                                  /* OVERHEAD Category */:
                     l_prevpdPCOvhAmt = l_prevpdPCOvhAmt + (  tr_hist.tr_qty_loc * ( tt-spt_det.spt_cst_tl + tt-spt_det.spt_cst_ll) ).
                  end. 
               end.   
               assign lInvoiceAmt = lInvoiceAmt + l_prevpdPCOvhAmt.
                  
            
               if ( l_prevpdPCOvhAmt <> 0 )
               then do:
                  {us/px/pxrun.i 
                      &PROC  = 'createTransactionDetail'
                      &PARAM = "(input if tr_hist.tr_ship_type = 'S'
                                    then (if luseWIPAcct 
                                          then dftWIPAcct 
                                          else dftCOPAcct)
                                    else dftInvAcct,
                              input if tr_hist.tr_ship_type = 'S'
                                    then (if luseWIPAcct 
                                          then dftWIPSub 
                                          else dftCOPSub)
                                    else dftInvSub,
                              input if tr_hist.tr_ship_type = 'S'
                                    then (if luseWIPAcct 
                                          then dftWIPCC 
                                          else dftCOPCC)
                                    else dftInvCC,
                              input dftOVHAcct,
                              input dftOVHSub,
                              input dftOVHCC,      
                              input lProject,
                              input (l_prevpdPCOvhAmt ) 
                                     /* BASE CURRENCY AMOUNT */,
                              input 0 /* STATUTORY CURRENCY AMOUNT */,
                              input recid(tr_hist) ,
                              input pEndDate,
                              input pBaseCostset,
                              input pStatCostset,
                              input pBaseCurrency,
                              input pStatCurrency,
                              input pStatIsFallBack,
                              input pSiteEntity,
                              input ppc_calc_daybook,
                              input ppc_daybook_desc,
                              input pmr_daybook,
                              input pmr_daybook_desc,
                              input pglmir_yn,                             
                              input dataset tapipostingdataiswithsaf
                                            by-reference,
                              input-output dataset tapipostingsaf 
                                                   by-reference,
                              input-output table ttSafStrEntGLCCPrj
                                                 by-reference )"
                      &NOAPPERROR=true
                      &CATCHERROR=true}
   
                   if return-value <> {&SUCCESS-RESULT}
                   then return error {&APP-ERROR-RESULT}.
               
               
               end.    
            end.
            /* we have to always pass only positive values  to GL  */
            /* It will take care of credit and debit side          */
            /* UPDATE THE CALCULATED PERIODIC COST
                AMOUNT INTO tr_gl_amt FIELD with Invoiceamt , 
                overhead cost and line tax  */
            {us/px/pxrun.i 
                  &PROC='updateGLAmount'
                  &PARAM="(input recid(tr_hist),
                        input 'tr_hist',
                        input lInvoiceAmt 
                              + ( if lInvoiceExist
                                  then (if pod_tax_in = no
                                        then (line_tax + nrline_tax)
                                        else 0 )
                                  else (line_tax + nrline_tax) )      
                              + lLogisticsTotalAmount,
                        input pBaseCurrency ,
                        input pStatCurrency ,
                        input pStatIsFallBack ,
                        input-output pTranscounter)"
                  &NOAPPERROR=true
                  &CATCHERROR=true}
 
            if return-value <> {&SUCCESS-RESULT}
            then return error {&APP-ERROR-RESULT}.
 
            if tr_hist.tr_ship_type <> "S"
            then do:
               /* UPDATE THE RECEIPT QTY IN TEMPORARY INVENTORY LOCATION
                  DETAIL TABLE FOR THE CURRENT COST CALCULATION
                  PERIOD BASED ON PART/SITE/LOCATION 
                  Ending Balance
                  ReceivedQuantity
                  UnconsumedQuantity */
               /* if the qty is negative and cost method is FIFO *
                * we have already deducted from *
                * different periods */   
               if ( pPCCostMethod = "WAVG" or
                  (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0))
                  and tr_hist.tr_type <> "RCT-LA"
               then do:              
                  {us/px/pxrun.i 
                  &PROC    = 'updateQtyInfo'
                  &PARAM   = "(input pCostCalcPeriodOID ,
                               input pItemNumber,
                               input pSite,
                               input tr_hist.tr_loc,
                               input tr_hist.tr_qty_loc
                               /* Ending Balance */,
                               input tr_hist.tr_qty_loc
                               /* ReceivedQuantity */ ,
                               input tr_hist.tr_qty_loc
                               /* UnconsumedQuantity */ )"
                  &NOAPPERROR=true
                  &CATCHERROR=true}
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
               end.
 
               /* if logistic acctg is not used and *
                * there are elements on material category *
                * we have move value to right element *
                * so deduct from material element */
               if use-log-acctg = no
               then do:
                  if ( pPCCostMethod = "WAVG" or
                     (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0))
                  then do:
                     if can-find (first spt_det no-lock
                              where spt_det.spt_domain     = global_domain
                                and spt_det.spt_site       = pin_gl_cost_site
                                and spt_det.spt_sim        = psimcostset
                                and spt_det.spt_part       = pItemNumber
                                and spt_det.spt_element    <> usr_val[1])
                     then for each spt_det no-lock
                        where spt_det.spt_domain = global_domain
                          and spt_det.spt_site   = pin_gl_cost_site
                          and spt_det.spt_sim    = psimcostset
                          and spt_det.spt_part   = pItemNumber
                          and spt_det.spt_element <> usr_val[1]
                          and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                          for first sc_mstr no-lock
                           where sc_mstr.sc_domain = global_domain
                             and sc_mstr.sc_sim = psimcostset
                             and sc_mstr.sc_element = spt_det.spt_element
                             and sc_mstr.sc_category = {&MATERIAL-CATEGORY}
                                                    /* Material Category */:
                           nonlogchgmatcatamount = nonlogchgmatcatamount + 
                                  ((spt_det.spt_cst_tl + spt_det.spt_cst_ll) 
                                      * tr_hist.tr_qty_loc ).
                          end.      
                     end.
                     else do:           
                     if (pin_gl_set <> "")  then
                     for each spt_det no-lock
                        where spt_det.spt_domain = global_domain
                          and spt_det.spt_site   = pin_gl_cost_site
                          and spt_det.spt_sim    = pin_gl_Set
                          and spt_det.spt_part   = pItemNumber
                          and spt_det.spt_element <> usr_val[1]
                          and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                        for first sc_mstr no-lock
                           where sc_mstr.sc_domain = global_domain
                             and sc_mstr.sc_sim = pin_gl_set
                             and sc_mstr.sc_element = spt_det.spt_element
                             and sc_mstr.sc_category = {&MATERIAL-CATEGORY}
                                                    /* Material Category */:
                           nonlogchgmatcatamount = nonlogchgmatcatamount + 
                                  ((spt_det.spt_cst_tl + spt_det.spt_cst_ll) 
                                      * tr_hist.tr_qty_loc ).
                        end.      
                     end.
                     else if (picc_gl_set <> "")  then
                     for each spt_det no-lock
                        where spt_det.spt_domain = global_domain
                          and spt_det.spt_site   = pin_gl_cost_site
                          and spt_det.spt_sim    = picc_gl_Set
                          and spt_det.spt_part   = pItemNumber
                          and spt_det.spt_element <> usr_val[1]
                          and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                        for first sc_mstr no-lock
                           where sc_mstr.sc_domain = global_domain
                             and sc_mstr.sc_sim = picc_gl_set
                             and sc_mstr.sc_element = spt_det.spt_element
                             and sc_mstr.sc_category = {&MATERIAL-CATEGORY} 
                                                   /* Material Category */ :
                           assign nonlogchgmatcatamount = nonlogchgmatcatamount + 
                                    ((spt_det.spt_cst_tl + spt_det.spt_cst_ll) 
                                      * tr_hist.tr_qty_loc ).
                        end.      
                     end.   
                     end.     /* Not equal to simcost */ 
                  end. /* if ppccostmethod = wavg */
               end. /* if use-log ac */    
               /* UPDATE THE RECEIPT VALUE(ELEMENT WISE) INTO
                  TEMPORARY SUMMED INVENTORY VALUE TABLE
                  AGAINST BASE COSTSET AND STATUTORY COSTSET */
 
               if ( pPCCostMethod = "WAVG" or
                     (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0)) and
                  tr_hist.tr_type <> "RCT-LA"   
               then do:   
                  {us/px/pxrun.i 
                  &PROC    = 'updateCostElementInfo'
                  &PARAM   = "(input pBaseCostSet,
                               input pStatCostSet,
		                           input pBaseCurrency,
		                           input pStatCurrency,
		                           input pStatIsFallBack,
                               input tr_hist.tr_effdate,
                               input pSite,
                               input pItemNumber,
                               input usr_val[1] /* Material Element */,
                               input lInvoiceAmt + ( if lInvoiceExist
                                                     then ( if pod_tax_in = no 
                                                            then (line_tax + NRline_tax)
                                                            else 0 )
                                                     else (line_tax + NRline_tax) ) - 
                                      nonlogchgmatcatamount /*THIS LEVEL*/,
                               input 0           /*LOWER LEVEL*/ )"
                  &NOAPPERROR=true
                  &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
               end.
 
               nonlogchgmatcatamount = 0.
 
               /* NOw see if apart from Material element we have 
                *  any element for puchase part */
               /* For this we have to find the standard cost 
                *  for other elements               */
               /* We do not do it for Logistics charge 
                *  as we had done earlier */
               if ( pPCCostMethod = "WAVG" or
                     (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0))
               then do: 
                  if can-find (first spt_det no-lock
                              where spt_det.spt_domain     = global_domain
                                and spt_det.spt_site       = pin_gl_cost_site
                                and spt_det.spt_sim        = psimcostset
                                and spt_det.spt_part       = pItemNumber
                                and spt_det.spt_element    <> usr_val[1])
                  then for each spt_det no-lock
                        where spt_det.spt_domain = global_domain
                        and spt_det.spt_site   = pin_gl_cost_site
                        and spt_det.spt_sim    = psimcostset
                        and spt_det.spt_part   = pItemNumber
                        and spt_det.spt_element <> usr_val[1]
                        and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                        if use-log-acctg
                        then do:  
                           for first lc_mstr no-lock
                             where lc_mstr.lc_domain   = global_domain
                               and lc_mstr.lc_element  = spt_det.spt_element
                               and lc_mstr.lc_charge <> "":
                           end.
                           if available lc_mstr then next.
                        end.   
                        else do:
                          for first sc_mstr no-lock 
                            where sc_mstr.sc_domain = global_domain
                              and sc_mstr.sc_sim = psimcostset
                              and sc_mstr.sc_element = spt_det.spt_element
                              and sc_mstr.sc_category = {&MATERIAL-CATEGORY}:
                           end.
                           if not available sc_mstr then next.
                        end.         
                        /* store the cost to temp table tt-CostElementInfo */
                        {us/px/pxrun.i 
                        &PROC    = 'updateCostElementInfo'
                                    &PARAM   = "(input pBaseCostSet,
                                                 input pStatCostSet,
   			                          input pBaseCurrency,
			                            input pStatCurrency,
			                            input pStatIsFallBack,
                                  input tr_hist.tr_effdate,
                                  input pSite,
                                  input pItemNumber,
                                                 input spt_det.spt_element /* Element */,
                                  input ( tr_hist.tr_qty_loc 
                                         * spt_det.spt_cst_tl)
                                  /*THIS LEVEL*/,
                                  input ( tr_hist.tr_qty_loc 
                                         * spt_det.spt_cst_ll) 
                                  /*LOWER LEVEL*/ )"
                                    &NOAPPERROR=true
                                    &CATCHERROR=true}
                        if return-value <> {&SUCCESS-RESULT}
                        then return error {&APP-ERROR-RESULT}.      
                  end.
                  else do:
                  if (pin_gl_set <> "")  then
                  for each spt_det no-lock
                     where spt_det.spt_domain = global_domain
                     and spt_det.spt_site   = pin_gl_cost_site
                     and spt_det.spt_sim    = pin_gl_Set
                     and spt_det.spt_part   = pItemNumber
                     and spt_det.spt_element <> usr_val[1]
                     and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                     if use-log-acctg
                     then do:  
                        for first lc_mstr no-lock
                           where lc_mstr.lc_domain   = global_domain
                             and lc_mstr.lc_element  = spt_det.spt_element
                             and lc_mstr.lc_charge <> "":
                        end.
                        if available lc_mstr then next.
                     end.   
                     else do:
                        for first sc_mstr no-lock 
                           where sc_mstr.sc_domain = global_domain
                             and sc_mstr.sc_sim = pin_gl_set
                             and sc_mstr.sc_element = spt_det.spt_element
                             and sc_mstr.sc_category = {&MATERIAL-CATEGORY}:
                        end.
                        if not available sc_mstr then next.
                     end.         
 
 
 
                     /* store the cost to temp table tt-CostElementInfo */
 
                     {us/px/pxrun.i 
                        &PROC    = 'updateCostElementInfo'
                        &PARAM   = "(input pBaseCostSet,
                                  input pStatCostSet,
   			                          input pBaseCurrency,
			                            input pStatCurrency,
			                            input pStatIsFallBack,
                                  input tr_hist.tr_effdate,
                                  input pSite,
                                  input pItemNumber,
                                  input spt_det.spt_element /* Element */,
                                  input ( tr_hist.tr_qty_loc 
                                         * spt_det.spt_cst_tl)
                                  /*THIS LEVEL*/,
                                  input ( tr_hist.tr_qty_loc 
                                         * spt_det.spt_cst_ll) 
                                  /*LOWER LEVEL*/ )"
                        &NOAPPERROR=true
                        &CATCHERROR=true}
                     if return-value <> {&SUCCESS-RESULT}
                     then return error {&APP-ERROR-RESULT}.
 
                  end.
                  else if (picc_gl_set <> "")  then
                  for each spt_det no-lock
                     where spt_det.spt_domain = global_domain
                       and spt_det.spt_site   = pin_gl_cost_site
                       and spt_det.spt_sim    = picc_gl_Set
                       and spt_det.spt_part   = pItemNumber
                       and spt_det.spt_element <> usr_val[1]
                       and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0 :
                     if use-log-acctg
                     then do:  
                        for first lc_mstr no-lock
                           where lc_mstr.lc_domain   = global_domain
                             and lc_mstr.lc_element  = spt_det.spt_element
                             and lc_mstr.lc_charge <> "":
                        end.
                        if available lc_mstr then next.
                     end.
                     else do:
                        for first sc_mstr no-lock 
                           where sc_mstr.sc_domain = global_domain
                             and sc_mstr.sc_sim = picc_gl_set
                             and sc_mstr.sc_element = spt_det.spt_element
                             and sc_mstr.sc_category = {&MATERIAL-CATEGORY} :
                        end.
                        if not available sc_mstr then next.
                     end.      
 
 
 
                     {us/px/pxrun.i 
                        &PROC    = 'updateCostElementInfo'
                        &PARAM   = "(input pBaseCostSet,
                                  input pStatCostSet,
		                              input pBaseCurrency,
		                              input pStatCurrency,
	                                input pStatIsFallBack,
                                  input tr_hist.tr_effdate,
                                  input pSite,
                                  input pItemNumber,
                                  input spt_det.spt_element /* Element */,
                                  input ( tr_hist.tr_qty_loc 
                                         * spt_det.spt_cst_tl)
                                  /*THIS LEVEL*/,
                                  input ( tr_hist.tr_qty_loc 
                                         * spt_det.spt_cst_ll)
                                  /*LOWER LEVEL*/ )"
                        &NOAPPERROR=true
                        &CATCHERROR=true}
                     if return-value <> {&SUCCESS-RESULT}
                     then return error {&APP-ERROR-RESULT}.
                  end. /* for each spt_det no-lock */
                  end. /* if not sim cost set */   
               end. /*  if ( pPCCostMethod = "WAVG" or */  
            end. /* if tr_ship_type <> "S" */

            /* THE PPV has to be reversed to inventory account */
            /* For Purchase item check against material cost   */
            /* for Manuafactured item check against total cost */
            /* For sub contract ones                           */
            /* The PO receipt could come from Kanban, we check */
            /* whether to use WIPacct                          */
 
            /* THIS CHANGE IS TO GET JUST THE MATERIAL UNIT COST TO USE IT */
            /* TO CALCULATE PPV BECAUSE OF DIFFERENT APPORTION METHODS     */
            if use-log-acctg = yes
            then do:
                if can-find(first pvo_mstr
                     where pvo_mstr.pvo_domain            = global_domain
                     and   pvo_mstr.pvo_order             = tr_hist.tr_nbr
                     and   pvo_mstr.pvo_internal_ref      = tr_hist.tr_lot
                     and   pvo_mstr.pvo_order_type        = {&TYPE_PO}
                     and   pvo_mstr.pvo_internal_ref_type = {&TYPE_POReceiver}
                     and   pvo_mstr.pvo_lc_charge         <> "") 
               then do:
                  if can-find (first spt_det no-lock
                              where spt_det.spt_domain     = global_domain
                                and spt_det.spt_site       = pin_gl_cost_site
                                and spt_det.spt_sim        = psimcostset
                                and spt_det.spt_part       = pItemNumber
                                and spt_det.spt_element    = usr_val[1])
                  then for each spt_det no-lock
                        where spt_det.spt_domain  = global_domain
                        and spt_det.spt_site    = pin_gl_cost_site
                        and spt_det.spt_sim     = psimcostset
                        and spt_det.spt_part    = pItemNumber
                        and spt_det.spt_element = usr_val[1]
                        and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                        assign l_mtl_std = spt_det.spt_cst_tl + spt_det.spt_cst_ll.
                  end.              
                  else do:
               if (pin_gl_set <> "") 
               then
                  for each spt_det no-lock
                     where spt_det.spt_domain  = global_domain
                       and spt_det.spt_site    = pin_gl_cost_site
                       and spt_det.spt_sim     = pin_gl_Set
                       and spt_det.spt_part    = pItemNumber
                       and spt_det.spt_element = usr_val[1]
                       and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                     assign l_mtl_std = spt_det.spt_cst_tl + spt_det.spt_cst_ll.
                  end.
               else if (picc_gl_set <> "") 
               then
                  for each spt_det no-lock
                     where spt_det.spt_domain  = global_domain
                       and spt_det.spt_site    = pin_gl_cost_site
                       and spt_det.spt_sim     = picc_gl_Set
                       and spt_det.spt_part    = pItemNumber
                       and spt_det.spt_element = usr_val[1]
                       and (spt_det.spt_cst_tl + spt_det.spt_cst_ll) <> 0:
                     assign l_mtl_std = spt_det.spt_cst_tl + spt_det.spt_cst_ll.
                  end.
                  end. /* if not sim cost set */ 
               end. /* if can find pvo */  
               else assign l_mtl_std = tr_hist.tr_mtl_std.     
            end. /* IF use-log-acctg = yes */
            else
               assign l_mtl_std = tr_hist.tr_mtl_std.
 
            if ( pPCCostMethod = "WAVG" or
                (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0)) and
                (tr_hist.tr_type <> "RCT-LA" )
               and can-find(first icc_ctrl no-lock
                               where icc_domain  = global_domain
                               and   icc_gl_tran = yes )
            then do: 
               /* CHANGED TO CALCULATE PPV WITHOUT USING LOGISTICS CHARGES */
               /* UNIT COST */
               if (pItem_pm_code = "P" or pItem_pm_code = "") and
                  (((tr_hist.tr_price * tr_hist.tr_qty_loc)  -
                   (((l_mtl_std + tr_hist.tr_lbr_std 
                      + tr_hist.tr_sub_std + tr_hist.tr_bdn_Std) 
                     * tr_hist.tr_qty_loc))) 
                     + line_tax) <> 0
               then do:
                  {us/px/pxrun.i 
                     &PROC  = 'createTransactionDetail'
                     &PARAM = "(input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPAcct 
                                         else dftCOPAcct)
                                   else dftInvAcct,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPSub 
                                         else dftCOPSub)
                                   else dftInvSub,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPCC 
                                         else dftCOPCC)
                                   else dftInvCC,
                             input dftPPVAcct,
                             input dftPPVSub,
                             input dftPPVCC,
                             input lProject,
                             input if tr_hist.tr_ship_type = 'S'
                                   then ( line_tax )
                                   else (((tr_hist.tr_price 
                                           * tr_hist.tr_qty_loc) -
                                         (((l_mtl_std 
                                            + tr_hist.tr_lbr_std 
                                            + tr_hist.tr_sub_std 
                                            + tr_hist.tr_bdn_Std) 
                                           * tr_hist.tr_qty_loc)) ) 
                                         + line_tax) /* BASE CURRENCY AMOUNT */,
                             input 0 /* STATUTORY CURRENCY AMOUNT */,
                             input recid(tr_hist) ,
                             input pEndDate,
                             input pBaseCostset,
                             input pStatCostset,
                             input pBaseCurrency,
                             input pStatCurrency,
                             input pStatIsFallBack,
                             input pSiteEntity,
                             input ppc_calc_daybook,
                             input ppc_daybook_desc,
                             input pmr_daybook,
                             input pmr_daybook_desc,
                             input pglmir_yn,                             
                             input dataset tapipostingdataiswithsaf
                                           by-reference,
                             input-output dataset tapipostingsaf 
                                                  by-reference,
                             input-output table ttSafStrEntGLCCPrj
                                                by-reference )"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
 
               end. /* if (pItem_pm_code = "P" or pItem_pm_code = "")  */
 
               if (pItem_pm_code = "M" or 
                  pItem_pm_code = "L" or 
                  pItem_pm_code = "R" or
                  pItem_pm_code = "C" or 
                  pItem_pm_code = "F" or 
                  pItem_pm_code = "W") and
                  (((tr_hist.tr_price * tr_hist.tr_qty_loc) - 
                  (((l_mtl_std + tr_hist.tr_lbr_std 
                   + tr_hist.tr_ovh_std + tr_hist.tr_sub_std 
                   + tr_hist.tr_bdn_std)
                   * tr_qty_loc)) ) 
                   + line_tax) <> 0
               then do:
                  /* create trgl_det, glt_det records */
                  {us/px/pxrun.i 
                     &PROC  = 'createTransactionDetail'
                     &PARAM = "(input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPAcct 
                                         else dftCOPAcct)
                                   else dftInvAcct,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPSub 
                                         else dftCOPSub)
                                   else dftInvSub,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPCC 
                                         else dftCOPCC)
                                   else dftInvCC,
                             input dftPPVAcct,
                             input dftPPVSub,
                             input dftPPVCC,
                             input lProject,
                             input if tr_hist.tr_ship_type = 'S'
                                   then ( line_tax )
                                   else (((tr_hist.tr_price 
                                           * tr_hist.tr_qty_loc) -
                                         (((l_mtl_std 
                                            + tr_hist.tr_lbr_std 
                                            + tr_hist.tr_ovh_std
                                            + tr_hist.tr_sub_std 
                                            + tr_hist.tr_bdn_Std) 
                                           * tr_hist.tr_qty_loc))) 
                                         + line_tax) /* BASE CURR AMOUNT */,
                              input 0 /* STATUTORY CURRENCY AMOUNT */,
                              input recid(tr_hist) ,
                              input pEndDate,
                              input pBaseCostset,
                              input pStatCostset,
                              input pBaseCurrency,
                              input pStatCurrency,
                              input pStatIsFallBack,
                              input pSiteEntity,
                              input ppc_calc_daybook,
                              input ppc_daybook_desc,
                              input pmr_daybook,
                              input pmr_daybook_desc,
                              input pglmir_yn,                              
                              input dataset tapipostingdataiswithsaf 
                                            by-reference,
                              input-output dataset tapipostingsaf 
                                                   by-reference,
                              input-output table ttSafStrEntGLCCPrj
                                                 by-reference )"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
 
               end. /* if pItem_pm_code = "M" and  */
              /* NOn recoverable tax has to used as cost for the item purchased */    
              if nrline_tax <> 0
              then do:
                  /* create trgl_det, glt_det records */
                  {us/px/pxrun.i 
                     &PROC  = 'createTransactionDetail'
                     &PARAM = "(input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPAcct 
                                         else dftCOPAcct)
                                   else dftInvAcct,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPSub 
                                         else dftCOPSub)
                                   else dftInvSub,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPCC 
                                         else dftCOPCC)
                                   else dftInvCC,
                             input dftPPVAcct,
                             input dftPPVSub,
                             input dftPPVCC,
                             input lProject,
                             input nrline_tax /* BASE CURR AMOUNT */,
                             input 0 /* STATUTORY CURRENCY AMOUNT */,
                              input recid(tr_hist) ,
                              input pEndDate,
                              input pBaseCostset,
                              input pStatCostset,
                              input pBaseCurrency,
                              input pStatCurrency,
                              input pStatIsFallBack,
                              input pSiteEntity,
                              input ppc_calc_daybook,
                              input ppc_daybook_desc,
                              input pmr_daybook,
                              input pmr_daybook_desc,
                              input pglmir_yn,                              
                              input dataset tapipostingdataiswithsaf 
                                            by-reference,
                              input-output dataset tapipostingsaf 
                                                   by-reference,
                              input-output table ttSafStrEntGLCCPrj
                                                 by-reference )"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
 
               end. /* if nrline_tax <> 0   */

            end. /* ( pPCCostMethod = "WAVG" or
                (pPCCostMethod <> "WAVG" and tr_hist.tr_qty_loc > 0)) */
            
              
 
            
            if ( tr_hist.tr_ovh_std * tr_qty_loc <> 0 )
            then do:
               {us/px/pxrun.i 
                   &PROC  = 'createTransactionDetail'
                   &PARAM = "(input dftOVHAcct,
                           input dftOVHSub,
                           input dftOVHCC,
                           input if tr_hist.tr_ship_type = 'S'
                                 then (if luseWIPAcct 
                                       then dftWIPAcct 
                                       else dftCOPAcct)
                                 else dftInvAcct,
                           input if tr_hist.tr_ship_type = 'S'
                                 then (if luseWIPAcct 
                                       then dftWIPSub 
                                       else dftCOPSub)
                                 else dftInvSub,
                           input if tr_hist.tr_ship_type = 'S'
                                 then (if luseWIPAcct 
                                       then dftWIPCC 
                                       else dftCOPCC)
                                 else dftInvCC,
                           input lProject,
                           input (tr_hist.tr_ovh_std * tr_hist.tr_qty_loc ) 
                                  /* BASE CURRENCY AMOUNT */,
                           input 0 /* STATUTORY CURRENCY AMOUNT */,
                           input recid(tr_hist) ,
                           input pEndDate,
                           input pBaseCostset,
                           input pStatCostset,
                           input pBaseCurrency,
                           input pStatCurrency,
                           input pStatIsFallBack,
                           input pSiteEntity,
                           input ppc_calc_daybook,
                           input ppc_daybook_desc,
                           input pmr_daybook,
                           input pmr_daybook_desc,
                           input pglmir_yn,                             
                           input dataset tapipostingdataiswithsaf
                                         by-reference,
                           input-output dataset tapipostingsaf 
                                                by-reference,
                           input-output table ttSafStrEntGLCCPrj
                                              by-reference )"
                   &NOAPPERROR=true
                   &CATCHERROR=true}

                if return-value <> {&SUCCESS-RESULT}
                then return error {&APP-ERROR-RESULT}.
            
            
            end.    
            
            /* REVERSE THE AP RATE VARAIANCE AMAOUNT */
            /* We do not look for the invoice date, 
             * at the time of running PC calculation *
             * if invoice exists consider it                            */
 
            if lInvoiceExist and tr_hist.tr_type <> "RCT-LA"
            then do:
               if pod_tax_in = no and
                 ( tr_hist.tr_qty_loc * (lUnitCost - tr_hist.tr_price)) <> 0
               then do:
                  /* create trgl_det, glt_det records */
                  {us/px/pxrun.i 
                     &PROC  = 'createTransactionDetail'
                     &PARAM = "(input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPAcct 
                                         else dftCOPAcct)
                                   else dftInvAcct,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPSub 
                                         else dftCOPSub)
                                   else dftInvSub,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPCC 
                                         else dftCOPCC)
                                   else dftInvCC,
                             input dftAPVRAcct,
                             input dftAPVRSub,
                             input dftAPVRCC,
                             input lProject,
                             input (tr_hist.tr_qty_loc 
                                   * (lUnitCost - tr_hist.tr_price)) 
                             /* BASE CURRENCY AMOUNT */ ,
                             input 0  /* STATUTORY CURRENCY AMOUNT */,
                             input recid(tr_hist) ,
                             input pEndDate,
                             input pBaseCostset,
                             input pStatCostset,
                             input pBaseCurrency,
                             input pStatCurrency,
                             input pStatIsFallBack,
                             input pSiteEntity,
                             input ppc_calc_daybook,
                             input ppc_daybook_desc,
                             input pmr_daybook,
                             input pmr_daybook_desc,
                             input pglmir_yn,                             
                             input dataset tapipostingdataiswithsaf 
                                           by-reference,
                             input-output dataset tapipostingsaf 
                                                  by-reference,
                             input-output table ttSafStrEntGLCCPrj
                                          by-reference )"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
               end.
               if pod_tax_in and
                 ( (tr_hist.tr_qty_loc * lUnitCost) - (( tr_hist.tr_price * tr_hist.tr_qty_loc) + line_tax ) )   <> 0
               then do:
                  /* create trgl_det, glt_det records */
                  {us/px/pxrun.i 
                     &PROC  = 'createTransactionDetail'
                     &PARAM = "(input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPAcct 
                                         else dftCOPAcct)
                                   else dftInvAcct,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPSub 
                                         else dftCOPSub)
                                   else dftInvSub,
                             input if tr_hist.tr_ship_type = 'S'
                                   then (if luseWIPAcct 
                                         then dftWIPCC 
                                         else dftCOPCC)
                                   else dftInvCC,
                             input dftAPVRAcct,
                             input dftAPVRSub,
                             input dftAPVRCC,
                             input lProject,
                             input ( (tr_hist.tr_qty_loc * lUnitCost) - (( tr_hist.tr_price * tr_hist.tr_qty_loc) + line_tax ) )
                             /* BASE CURRENCY AMOUNT */ ,
                             input 0  /* STATUTORY CURRENCY AMOUNT */,
                             input recid(tr_hist) ,
                             input pEndDate,
                             input pBaseCostset,
                             input pStatCostset,
                             input pBaseCurrency,
                             input pStatCurrency,
                             input pStatIsFallBack,
                             input pSiteEntity,
                             input ppc_calc_daybook,
                             input ppc_daybook_desc,
                             input pmr_daybook,
                             input pmr_daybook_desc,
                             input pglmir_yn,                             
                             input dataset tapipostingdataiswithsaf 
                                           by-reference,
                             input-output dataset tapipostingsaf 
                                                  by-reference,
                             input-output table ttSafStrEntGLCCPrj
                                          by-reference )"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
               end.   
            end. /* if lInvoiceExist  */
         end.     /*  tr_qty_loc <> 0 */
 
         /* FOR SUB-CONTRACT ITEM, UPDATE THE CURRENT PERIOD
          *  SUB-CONTRACT AMOUNT AS THIS LEVEL VALUE
          *  INTO WORK ORDER ROUTING DETAIL AND WORK ORDER
          *  PERIOD BALANCE FOR BOTH BASE COSTSET AND
          *  STATUTORY COSTSET */
 
         if tr_hist.tr_ship_type = "S" /* sub contract */
         and available pod_det
         then do:
            for first wo_mstr no-lock
                where wo_mstr.wo_domain = global_domain
                  and wo_mstr.wo_lot    = pod_det.pod_wo_lot:
 
               /* FETCH THE COST OF PRODUCTION ACCOUNT */
               {us/bbi/gprun.i ""glactdft.p""
                         "(input ""WO_COP_ACCT"",
                           input pItemProdLine,
                           input pod_det.pod_site,
                           input if available vd_mstr then
                                 vd_mstr.vd_type else """",
                           input """",
                           input no,
                           output dftCOPAcct,
                           output dftCOPSub,
                           output dftCOPCC)"}
 
               /* FETCH THE SUB-CONTRACT RATE VARIANCE
                * FROM WORK ORDER MASTER  */
               assign
                  sub_rate_acct    = wo_mstr.wo_svrr_acct
                  sub_rate_sub     = wo_mstr.wo_svrr_sub
                  sub_rate_cc      = wo_mstr.wo_svrr_cc
                  dftWipAcct       = wo_mstr.wo_acct
                  dftWipSub        = wo_mstr.wo_sub
                  dftWipCC         = wo_mstr.wo_cc.
 
               for first wr_route no-lock
                   where wr_route.wr_domain = global_domain
                   and   wr_route.wr_lot    = pod_det.pod_wo_lot
                   and   wr_route.wr_op     = pod_det.pod_op:
 
                  {us/px/pxrun.i 
                     &PROC   = 'updateWoRoutePeriodDetail'
                     &PARAM  = "(input wo_mstr.oid_wo_mstr,
                                 input wr_route.oid_wr_route,
                                 input pCostCalcPeriodOID  
                                 /*CURRENT COST CALC PERIOD OID*/ ,
                                 input 0  /* SETUP HOURS */,
                                 input 0  /* LABOR HOURS */ ,
                                 input tr_hist.tr_qty_loc 
                                 /* Process QUANTITY */,
                                 buffer wopm_det,
                                 buffer wopr_det)"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
 
                  {us/px/pxrun.i 
                     &PROC='updatePctropWORoutePeriodDetail'
                     &PARAM="(input wopr_det.oid_wopr_det,
                              input wopm_det.oid_wopm_det,
                              input pBaseCostSetOID  
                              /* CURRENT PERIOD BASE COSTSET OID */,
                              input pStatCostSetOID  
                              /* CURRENT PERIOD STAT COSTSET OID */,
                              input pCostCalcPeriodOID ,
                              input pBaseCurrency ,
                              input pStatCurrency ,
                              input pStatIsFallBack, 
                              input tr_hist.tr_effdate,
                              input '{&SUBCONTRACT-ELEMENT}',
                              input lInvoiceAmt + line_tax /*THIS LEVEL*/,
                              input 0  /*LOWER LEVEL*/ )"
                     &NOAPPERROR=true
                     &CATCHERROR=true}
 
                  if return-value <> {&SUCCESS-RESULT}
                  then return error {&APP-ERROR-RESULT}.
 
                  for first op_hist no-lock
                      where op_hist.op_domain = global_domain
                      and   op_hist.op_wo_nbr = wr_nbr
                      and   op_hist.op_wo_lot = wr_lot
                      and   op_hist.op_wo_op  = wr_op
                      and   op_hist.op_po_nbr = pod_nbr
                      and   op_hist.op_part   = pod_part
                      and   op_hist.op_date   = tr_effdate
                      and   op_hist.op_type   = "SUBCNT":
 
                     lop_recno = recid(op_hist).
 
                     /* UPDATE THE  CALCULATED PERIODIC COST
                      * AMOUNT INTO op_gl_amt FIELD  */
                     {us/px/pxrun.i &PROC='updateGLAmount'
                              &PARAM="(input recid(op_hist),
                                       input 'op_hist',
                                       input (lInvoiceAmt + line_tax ),
                                       input pBaseCurrency ,
                                       input pStatCurrency ,
                                       input pStatIsFallBack ,
                                       input-output pTranscounter)"
                              &NOAPPERROR=true
                              &CATCHERROR=true}
 
                     if return-value <> {&SUCCESS-RESULT}
                     then return error {&APP-ERROR-RESULT}.
 
                     /* REVERSE BURDEN USAGE VARIANCE /
                      * LABOR USAGE VARIANCE /
                      * SUB-CONTRACT RATE VARIANCE
                      * DURING ADJUSTMENT MODE CALCULATION */
 
                     if pisAdjustmentMode
                     then do:
                        /* GET THE WO Department
                           Labor, Burden and VARIANCE ACCOUNT DETAILS  */
                        {us/px/pxrun.i &PROC    = 'getWODeptAccount'
                                 &PARAM   = "(input  op_hist.op_dept,
                                              output dftLbrAcct,
                                              output dftLbrSub,
                                              output dftLbrCc,
                                              output lbr_use_acct,
                                              output lbr_use_sub,
                                              output lbr_use_cc,
                                              output lbr_rate_acct,
                                              output lbr_rate_sub,
                                              output lbr_rate_cc,
                                              output dftBdnAcct,
                                              output dftBdnSub,
                                              output dftBdnCc,
                                              output bdn_use_acct,
                                              output bdn_use_sub,
                                              output bdn_use_cc,
                                              output bdn_rate_acct,
                                              output bdn_rate_sub,
                                              output bdn_rate_cc)"
                                 &NOAPPERROR=true
                                 &CATCHERROR=true}
 
                        if return-value <> {&SUCCESS-RESULT}
                        then return error {&APP-ERROR-RESULT}.
 
                        lStdSubAmount = 0.
 
                        for each opgl_det no-lock
                           where opgl_det.opgl_domain = global_domain
                           and   opgl_det.opgl_trnbr  = op_hist.op_trnbr:
                              if opgl_det.opgl_gl_ref begins "PC" then next.
 
                           if opgl_det.opgl_type = "SUB-2000"
                           then 
                              lStdSubAmount = lStdSubAmount 
                                            + opgl_det.opgl_gl_amt.
 
                           /* Get the variance accounts which are 
                            * in the debit side if available, then reverse 
                            * them by putting those accounts 
                            * on the credit side */
 
                           if ( opgl_det.opgl_type = "SUB-2001" or
                                opgl_det.opgl_type = "SUB-2002" )
                           then do:
                              {us/gp/gprunp.i "pcopgl" "p" "CreGltProcforOPgl"
                                       "(input opgl_det.opgl_cr_acct, 
                                         /* debit side of posting */
                                         input opgl_det.opgl_cr_sub,
                                         input opgl_det.opgl_cr_cc,
                                         input opgl_det.opgl_dr_acct, 
                                         /* credit side of posting */
                                         input opgl_det.opgl_dr_sub,
                                         input opgl_det.opgl_dr_cc,
                                         input opgl_det.opgl_gl_amt,
                                         input recid(op_hist)
                                         /* OP_HIST RECID */ ,
                                         input ?
                                         /* OPGL_DET RECID */ ,
                                         input pEndDate,
                                         input pSiteEntity,
                                         input opgl_det.opgl_type,
                                         input ppc_calc_daybook,
                                         input ppc_daybook_desc,
                                         input dataset tapipostingdataiswithsaf
                                                              by-reference,
                                         input-output dataset tApiPostingSaf 
                                                              by-reference,
                                         input-output table ttSafStrEntGLCCPrj
                                                        by-reference)"}
                           end. /* if opgl_type = SUB-2001 */
                        end.  /* each opgl_det   */
                     end.    /* pisAdjustmentMode */
 
                  end.  /* first op_hist */
 
                  lSubAmount = lInvoiceAmt + line_tax.
 
                  if pisAdjustmentMode
                  then 
                     lSubAmount = lSubAmount - lStdSubAmount.
 
                  if lSubAmount <> 0
                  then do:
                     {us/gp/gprunp.i "pcopgl" "p" "CreGltProcforOPgl"
                              "(input dftWipAcct,
                                input dftWipSub,
                                input dftWipCc,
                                input dftCopAcct,
                                input dftCopSub,
                                input dftCopCc,
                                input lSubAmount,
                                input lop_recno
                                /* OP_HIST RECID */ ,
                                input ?
                                 /* OPGL_DET RECID */ ,
                                input pEndDate,
                                input pSiteEntity,
                                input 'SUB-2000',
                                input ppc_calc_daybook,
                                input ppc_daybook_desc,                                
                                input dataset tapipostingdataiswithsaf
                                                     by-reference,
                                input-output dataset tApiPostingSaf 
                                                     by-reference,
                                input-output table ttSafStrEntGLCCPrj
                                                     by-reference)"}
                  end.
               end.   /* first wr_route      */
            end.     /* first wo_mstr       */
         end.       /* tr_ship_type = "S"  */
      end.         /* FOR EACH tr_hist    */
   end.          /* do on error undo, return error {&GENERAL-APP-EXCEPT}: */
   return {&SUCCESS-RESULT}.
END PROCEDURE.  /* POReceiptCalculation */