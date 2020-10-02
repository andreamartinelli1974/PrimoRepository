function [methodSummary]= calculateMetrics (matrix)
methodSummary.meanLO=mean(matrix.longOnlypunt)';
methodSummary.meanLS=mean(matrix.LSpunt)';
methodSummary.meanLB=mean(matrix.LBpunt)';


methodSummary.sdevLO=std(matrix.longOnlypunt)';
methodSummary.sdevLS=std(matrix.LSpunt)';
methodSummary.sdevLB=std(matrix.LBpunt)';

methodSummary.avLO=sqrt(12)*methodSummary.sdevLO;
methodSummary.avLS=sqrt(12)*methodSummary.sdevLS;

methodSummary.medianLO=median(matrix.longOnlypunt)';
methodSummary.medianLS=median(matrix.LSpunt)';
methodSummary.medianLB=median(matrix.LBpunt)';

productLO=prod(1+matrix.longOnlypunt); %row vector
methodSummary.arLO=(-1+(productLO.^(12/171)))';

productLS=prod(1+matrix.LSpunt); %row vector
methodSummary.arLS=(-1+(productLS.^(12/171)))';

productLB=prod(1+matrix.LBpunt); %row vector
methodSummary.arLB=(-1+(productLB.^(12/171)))';

methodSummary.maxarLO=max(methodSummary.arLO);
methodSummary.maxarLS=max(methodSummary.arLS);
methodSummary.maxarLB=max(methodSummary.arLB);

methodSummary.cumretLO=matrix.longOnlycum(end,:)';
methodSummary.cumretLS=matrix.LScum(end,:)';
methodSummary.cumretLB=matrix.LBcum(end,:)';

methodSummary.maxcumretLO=max(methodSummary.cumretLO);
methodSummary.maxcumretLS=max(methodSummary.cumretLS);
methodSummary.maxcumretLB=max(methodSummary.cumretLB);

methodSummary.SR_MR_LO=(methodSummary.meanLO./methodSummary.sdevLO);
methodSummary.SR_MR_LS=(methodSummary.meanLS./methodSummary.sdevLS);
methodSummary.SR_MR_LB=(methodSummary.meanLB./methodSummary.sdevLB);

methodSummary.SR_ARAV_LO=(methodSummary.arLO./sqrt(methodSummary.avLO));
methodSummary.SR_ARAV_LS=(methodSummary.arLS./sqrt(methodSummary.avLS));
methodSummary.SR_ARAV_LB=(methodSummary.arLB./sqrt(methodSummary.avLB));


end