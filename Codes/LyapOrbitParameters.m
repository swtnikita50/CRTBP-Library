%{
...
Created on  30/6/2022 18:47
taken from Karthi and then modified on 30/6/2022.
added energy sensitivity to the function on 30/6/2022

This File does the continuation and gets all the Lyapunov orbit parameters.

Inputs
------
1) UserDat - Supplied UserData in main file.
2) G_var   - Global data.
3) e       - specified jacobianContant

Outputs
--------
1) LyapOrb - A structure containing 
                - time      - full time period for lyapunov orbit.
                - IC        - Initial Conditions for Lyapunov Orbit.
                - Energy    - Energy Value for Lyapunov Orbit.
                - Monodromy - Monodromy matrix of Lyapunov Orbit.
                - Eigens    - Eigen Values and Eigen Vectors for Lyapunov Orbit.
                                    - Stable,Unstable and Center Eigen Values
                                    - Stable,Unstable and Center Eigen Vectors

Note that the size of eigen values and eigen vectors might change

Dependencies
------------
1) InitialGuess(PointLoc,G_var)
2) DiffCorrec(X_Guess,Plot,G_var)
                        

Reference for continuation 
--------------------------
1) Wang Sang Koon, Martin W Lo,JE Marsden, Shane D Ross - "Dynamical
   Systems,the Three Body Problem and Space Mission Design", 2011
...
%}
function [LyapOrb] = LyapOrbitParameters(UserDat,G_var,e)
% Extract the parameters
CorrecPlot = UserDat.CorrectionPlot;
EqPoint = UserDat.PointLoc;
mu = G_var.Constants.mu;
funVarEq = G_var.IntFunc.VarEqAndSTMdot;

[XGuessL] = InitialGuess(EqPoint,G_var);

switch EqPoint
    case 1
        eMax = G_var.LagPts.Energy.L1;
    case 2
        eMax = G_var.LagPts.Energy.L2;
    case 3
        eMax = G_var.LagPts.Energy.L3;
end

isOrbitFound = 1;

if e > eMax
    fprintf(']\n===============================================\n')
    fprintf('Error: The jacobian(energy) value enetered is more than the maximum limit for the Libration Point\n')
    fprintf('===============================================\n');
    isOrbitFound = 0;
else
end
for guess = 1:2
    fprintf('\n===============================================\n')
    fprintf('Obtaining the Corrected Values for guess:- %d\n',guess)
    fprintf('===============================================\n')
    [tCorrec(guess,1),xCorrec(guess,:),~] = DiffCorrec(XGuessL(guess,:),CorrecPlot,G_var);
    Energy(guess,1) = jacobiValue3D(xCorrec(guess,:),mu);
end

tol = 1e-6;
family = 3;
eMin = 2.6;

if e > Energy(1)
    xSubs(1,:) = xCorrec(1,:); tSubs(1,1) = tCorrec(1,1); EnergySubs(1,1) = Energy(1,1);
    xCorrec(1,:) = xCorrec(2,:); tCorrec(1,1) = tCorrec(2,1); Energy(1,1) = Energy(2,1);
    xCorrec(2,:) = xSubs(1,:); tCorrec(2,1) = tSubs(1,1); Energy(2,1) = EnergySubs(1,1);
    while Energy(family-1) < e 
    fprintf('\nObtaining the Corrected Values for guess:- %d\n',family);

    delta = (xCorrec(family-1,:) - xCorrec(family-2,:))/2;
    GuessX = xCorrec(family-1,:) + delta;
    [~,~,~,isMaxIterReached] = DiffCorrec(GuessX,CorrecPlot,G_var);
    while isMaxIterReached
        delta = delta/2;
        GuessX = xCorrec(family-1,:) + delta;
        [~,~,~,isMaxIterReached] = DiffCorrec(GuessX,CorrecPlot,G_var);
    end
    [tCorrec(family,1),xCorrec(family,:),~,~] = DiffCorrec(GuessX,CorrecPlot,G_var);
    Energy(family,1) = jacobiValue3D(xCorrec(family,:),mu);
    if abs(Energy(family)-Energy(family-1)) < tol
        disp('\n Error: The energy difference is negligible. \n');
        isOrbitFound = 0;
        break;
    end
    family = family+1;
    end
    xCorrecLowerAmp(1,:) = xCorrec(end,:); tCorrecLowerAmp(1,1) = tCorrec(end,1); EnergyLowerAmp(1,1) = Energy(end,1);
    xCorrecUpperAmp(1,:) = xCorrec(end-1,:); tCorrecUpperAmp(1,1) = tCorrec(end-1,1); EnergyUpperAmp(1,1) = Energy(end-1,1);
