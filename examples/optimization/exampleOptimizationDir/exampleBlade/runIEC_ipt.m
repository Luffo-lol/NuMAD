%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%params.fstfn= 'IEC_IEA10p0-198-mk0p4-s0p0';   % without .fst
params.fstfn= 'BAR_FAST_MAIN_BD';
%params.fstfn= 'BAR_FAST_MAIN_ED';
params.numadfn='NuMAD\numad.nmd';    % full path, including extension
params.fastsim = 'fast';%'fast simulink';%'adams';%
params.simulinkModel = '';
params.simulinkModelFolder = '';
params.operatingPoints=[3 12 25];  % cutin ratedspeed cutout
params.ws=[3:2:25];%warning('ble: [5:2:23];')  % range of mean wind speeds for turbulent simulations
%params.avgws = 10;
params.wd=[180]; % range of "wind direction" bias for look-up table simulations - programmed as yaw position
params.yaw = [0];    % intentional yaw misalignment, degrees (for DLC 1.1)
params.momentMaxRotation = 45;  % [deg] The angular discretization for coordinate rotation and maxima moment calculation (used for fatigue and ultimate)
params.ratedSpeed=12; % rpm
params.lin=params.operatingPoints(1):1:params.operatingPoints(3);  % range of steady wind speeds for linearizations
% params.lin=10;  % range of steady wind speeds for linearizations
params.fast_path='C:\DesignCodes\FAST_v7.02.00d\FAST.exe';
params.adams_path='call adams08r1 ru-user C:\DesignCodes\Compile_brr\FASTdll_AD_ADAMS\ADAMS08r1.dll';
params.turbsim_path='C:\DesignCodes\TurbSim_v1.50\TurbSim.exe';
params.iecwind_path='C:\DesignCodes\IECWind\IECWind.exe';
params.crunch_path='C:\DesignCodes\Crunch_v3.00.00\Crunch.exe';
params.mbc_path='C:\DesignCodes\MBC_v1.00.00a\Source';
params.sf_fat=1.380; % total fatigue safety factor
params.sf_uts=1.755; % total ultimate strength safety factor
params.sf_tow=1.755; % total tower clearance safety factor
params.numSeeds=6;%warning('ble: 6;')  % number of seeds - number of 10-minute simulations - for turbulent simulations
params.delay=29;  % throw away this much simulated data at the beginning of each simulation (turbulent and otherwise)
params.SimTime=params.delay+600;%warning('ble: params.delay+600;')  % total simulation time needed
params.NumGrid=10;%warning('ble: [10]')  % number of grid points in turbsim 4-D wind field
params.Class=3; % turbine class: 1,2,3
params.TurbClass='C';  % turbulence class: A,B,C
params.designLife = 30;             % years of life
params.BldGagNd=[1,2,3,4,5,6,7];  % vector of length 7; blade gage nodes (corresponding to aerodyn nodes) for moment (strain) gages in FAST computations 
params.fatigueCriterion = 'Shifted Goodman';

switch params.Class
    case 1
        params.avgws=0.2*50; % m/s, average wind speed of IEC Class I site (Vref=50m/s); IEC Section 6.3.1.1 Eqn (9)
    case 2
        params.avgws=0.2*42.5; % m/s, average wind speed of IEC Class II site (Vref=42.5m/s); IEC Section 6.3.1.1 Eqn (9)
    case 3
        params.avgws=0.2*37.5; % m/s, average wind speed of IEC Class III site (Vref=37.5m/s); IEC Section 6.3.1.1 Eqn (9)
end

% Material properties for fatigue analyses
matData(1).Name='s1-fiberglass';
matData(1).E=42.8e9;
matData(1).m=10;  % from GL standard for uni-directional, epoxy laminate construction
matData(1).Sk=[-637e6 1002e6]; % characteristic material strength [UCS UTS] (95%/95%, NOT FS factored)
matData(1).gamma_ms = 1.88; % from DNV-GL standard, short term strength reduction factor
matData(1).gamma_mf = 1.96; % from DNL-GL standard, fatigue strength reduction factor
matData(2).Name='s2-baselineCF';
matData(2).E=157.6e9;
matData(2).m=16.1;  % from GL standard for CFP, epoxy matrix
matData(2).Sk=[-1528e6 2236e6]; % characteristic material strength (95%/95%, NOT FS factored)
matData(2).gamma_ms = 1.71; % from DNV-GL standard, short term strength reduction factor
matData(2).gamma_mf = 1.78; % from DNL-GL standard, fatigue strength reduction factor
matData(3).Name='s3-heavyTCF';
matData(3).E=160.6e9;
matData(3).m=45.4;  % from GL standard for uni-directional, epoxy laminate construction
matData(3).Sk=[-1172e6 1345e6]; % characteristic material strength (95%/95%, NOT FS factored)
matData(3).gamma_ms = 1.71; % from DNV-GL standard, short term strength reduction factor
matData(3).gamma_mf = 1.78; % from DNL-GL standard, fatigue strength reduction factor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pause(10)