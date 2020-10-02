function [scoreTable,scoreT]= calculateScore(summary1,summary2,summary3,summary4,summary5,summary6,summary7,summary8)


meanMatrixLO=[summary1.meanLO,summary2.meanLO,summary3.meanLO,summary4.meanLO,summary5.meanLO,...
             summary6.meanLO,summary7.meanLO,summary8.meanLO];

scoreTable.Mean=scorecalc(meanMatrixLO);


medianMatrixLO=[summary1.medianLO,summary2.medianLO,summary3.medianLO,summary4.medianLO,summary5.medianLO,...
            summary6.medianLO,summary7.medianLO,summary8.medianLO];        
scoreTable.Median=scorecalc(medianMatrixLO);


arMatrixLO=[summary1.arLO,summary2.arLO,summary3.arLO,summary4.arLO,summary5.arLO,...
            summary6.arLO,summary7.arLO,summary8.arLO]; 
        
scoreTable.ArLO=scorecalc(arMatrixLO);   

meanMatrixLS=[summary1.meanLS,summary2.meanLS,summary3.meanLS,summary4.meanLS,summary5.meanLS,...
             summary6.meanLS,summary7.meanLS,summary8.meanLS];
scoreTable.MeanLS=scorecalc(meanMatrixLS);


medianMatrixLS=[summary1.medianLS,summary2.medianLS,summary3.medianLS,summary4.medianLS,summary5.medianLS,...
            summary6.medianLS,summary7.medianLS,summary8.medianLS];        
scoreTable.MedianLS=scorecalc(medianMatrixLS);


arMatrixLs=[summary1.arLS,summary2.arLS,summary3.arLS,summary4.arLS,summary5.arLS,...
            summary6.arLS,summary7.arLS,summary8.arLS]; 
        
scoreTable.ArLS=scorecalc(arMatrixLs);   

lastMatrixLO=[summary1.cumretLO,summary2.cumretLO,summary3.cumretLO,summary4.cumretLO,summary5.cumretLO,...
            summary6.cumretLO,summary7.cumretLO,summary8.cumretLO];
scoreTable.cumretLO=scorecalc(lastMatrixLO);


lastMatrixLS=[summary1.cumretLS,summary2.cumretLS,summary3.cumretLS,summary4.cumretLS,summary5.cumretLS,...
            summary6.cumretLS,summary7.cumretLS,summary8.cumretLS];
scoreTable.cumretLS=scorecalc(lastMatrixLS);


SR_MR_MatrixLO =[summary1.SR_MR_LO,summary2.SR_MR_LO,summary3.SR_MR_LO,summary4.SR_MR_LO,summary5.SR_MR_LO,...
            summary6.SR_MR_LO,summary7.SR_MR_LO,summary8.SR_MR_LO];
scoreTable.SR_MR_LO=scorecalc(SR_MR_MatrixLO);

SR_MR_MatrixLS =[summary1.SR_MR_LS,summary2.SR_MR_LS,summary3.SR_MR_LS,summary4.SR_MR_LS,summary5.SR_MR_LS,...
            summary6.SR_MR_LS,summary7.SR_MR_LS,summary8.SR_MR_LS];
scoreTable.SR_MR_LS=scorecalc(SR_MR_MatrixLS);

SR_ARAV_MatrixLO =[summary1.SR_ARAV_LO,summary2.SR_ARAV_LO,summary3.SR_ARAV_LO,summary4.SR_ARAV_LO,summary5.SR_ARAV_LO,...
            summary6.SR_ARAV_LO,summary7.SR_ARAV_LO,summary8.SR_ARAV_LO];
scoreTable.SR_ARAV_LO=scorecalc(SR_ARAV_MatrixLO);

SR_ARAV_MatrixLS =[summary1.SR_ARAV_LS,summary2.SR_ARAV_LS,summary3.SR_ARAV_LS,summary4.SR_ARAV_LS,summary5.SR_ARAV_LS,...
            summary6.SR_ARAV_LS,summary7.SR_ARAV_LS,summary8.SR_ARAV_LS];
scoreTable.SR_ARAV_LS=scorecalc(SR_ARAV_MatrixLS);


maxReturn_MatrixLO =[summary1.maxcumretLO,summary2.maxcumretLO,summary3.maxcumretLO,summary4.maxcumretLO,summary5.maxcumretLO,...
            summary6.maxcumretLO,summary7.maxcumretLO,summary8.maxcumretLO];
