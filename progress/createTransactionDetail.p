PROCEDURE createTransactionDetail:
/*------------------------------------------------------------------------------
Purpose:       Creation of glt_det and trgl_det record
 
Parameters:
          Input - Debit Account
                  Debit Sub Account
                  Debit Cost Center
                  Credit Account
                  Credit Sub Account
                  Credit Cost Center
                  Project
                  Base Currency Amount
                  Statutoy Currency Amount
                  Transaction History Recid
                  Effective Date
                  Base Cost Set
                  STATUTORY Cost Set
                  Base Currency
                  Statutory Currency
                  StatIsFallBack
                  Site Entity
                  Dataset(tapipostingdataiswithsaf)
         Input-Output - Dataset(tApiPostingSaf)
                        temp-table ttSafStrEntGLCCPrj
 
 
 
Exceptions:
Conditions:
       Pre:   NONE
      Post:   NONE
Notes:
History:
------------------------------------------------------------------------------*/
 
   define input parameter pDebitAcct             as character    no-undo.
   define input parameter pDebitSub              as character    no-undo.
   define input parameter pDebitCC               as character    no-undo.
   define input parameter pCreditAcct            as character    no-undo.
   define input parameter pCreditSub             as character    no-undo.
   define input parameter pCreditCC              as character    no-undo.
   define input parameter pProject               as character    no-undo.
   define input parameter pBaseCurrencyAmt       like trgl_det.trgl_gl_amt	no-undo.
   define input parameter pStatutoryCurrencyAmt	 like trgl_det.trgl_gl_amt	no-undo.
   define input parameter pTrHistRecid           as recid        no-undo.
   define input parameter pEffDate               as date         no-undo.
   define input parameter pBaseCostSet           as character    no-undo.
   define input parameter pStatCostSet           as character    no-undo.
   define input parameter pBaseCurrency          as character    no-undo. 
   define input parameter pStatCurrency          as character    no-undo. 
   define input parameter pStatIsFallBack        as logical      no-undo. 
   define input parameter pSiteEntity         	 as character    no-undo.
   define input parameter ppc_calc_daybook  like glt_dy_code    no-undo.
   define input parameter ppc_daybook_desc  like dy_desc        no-undo.
   define input parameter pmr_daybook       like glt_dy_code    no-undo.
   define input parameter pmr_daybook_desc  like dy_desc        no-undo.
   define input parameter pglmir_yn      like mfc_logical       no-undo.
   define input parameter dataset for tapipostingdataiswithsaf.
   define input-output parameter dataset for tApiPostingSaf.
   define input-output parameter table for ttSafStrEntGLCCPrj.
 
 
 
   define variable lTrglDetRecid              as recid     no-undo.
 
   do on error undo, return error {&GENERAL-APP-EXCEPT}:
      if pBaseCurrencyAmt = 0 and pStatutoryCurrencyAmt = 0 
      then return {&SUCCESS-RESULT}.
      {us/px/pxrun.i &PROC  = 'createTrglRecords'
               &PARAM = "(input pDebitAcct,
                          input pDebitSub,
                          input pDebitCC,
                          input pCreditAcct,
                          input pCreditSub,
                          input pCreditCC,
                          input pProject,
                          input pBaseCurrencyAmt,
                          input pBaseCurrency ,
                          input pStatCurrency ,
                          input pStatIsFallBack ,
                          input pTrHistRecid ,
                          output lTrglDetRecid)"
               &NOAPPERROR=true
               &CATCHERROR=true}
 
      if return-value <> {&SUCCESS-RESULT} then
      return error {&APP-ERROR-RESULT}.
 
      {us/px/pxrun.i &PROC  = 'createGltRecords'
               &PARAM = "(input pTrHistRecid,
                          input lTrglDetRecid,
                          input pSiteEntity,
                          input pEffDate,
                          input pStatutoryCurrencyAmt,
                          input pBaseCurrency ,
                          input pStatCurrency ,
                          input pStatIsFallBack ,
                          input ppc_calc_daybook,
                          input ppc_daybook_desc,
                          input pmr_daybook,
                          input pmr_daybook_desc,
                          input pglmir_yn,                          
                          input dataset tapipostingdataiswithsaf by-reference,
                          input-output dataset tapipostingsaf by-reference,
                          input-output table ttSafStrEntGLCCPrj by-reference)"
               &NOAPPERROR=true
               &CATCHERROR=true}
			if return-value <> {&SUCCESS-RESULT} then
      return error {&APP-ERROR-RESULT}.
 
   end. /* do on error undo, return error {&GENERAL-APP-EXCEPT}: */
   return {&SUCCESS-RESULT}.
END PROCEDURE. /* createTransactionDetail */