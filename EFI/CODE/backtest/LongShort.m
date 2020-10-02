function [results]=LongShort(bestReturnComp,shortRetSimple,bmk,capitalLong,leg_weigth,isGrossEx)

results.LOcap(1)=capitalLong;
results.SOcap(1)=-capitalLong;
results.cum_pl_LO=zeros(1,length(bestReturnComp));
results.punt_pl_LO=zeros(1,length(bestReturnComp));
results.cum_pl_SO=zeros(1,length(bestReturnComp));
results.punt_pl_SO=zeros(1,length(bestReturnComp));

results.LScap(1)=capitalLong;
results.LongLeg_cap(1)=capitalLong*leg_weigth;
results.cumPL_LongLeg=zeros(1,length(bestReturnComp));
results.cumPL_ShortLeg=zeros(1,length(bestReturnComp));
results.cum_pl_LS=zeros(1,length(bestReturnComp));
results.ShortLeg_cap(1)=-capitalLong*leg_weigth;


results.LBcap(1)=capitalLong;
results.LongLegB_cap(1)=capitalLong*leg_weigth;
results.ShortLegBmk_cap(1)=-capitalLong*leg_weigth;
results.cumPL_LongLegB=zeros(1,length(bestReturnComp));
results.cumPL_ShortLegBmk=zeros(1,length(bestReturnComp)); %BMK acts as the short leg
results.cum_pl_LB=zeros(1,length(bestReturnComp));


for i=2:length(bestReturnComp)
    
    %quantità LO
    puntRet_LO=bestReturnComp(i);
    results.punt_pl_LO(i)=results.LOcap(i-1)*(1+puntRet_LO)-results.LOcap(i-1);
    results.LOcap(i)=results.LOcap(i-1)+results.punt_pl_LO(i);
    results.cum_pl_LO(i)=results.cum_pl_LO(i-1)+results.punt_pl_LO(i);
    results.cumret_LO(i)=results.cum_pl_LO(i)/abs(results.LOcap(1));
    
    %quantità SO
    puntRet_SO=-shortRetSimple(i); %positive ret
    results.punt_pl_SO(i)=results.SOcap(i-1)*(1+puntRet_SO)-results.SOcap(i-1);
    results.SOcap(i)=results.SOcap(i-1)+results.punt_pl_SO(i);
    results.cum_pl_SO(i)=results.cum_pl_SO(i-1)+results.punt_pl_SO(i);
    results.cumret_SO(i)=results.cum_pl_SO(i)/abs(results.SOcap(1));
    
    %quantita LS
    results.puntPL_LongLeg(i)=results.LongLeg_cap(i-1)*(1+puntRet_LO)-results.LongLeg_cap(i-1);
    results.puntPL_ShortLeg(i)=results.ShortLeg_cap(i-1)*(1+puntRet_SO)-results.ShortLeg_cap(i-1);
    results.cumPL_LongLeg(i)=results.cumPL_LongLeg(i-1)+results.puntPL_LongLeg(i);
    results.cumPL_ShortLeg(i)=results.cumPL_ShortLeg(i-1)+results.puntPL_ShortLeg(i);
    
    results.puntPL_LS(i)=results.puntPL_LongLeg(i)+results.puntPL_ShortLeg(i);
    results.LScap(i)=results.LScap(i-1)+results.puntPL_LS(i);
    results.LongLeg_cap(i)=results.LScap(i)*leg_weigth;
    results.ShortLeg_cap(i)=-results.LScap(i)*leg_weigth;
    
    results.cum_pl_LS(i)=results.cum_pl_LS(i-1)+results.puntPL_LS(i);
    results.puntret_LS_Gross(i)=results.puntPL_LS(i)/(abs(results.LongLeg_cap(i))+abs(results.ShortLeg_cap(i)));
    results.cumret_LS_Gross(i)=results.cum_pl_LS(i)/(abs(results.LongLeg_cap(1))+abs(results.ShortLeg_cap(1)));
    results.puntret_LS_Net(i)=results.puntPL_LS(i)/abs(results.LScap(i-1));
    results.cumret_LS_Net(i)=results.cum_pl_LS(i)/abs(results.LScap(1));
%     if leg_weigth==1 && isGrossEx==true
%         results.puntret_LS(i)=results.puntPL_LS(i)/(abs(LongLeg_cap(i))+abs(ShortLeg_cap(i)));
%         results.cumret_LS(i)=results.cum_pl_LS(i)/(abs(LongLeg_cap(1))+abs(ShortLeg_cap(1)));
%     else
%         results.puntret_LS(i)=results.puntPL_LS(i)/abs(results.LScap(i-1));
%         results.cumret_LS(i)=results.cum_pl_LS(i)/abs(results.LScap(1));
%     end
    
    
    %quantita LB
    results.puntPL_LongLegB(i)=results.LongLegB_cap(i-1)*(1+puntRet_LO)-results.LongLegB_cap(i-1);
    results.puntPL_ShortLegBmk(i)=results.ShortLegBmk_cap(i-1)*(1+bmk.totRet(i,1))-results.ShortLegBmk_cap(i-1);
    results.cumPL_LongLegB(i)=results.cumPL_LongLegB(i-1)+results.puntPL_LongLegB(i);
    results.cumPL_ShortLegBmk(i)=results.cumPL_ShortLegBmk(i-1)+results.puntPL_ShortLegBmk(i);
    
    results.puntPL_LB(i)=results.puntPL_LongLegB(i)+results.puntPL_ShortLegBmk(i);
    results.LBcap(i)=results.LBcap(i-1)+results.puntPL_LB(i);
    results.LongLegB_cap(i)=results.LBcap(i)*leg_weigth;
    results.ShortLegBmk_cap(i)=-results.LBcap(i)*leg_weigth;
    
    results.cum_pl_LB(i)=results.cum_pl_LB(i-1)+results.puntPL_LB(i);
    results.puntret_LB_Gross(i)=results.puntPL_LB(i)/(abs(results.LongLegB_cap(i))+abs(results.ShortLegBmk_cap(i)));
    results.cumret_LB_Gross(i)=results.cum_pl_LB(i)/(abs(results.LongLegB_cap(1))+abs(results.ShortLegBmk_cap(1)));
    results.puntret_LB_Net(i)=results.puntPL_LB(i)/abs(results.LBcap(i-1));
    results.cumret_LB_Net(i)=results.cum_pl_LB(i)/abs(results.LBcap(1));
    
%     if leg_weigth==1 && isGrossEx==true
%         results.puntret_LB(i)=results.puntPL_LB(i)/(abs(LongLegB_cap(i))+abs(ShortLegBmk_cap(i)));
%         results.cumret_LB(i)=results.cum_pl_LB(i)/(abs(LongLegB_cap(1))+abs(ShortLegBmk_cap(1)));
%     else
%         results.puntret_LB(i)=results.puntPL_LB(i)/abs(results.LBcap(i-1));
%         results.cumret_LB(i)=results.cum_pl_LB(i)/abs(results.LBcap(1));
%     end
    
end
end