scoreTable.maxcumretLO=scorecalc(maxReturn_MatrixLO);

maxReturn_MatrixLS =[summary1.maxcumretLS,summary2.maxcumretLS,summary3.maxcumretLS,summary4.maxcumretLS,summary5.maxcumretLS,...
            summary6.maxcumretLS,summary7.maxcumretLS,summary8.maxcumretLS];
scoreTable.maxcumretLS=scorecalc(maxReturn_MatrixLS);


maxAR_MatrixLO =[summary1.maxarLO,summary2.maxarLO,summary3.maxarLO,summary4.maxarLO,summary5.maxarLO,...
            summary6.maxarLO,summary7.maxarLO,summary8.maxarLO];
scoreTable.maxarLO=scorecalc(maxAR_MatrixLO);

maxAR_MatrixLS =[summary1.maxarLS,summary2.maxarLS,summary3.maxarLS,summary4.maxarLS,summary5.maxarLS,...
            summary6.maxarLS,summary7.maxarLS,summary8.maxarLS];
scoreTable.maxarLS=scorecalc(maxAR_MatrixLS);


meanMatrixLB=[summary1.meanLB,summary2.meanLB,summary3.meanLB,summary4.meanLB,summary5.meanLB,...
             summary6.meanLB,summary7.meanLB,summary8.meanLB];
scoreTable.MeanLB=scorecalc(meanMatrixLB);


medianMatrixLB=[summary1.medianLB,summary2.medianLB,summary3.medianLB,summary4.medianLB,summary5.medianLB,...
            summary6.medianLB,summary7.medianLB,summary8.medianLB];        
scoreTable.MedianLB=scorecalc(medianMatrixLB);


arMatrixLB=[summary1.arLB,summary2.arLB,summary3.arLB,summary4.arLB,summary5.arLB,...
            summary6.arLB,summary7.arLB,summary8.arLB]; 
        
scoreTable.ArLB=scorecalc(arMatrixLB);   

lastMatrixLB=[summary1.cumretLB,summary2.cumretLB,summary3.cumretLB,summary4.cumretLB,summary5.cumretLB,...
            summary6.cumretLB,summary7.cumretLB,summary8.cumretLB];
scoreTable.cumretLB=scorecalc(lastMatrixLB);


SR_MR_MatrixLB =[summary1.SR_MR_LB,summary2.SR_MR_LB,summary3.SR_MR_LB,summary4.SR_MR_LB,summary5.SR_MR_LB,...
            summary6.SR_MR_LB,summary7.SR_MR_LB,summary8.SR_MR_LB];
scoreTable.SR_MR_LB=scorecalc(SR_MR_MatrixLB);


SR_ARAV_MatrixLB =[summary1.SR_ARAV_LB,summary2.SR_ARAV_LB,summary3.SR_ARAV_LB,summary4.SR_ARAV_LB,summary5.SR_ARAV_LB,...
            summary6.SR_ARAV_LB,summary7.SR_ARAV_LB,summary8.SR_ARAV_LB];
scoreTable.SR_ARAV_LB=scorecalc(SR_ARAV_MatrixLB);


maxReturn_MatrixLB =[summary1.maxcumretLB,summary2.maxcumretLB,summary3.maxcumretLB,summary4.maxcumretLB,summary5.maxcumretLB,...
            summary6.maxcumretLB,summary7.maxcumretLB,summary8.maxcumretLB];
scoreTable.maxcumretLB=scorecalc(maxReturn_MatrixLB);


maxAR_MatrixLB =[summary1.maxarLB,summary2.maxarLB,summary3.maxarLB,summary4.maxarLB,summary5.maxarLB,...
            summary6.maxarLB,summary7.maxarLB,summary8.maxarLB];
scoreTable.maxarLB=scorecalc(maxAR_MatrixLB);

scoreT=table(scoreTable.Mean,scoreTable.Median,scoreTable.ArLO,scoreTable.MeanLS,scoreTable.MedianLS,scoreTable.ArLS,...
             scoreTable.cumretLO,scoreTable.cumretLS,scoreTable.SR_MR_LO, scoreTable.SR_MR_LS,scoreTable.SR_ARAV_LO,scoreTable.SR_ARAV_LS,scoreTable.maxcumretLO,scoreTable.maxcumretLS)
end