elseif e < Energy(2)
% Check if e is between these two energies
%% Start Continuation
while Energy(family-1) > e
    fprintf('\n Obtaining the Corrected Values for guess:- %d\n',family);
    if e < eMin
        fprintf('\nError: Energy input is less than the %d.\n',eMin);
        isOrbitFound = 0;
        break;
    end

    delta = (xCorrec(family-1,:) - xCorrec(family-2,:));
    GuessX = xCorrec(family-1,:) + delta;
    [~,~,~,isMaxIterReached] = DiffCorrec(GuessX,CorrecPlot,G_var);
    while isMaxIterReached
        delta = delta/2;
        GuessX = xCorrec(family-1,:) + delta;
        [~,~,~,isMaxIterReached] = DiffCorrec(GuessX,CorrecPlot,G_var);
    end
    [tCorrec(family,1),xCorrec(family,:),~,~] = DiffCorrec(GuessX,CorrecPlot,G_var);
    Energy(family,1) = jacobiValue3D(xCorrec(family,:),mu);
    if abs(Energy(family)-Energy(family-1)) < tol
        disp('\n Error: The energy difference is negligible. \n');
        isOrbitFound = 0;
        break;
    end
    family = family+1;
end
xCorrecLowerAmp(1,:) = xCorrec(end-1,:); tCorrecLowerAmp(1,1) = tCorrec(end-1,1); EnergyLowerAmp(1,1) = Energy(end-1,1);
    xCorrecUpperAmp(1,:) = xCorrec(end,:); tCorrecUpperAmp(1,1) = tCorrec(end,1); EnergyUpperAmp(1,1) = Energy(end,1);
end

switch isOrbitFound
    case 1
        fprintf('\n===============================================\n')
        fprintf('Found IC for orbit with energy lesser than and greater than %d\n',e)
        fprintf('===============================================\n')


        tol = 1e-10;
        eNew = EnergyUpperAmp(1,1);
        while abs(eNew-e)>tol
            delta = (xCorrecUpperAmp(1,:) - xCorrecLowerAmp(1,:))/2;
            GuessX = xCorrecLowerAmp(1,:) + delta;

            [tNew,xNew,~] = DiffCorrec(GuessX,CorrecPlot,G_var);
            eNew = jacobiValue3D(xNew,mu);
            % CHECK eNew with e and update in xcorrec and everywhere
            if eNew>e
                xCorrecLowerAmp(1,:) = xNew;
                tCorrecLowerAmp(1,1) = tNew;
                EnergyLowerAmp(1,1) = eNew;
                %idx = (length(tCorrec))-1;
            else
                xCorrecUpperAmp(1,:) = xNew;
                tCorrecUpperAmp(1,1) = tNew;
                EnergyUpperAmp(1,1) = eNew;
                %idx = (length(tCorrec));
            end
        end

        [~,Monodromy,~,~] = StateTransAndX(G_var,xNew,funVarEq,tNew);
        [Eigens.S_EigVal,Eigens.US_EigVal,Eigens.C_Val,Eigens.S_EigVec,...
            Eigens.US_EigVec,Eigens.C_EigVec] = CalcEigenValVec(Monodromy,1) ;
        StabilityIdx = CalcStabilityIdx(Eigens);
        LyapOrb.time      = tNew; %(NoofFam x 1) - Full Orbit Time
        LyapOrb.IC        = xNew; %(NoofFam x UserDat.Dimension)
        LyapOrb.Energy    = eNew;
        LyapOrb.Monodromy = Monodromy;
        LyapOrb.Eigens    = Eigens;
        LyapOrb.StabilityIdx = StabilityIdx;
    case 0

        if e > eMax
            fprintf('\n===============================================\n')
            fprintf('Error: The jacobian(energy) value enetered is greater than the maximum limit for the Libration Point\n')
            fprintf('===============================================\n');
        else
            fprintf('\nError: Energy input is less than the %d.\n',Energy(end));
        end
        clear LyapOrb;
        LyapOrb = -1;
end

