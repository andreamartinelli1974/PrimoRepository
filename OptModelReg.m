classdef OptModelReg < handle
    % class to implement a baynesian approach to the optimization of a
    % multilinear regression for an hedge fund
   
    properties
        
        InputDates;
        InputArray;
        InputNames;
        ModelMTX; % Logical Matrix for the different models
        Rolling; % rolling window for the first regression
        Rolling2; % rolling window for the baynesian optimisation
        ModelWeights; % matrix with the optimal weights for any models
        TableRet; % the table of returns of the regressors and the fund (last column)
        Betas; % cube of the betas. first column is the alpha.
        RollReg; % obj HFRollingReg. MAYBE UNNECESSARY
        Output; % obj HFRegresOPT: result of the optimized regression
        
       
    end
    
    methods
        
        function obj=OptModelReg(parameters) %Constructor
            obj.InputDates = params.inputdates;
            obj.InputArray = params.inputarray;
            obj.InputNames = params.inputnames;
            obj.Rolling=double(parameters.rolling);
            obj.Rolling2=double(parameters.rolling2);
        end
        
        function OpRegression(obj)
            
            params.inputdates = obj.InputDates;
            params.inputarray = obj.InputArray;
            params.inputnames = obj.InputNames;
            
            %create a HFRollingReg object 
            obj.RollReg=HFRollingReg(params,obj.Rolling);
            
            %get the Table with regressors and fund returns
            obj.RollReg.GetTableRet;
            obj.TableRet=obj.RollReg.Output;
            
            %create the logical matrix with the regressors to use in any
            %regression
            A=obj.RollReg.getMtxPredictors(obj,1,'strategy');
            B=obj.RollReg.getMtxPredictors(obj,1,'correlation');
            lowcorrelregressors=find(B(end,:));
            obj.ModelMTX=A(:,lowcorrelregressors);
            
            % with the MTXRollReg method of the HFRollingReg object create
            % the array of the betas with 3 dimensions:
            % time,regressors and regressors strategy
            obj.RollReg.MTXRollReg(obj.ModelMTX);
            obj.RollReg.GetBetas;
            obj.Betas=obj.RollReg.Output;
            
            if size(obj.TableRet,1)-(obj.Rolling+obj.Rolling2)+1<=0
                    ME=MException('myComponent:dateError','la finestra di rolling � troppo lunga');
                    throw(ME)
            end
            
            %calculate B*ft, g this are the values for the t-student-like
            %distributions used to evaluate the goodness of any strategy
            %regression
            for k=1:size(obj.TableRet,1)-(obj.Rolling+obj.Rolling2)+1 % cycle on rolling window
                for i=1:obj.Rolling2 % cycle on checking window
                    for j=1:size(obj.Betas,3) % cycle on regressors startegies
                        l=i+k-1;
                        
                        regressors1=table2array(obj.TableRet(obj.Rolling+l,2:end-1));
                        filter=find(obj.ModelMTX(j,:));
                        ft=regressors1(:,filter);
                        
                        regressors2=table2array(obj.TableRet(l:obj.Rolling+l-1,2:end-1));
                        Ft=regressors2(:,filter);
                        
                        g=1-ft/(Ft'*Ft+ft'*ft)*ft';
                        nu=obj.Rolling-size(ft,2);
                        Bft=table2array(obj.TableRet(l+obj.Rolling,2:end-1))*(obj.Betas(l,3:end,j))'+(obj.Betas(l,2,j));
                        h=(g*nu)/(table2array(obj.TableRet(l+obj.Rolling,end))-Bft)^2;
                        
                        % this is the score assigned to any strategy
                        % regression to weight the goodness of the
                        % estimated beta
                        logscore(i,j)=tpdf(sqrt(h)*(table2array(obj.TableRet(l+obj.Rolling,end))-Bft),nu)*sqrt(h);
                        lsnan=isnan(logscore);
                        lsnan=find(lsnan==1);
                        logscore(lsnan)=0;
                   
                    end
                end
                
                % optimization (using the logscore of any strategy
                % regression in the checking window)
                fun=@(x)-sum(log(logscore*x'));
                lb=zeros(1,size(obj.Betas,3));
                ub=ones(1,size(obj.Betas,3));
                constr=@norma;
                x0=ub/size(obj.Betas,3);
                
                %this is the optimization:
                obj.ModelWeights(k,:)=fmincon(fun,x0,[],[],[],[],lb,ub,constr);
                % a=[k,size(obj.TableRet,1)-(obj.Rolling+obj.Rolling2)+1];
            end
            
            % create the matrix of the betas weighted with the optimizer
            weightedBetas=zeros(size(obj.ModelWeights,1),size(obj.Betas,2)-1);
            for j=1:size(obj.Betas,3)   
                % weightedBetas=weightedBetas+obj.Betas(obj.Rolling2+1:end,2:end,j).*obj.ModelWeights(:,j);     
                
                rmatrix  = repmat(obj.ModelWeights(:,j),1,size(obj.Betas,2)-1);
                weightedBetas=weightedBetas+obj.Betas(obj.Rolling2+1:end,2:end,j).*rmatrix;
            end
            
            % cut the betas belows 10e-4 (to simplify the results)
            x=find(abs(weightedBetas)<=0.0001);
            weightedBetas(x)=0;
            betas=array2table([obj.TableRet(obj.Rolling+obj.Rolling2:end,1).date,weightedBetas],'VariableNames',['Dates','Intercept',{obj.TableRet.Properties.VariableNames{2:end-1}}]);
            
            % create a HFOptReg object (a subclass of HFRegression to be
            % used by the HedgeFund object to build the backtest track
            % record
            inputs.fund=obj.Fund;
            inputs.Indices=obj.Regressors;
            roll=obj.Rolling+obj.Rolling2;
            obj.Output=HFOptReg(inputs,roll,betas,obj.TableRet);
            
        end
        
    end
    
end

%%*********************************************************************
%  SIMPLE NORM FUNCTION TO BE USED IN THE OPTIMIZATION
function [c,ceq]=norma(x)
    c=sum(x)-1;
    ceq=[];
end

%%*********************************************************************