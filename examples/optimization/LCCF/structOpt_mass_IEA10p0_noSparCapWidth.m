function structOpt_mass_IEA10p0_noSparCapWidth(blade,lb,ub,A,b,pop,gen,restartFile,useParallel)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ************************** INPUT OPTIONS ********************************
optRoutine = 'particle swarm';%'pattern search';%'genetic algorithm';%
tic

if isempty(restartFile)
    useRestartFile = false;
else
    useRestartFile = true;
end
[initPop,initScores] = setInitPop(useRestartFile,restartFile);
% % if useRestartFile
% %     options = gaoptimset( 'PopulationSize',pop,...
% %         'Generations',gen,...
% %         'InitialPopulation',initPop,...
% %         'InitialScores',initScores,...
% %         'UseParallel',useParallel,...
% %         'PlotFcns',{@gaplotbestf,@gaplotscorediversity,@gaplotbestindiv,@gaCustomPlot} );
% %     
% % % %     options = optimoptions(optRoutine,'PopulationSize',pop,'Generations',gen,...
% % % %         'InitialPopulation',initPop,'InitialScores',initScores,'UseParallel',useParallel,...
% % % %         'PlotFcns',{@gaplotbestf,@gaplotscorediversity,@gaplotbestindiv,@gaCustomPlot} );
% % else
% %     options = gaoptimset('PopulationSize',pop,...
% %         'Generations',gen,...
% %         'UseParallel',useParallel,...
% %         'PlotFcns',{@gaplotbestf,@gaplotscorediversity,@gaplotbestindiv,@gaCustomPlot} );
% %     
% % % %     options = optimoptions(optRoutine,'PopulationSize',pop,'Generations',gen,...
% % % %         'InitialPopulation',initPop,'InitialScores',initScores,'UseParallel',useParallel,...
% % % %         'PlotFcns',{@gaplotbestf,@gaplotscorediversity,@gaplotbestindiv,@gaCustomPlot} );
% % end

nVar=length(lb);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ***************** DELETE OUTPUT FROM PREVIOUS RUNS **********************
delete 'layupDesignProgress.txt'
delete 'layupDesignCandidates.txt'

delete('..\carray.mat')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ************************** RUN OPTIMIZATION *****************************
blade.mesh=0.1;

if 1 % call the optimization algorithm
    % ================== Choose Optmization Algorithm =====================
    switch optRoutine
        case 'genetic algorithm'
            % set up options for genetic algorithm
            if useRestartFile
                options = optimoptions('ga','PopulationSize',pop,'Generations',gen,...
                    'InitialPopulation',initPop,'InitialScores',initScores,'UseParallel',useParallel,...
                    'PlotFcn',{@gaplotbestf,@gaplotscorediversity,@gaplotbestindiv,@optCustomPlot} );
            else
                options = optimoptions('ga','PopulationSize',pop,'Generations',gen,...
                    'UseParallel',useParallel,...
                    'PlotFcn',{@gaplotbestf,@gaplotscorediversity,@gaplotbestindiv,@optCustomPlot} );
            end
            % call the genetic algorithm
            [x,fval,exitflag,output,population,scores] = ga(@(x)designBladeFcn(x,blade,useParallel,false),nVar,A,b,[],[],lb,ub,[],[],options);
            save gaResults x fval exitflag output population scores
            
        case 'pattern search'
            % call the pattern search algorithm
            clear options
% %             options = optimoptions('patternsearch','MaxFunEvals',1000,'Cache','on','UseParallel',true);
            maxIter = 100*nVar;  % default
            maxFunEval = 2000*nVar; % default
            options = optimoptions('patternsearch','MaxIterations',maxIter,'MaxFunctionEvaluations',maxFunEval,...
                'Cache','on','UseParallel',true,'UseVectorized', false,'PlotFcn',@psplotbestf);
            
            xo = (lb+ub)/2;
            
%             options = optimoptions('patternsearch','UseParallel', true, 'UseCompletePoll', true, 'UseVectorized', false,'MaxFunctionEvaluations',1000);
            [x,fval,exitflag,output] = patternsearch(@(x)designBladeFcn(x,blade,useParallel,false),xo,A,b,[],[],lb,ub,options);
            save patternsResults x fval exitflag output
            
        case 'particle swarm'
            % call the particle swarm algorithm
            deltaf_stop = 5; % tolerance in best case to stop optimization [kg]
            
            if 0
                options = optimoptions('particleswarm','SwarmSize',64,...
                    'UseParallel',true,'PlotFcn',{@pswplotbestf,@optCustomPlot});
            else
                options = optimoptions('particleswarm','SwarmSize',pop,'FunctionTolerance',deltaf_stop,...
                    'UseParallel',true,'PlotFcn',@pswplotbestf);
            end
            
            [x,fval,exitflag,output] = particleswarm(@(x)designBladeFcn(x,blade,useParallel,false),nVar,lb,ub,options);
            save gaResults x fval exitflag output
    end
    
else % just do manual analysis and then quit
    x=[11.44 .093 30.61 12.51 279.95 .472];
    for i=1:size(x,1)
        f(i,1) = designBladeFcn(x(i,:), blade, false, false);
        save tmp x f
    end
    disp('results summary:')
    sprintf('%i %i %i %i %i %i %.1f\n',[x f]')
end
toc
end
%%
function f = designBladeFcn(x, blade, useParallel, saveBlade)
% <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
% Change folder saving structure so that multiple workers in a parallel
% algorithm don't overwrite each other.
hm = pwd; % reference to the 'NuMad' folder in the main directory
if useParallel
    t = getCurrentTask;
    if isempty(t)
        id = '0'; % first iteration of genetic algorithm in generation
    else
        id = num2str(t.ID); % remaining population are sent to workers in parallel
    end  
    % distinct folder for each worker (will be overwritten once that worker is
    % finished and called back - MUST save important information to main
    % directory if you want to keep it.
    caseFolder = ['parallel_worker_' id];
    mkdir(['..\' caseFolder '\NuMAD'])
    mkdir(['..\' caseFolder '\wind'])
    mkdir(['..\' caseFolder '\out'])
    % if exist(['..\' caseFolder],'dir'), rmdir(['..\' caseFolder],'s'), end
    copyfile('airfoils', ['..\' caseFolder '\NuMAD\airfoils'])
    copyfile('..\AeroData', ['..\' caseFolder '\AeroData'])    
    copyfile('..\out\IECSweep_ramp.out', ['..\' caseFolder '\out\IECSweep_ramp.out'])
    copyfile('..\wind\ramp.wnd', ['..\' caseFolder '\wind\ramp.wnd'])
    copyfile('..\runIEC_ipt.m',['..\' caseFolder '\runIEC_ipt.m'])
    cd(['..\' caseFolder '\NuMAD'])
end
% >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
% Blade Design Variables and Material Properties
bladeLength = 96.7; % m
ratedRotorSpeed = 8.68; % rpm
frequency3P = ratedRotorSpeed/60 * 3; % hz
frequency6P = ratedRotorSpeed/60 * 6; % hz
% material limits -- unidirectional glass fiber, 57% Vf
strain_design_GFRP_uni = [-7900 12440];
% material limits -- Zoltek PX35 pultrusions, 68% Vf
strain_design_CFRP_PX35 = [-5670 8290];
% material limits -- CFTF Kaltex pultrusions, 68% Vf
strain_design_CFRP_K20 = [-4270 4890];

% assumes the spar cap material is same for LP and HP sides
sparCmp = find(contains({blade.components.name},'spar'));
sparMaterial = blade.materials(blade.components(sparCmp).materialid).name;
if strcmp(sparMaterial,'EUD-uni')
    sparStrainDesign_min = strain_design_GFRP_uni(1);
    sparStrainDesign_max = strain_design_GFRP_uni(2);
    fatigueMaterial = 's1_fiberglass';
elseif strcmp(sparMaterial,'CFP-baseline')
    sparStrainDesign_min = strain_design_CFRP_PX35(1);
    sparStrainDesign_max = strain_design_CFRP_PX35(2);
    fatigueMaterial = 's2_baselineCF';
elseif strcmp(sparMaterial,'CFP-heavytextile')
    sparStrainDesign_min = strain_design_CFRP_K20(1);
    sparStrainDesign_max = strain_design_CFRP_K20(2);
    fatigueMaterial = 's3_heavyTCF';
else
    error('new material used')
end

% assumes TE and LE reinforcement is fiberglass
reinfStrainDesign_min = strain_design_GFRP_uni(1);
reinfStrainDesign_max = strain_design_GFRP_uni(2);

%%%%%%%%%%%%%%%%%%%%%%%%% set targets for design %%%%%%%%%%%%%%%%%%%%%%%%%%
designcriteria.MaxOoPDefl=0.2*bladeLength; % note: not using the critical displacement partial FS (1.1)
designcriteria.MinHPStrain=sparStrainDesign_min;
designcriteria.MaxHPStrain=sparStrainDesign_max;
designcriteria.MinLPStrain=sparStrainDesign_min;
designcriteria.MaxLPStrain=sparStrainDesign_max;
designcriteria.MinEdgeStrain=reinfStrainDesign_min;
designcriteria.MaxEdgeStrain=reinfStrainDesign_max;
designcriteria.Mass = 80e3;   % kg
designcriteria.FFreq = frequency3P * 1.1;  % for 13m rotor
designcriteria.EFreq = frequency3P * 1.1;  % for 13m rotor
% designcriteria.Buckle=1.00;  % for use with final mesh
% designcriteria.Buckle=1.62;  % for use with final mesh
% designcriteria.Buckle=1.68;   % it's high because I'm using a course mesh

%%%%%%%%%%%%%%%%%%%%%%% set ga case blade properties %%%%%%%%%%%%%%%%%%%%%%
disp('Creating bladeDef and writing NMD files...')

% spar cap width
% % blade.sparcapwidth=x(1);
% % blade.sparcapwidth
% spar cap thickness
cmp=4;
blade.components(cmp).name
blade.components(cmp).cp(1,2)=x(1);
blade.components(cmp).cp(2,2)=x(2);
blade.components(cmp).cp(3,2)=x(3);
blade.components(cmp).cp(4,2)=x(4);
blade.components(cmp).cp(5,2)=x(5);
blade.components(cmp).cp(6,2)=x(5);

% update numad input file
blade.updateGeometry
blade.updateKeypoints
blade.updateBOM

BladeDef_to_NuMADfile(blade,'numad.nmd','MatDBsi.txt');

if saveBlade   % save the blade file for future use - FINAL RUN ONLY.
    save blade blade
end

%%%%%%%%%%%%%%%% call precomp and generate FAST blade file %%%%%%%%%%%%%%%%
delete bmodesFrequencies.mat
disp('Creating FAST Blade file using NuMAD and PreComp...')
% run one precomp call and generate new blade frequencies from revised
% numad.nmd input.
numad('numad.nmd','precomp',[1 3 2])
movefile('FASTBlade_Precomp.dat','..\')
disp('Newly created FAST Blade file copied to FAST simulation directory')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% **************** CHECK RELEVANT IEC DESIGN LOAD CASES *******************
disp('Checking Mass using FAST')
bladeFilename = 'FASTBlade_precomp.dat';
designvarMassPerLength=layupDesign_FASTmass_BLE(bladeFilename); 
designVar.Mass = designvarMassPerLength * bladeLength;
if designVar.Mass>designcriteria.Mass
    penalty.Mass = (designVar.Mass/designcriteria.Mass)^2;
else
    penalty.Mass = 1;
end

if 1
    disp('Checking OoP deflection using FAST')
    DLCoptions = {'1.4' '6.1'};%{'1.4' '6.1' '6.2'}
    output=layupDesign_FASTdeflection(blade,DLCoptions,useParallel);
    % calculate maximum/minimum values of interest
    numDLC=length(output);
    
    fastVarNames = {'MaxOoPDefl' 'MaxHPStrain' 'MinHPStrain' ...
        'MaxLPStrain' 'MinLPStrain' 'MaxEdgeStrain' 'MinEdgeStrain'};
    
    for jj = 1:length(fastVarNames)
        % =============== FIND EXTREME FAST DATA VALUES =============== %
        designVarName = fastVarNames{jj}; fastVar=zeros(1,numDLC);
        % add the partial safety factor for critical displacement
        if contains(designVarName,'OoPDefl')            
            FSdeflection = 1.1;
        else, FSdeflection = 1.0; 
        end
        for vv=1:length({output.(designVarName)})
            normalFS = {'1p1' '1p3' '1p4' '1p5' '2p1' '3p2' '3p3' '4p2' '5p1' '6p1' '6p3'};
            abnormalFS = {'2p2' '2p3' '6p2' '7p1'};
            % add the specified partial safety factor for loads
            % NOTE: not adding critical deflection partial safety factor
            if contains(output(vv).(designVarName).Name, normalFS)
                FSloads = 1.35; % normal safety factor (IEC 61400-1)
            elseif contains(output(vv).(designVarName).Name, abnormalFS)
                FSloads = 1.1; % abnormal safety factor (IEC 61400-1)  
                error('TEST -- not currently using this DLC')
            else
                error('design load case not recognized')
            end
            fastVar(vv)=output(vv).(designVarName).data * FSloads * FSdeflection;
        end
        if contains(designVarName,'max','IgnoreCase',1) || contains(designVarName,'ampl','IgnoreCase',1) % find maximum
            designVar.(designVarName)=max(fastVar);
            
        elseif contains(designVarName,'min','IgnoreCase',1) % find minimum
            designVar.(designVarName)=min(fastVar);
        else
            error('FAST variable name not correct')
        end
        % =============== ADD PENALTY =============== %
        penalty.(designVarName) = max(designVar.(designVarName)/designcriteria.(designVarName), 1)^2;
    end
else
    designVar.MaxOoPDefl = 999;
    penalty.MaxOoPDefl = 1;
end

if 0
    disp('Checking frequencies using NuMAD, PreComp, and BModes...')
    [~,freqs]=layupDesign_FASTmodal(blade);
    designVar.FFreq=freqs(1);
    if designVar.FFreq<designcriteria.FFreq
        penalty.FFreq = (designcriteria.FFreq/designVar.FFreq)^2;
    else
        penalty.FFreq = 1;
    end
    designVar.EFreq=freqs(2);
    if designVar.EFreq<designcriteria.EFreq
        penalty.EFreq = (designcriteria.EFreq/designVar.EFreq)^2;
    else
        penalty.EFreq = 1;
    end
else
    designVar.FFreq = 999;
    penalty.FFreq = 1;
    designVar.EFreq = 999;
    penalty.EFreq = 1;
end

if 1
    disp('Checking fatigue values using FAST')
    runFASTfatigue = 0; % flag to re-run FAST simulations    
    damage=layupDesign_FASTfatigue(blade,runFASTfatigue,useParallel);
      
    designVar.flapFatigue = max(damage.flap.(fatigueMaterial)); % spar cap fatigue only
    designVar.edgeFatigue = max(damage.edge.(fatigueMaterial));     
    penalty.flapFatigue = max(1,designVar.flapFatigue^2);
    penalty.edgeFatigue = max(1,designVar.edgeFatigue^2);
else
    designVar.flapFatigue = 999;
    designVar.edgeFatigue = 999;  
    penalty.flapFatigue = 1;
    penalty.edgeFatigue = 1;
end

% disp('Checking buckling criteria using ANSYS')
% [designvar,mass]=layupDesign_ANSYSbuckling(blade)
% designVar.Buckle=designvar(1);
% if designVar.Buckle<designcriteria.Buckle
%     penalty.Buckle = (designcriteria.Buckle/designVar.Buckle)^2;
% else
%     penalty.Buckle = 1;
% end

%%%%%%%%%%%%%%%% END check relevant IEC Design Load Cases %%%%%%%%%%%%%%%%%
delete 'master.db'
% *** {'MaxOoPDefl' 'MaxFlapStrain' 'MinFlapStrain' 'MaxEdgeStrain' 'MinEdgeStrain' } *** %

f=designVar.Mass*penalty.MaxOoPDefl*penalty.MaxHPStrain*penalty.MinHPStrain*...
    penalty.MaxLPStrain*penalty.MinLPStrain*penalty.MaxEdgeStrain*penalty.MinEdgeStrain*...
    penalty.flapFatigue;

params=[designVar.FFreq,penalty.FFreq,designVar.EFreq,penalty.EFreq,designVar.MaxOoPDefl,penalty.MaxOoPDefl,...
    designVar.MaxHPStrain,penalty.MaxHPStrain,designVar.MinHPStrain,penalty.MinHPStrain,...
    designVar.MaxLPStrain,penalty.MaxLPStrain,designVar.MinLPStrain,penalty.MinLPStrain,...
    designVar.MaxEdgeStrain,penalty.MaxEdgeStrain,designVar.MinEdgeStrain,penalty.MinEdgeStrain,...
    designVar.flapFatigue,penalty.flapFatigue,designVar.edgeFatigue,penalty.edgeFatigue,designVar.Mass,f];

% save the blade object for each iteration
save_index = 0;
while save_index < 10
    try
        save blade blade
        break
    catch
        % this file may be open outside of this worker, pause and retry
        pause(0.1)
        save_index = save_index+1;
    end
    if save_index == 10
        error('saving progress in parallel is problematic')
    end
end

% write results to layupDesignProgress.txt
cd(hm)
save_index = 0;
while save_index < 10
    try
        fid=fopen('layupDesignProgress.txt','a');
        fprintf(fid,'%s,(value/penalty),Flap Freq,%2.4f,%2.2f,Edge Freq,%2.4f,%2.2f,OoPDefl,%2.4f,%2.2f,HPStrain,%.0f,%2.2f,HPStrain,%.0f,%2.2f,LPStrain,%.0f,%2.2f,LPStrain,%.0f,%2.2f,EdgeStrain,%.0f,%2.2f,EdgeStrain,%.0f,%2.2f,Flap Fatigue,%2.6f,%2.2f,Edge Fatigue,%2.6f,%2.2f,Actual mass kg,%.0f,fitness function,%.0f\n',datestr(now),params);
        fclose(fid);
        break
    catch
        % this file may be open outside of this worker, pause and retry
        pause(0.05)
        save_index = save_index+1;
    end
    if save_index == 10
        error('saving progress in parallel is problematic')
    end
end

% write the candidate to file...
save_index = 0;
candidate_data = [f x];
while save_index < 10
    try
        fid = fopen('layupDesignCandidates.txt','a');
        fprintf(fid,'%s,fitness function,%6.0f, designVars, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f\n',datestr(now),candidate_data);
        fclose(fid);
        break
    catch
        % this file may be open outside of this worker, pause and retry
        pause(0.05)
        save_index = save_index+1;
    end
    if save_index == 10
        error('saving progress in parallel is problematic')
    end
end

    
end
%%
function [initPop,initScores] = setInitPop(useRestartFile,restartFile)

if useRestartFile
    a=load(restartFile);
    pp= a(:, 1) == a(end, 1) ;
    aa=sortrows( a(pp,:), size(a,2) );
    initPop=aa( 1:6, 2:end-1 )
    initScores=aa( 1:6, end )
else
    % manual entry
    initPop    =[];
    initScores =[];
end

end
%%
function [state, stop] = optCustomPlot(optimValues,state)
%options, state, and flag are delivered from the MATLAB genetic algorithm functions
disp('IN OPTIMIZATION CUSTOM PLOT FUNCTION...')
% state
% optimValues
% 
% % % gennum = state.Generation;
% 
stop = false; % is this needed?
% 
% switch state
%     
%     case 'init'
%         % do not save swarm
%         nplot = size(optimValues.swarm,2); % Number of dimensions
%         for i = 1:nplot % Set up axes for plot
%             subplot(nplot,1,i);
%             tag = sprintf('psoplotrange_var_%g',i); % Set a tag for the subplot
%             semilogy(optimValues.iteration,0,'-k','Tag',tag); % Log-scaled plot
%             ylabel(num2str(i))
%         end
%         xlabel('Iteration','interp','none'); % Iteration number at the bottom
%         subplot(nplot,1,1) % Title at the top
%         title('Log range of particles by component')
%         setappdata(gcf,'t0',tic); % Set up a timer to plot only when needed
%         
%     case 'iter'
%         % save the swarm
%         nplot = size(optimValues.swarm,2); % Number of dimensions
%         for i = 1:nplot
%             subplot(nplot,1,i);
%             % Calculate the range of the particles at dimension i
%             irange = max(optimValues.swarm(:,i)) - min(optimValues.swarm(:,i));
%             tag = sprintf('psoplotrange_var_%g',i);
%             plotHandle = findobj(get(gca,'Children'),'Tag',tag); % Get the subplot
%             xdata = plotHandle.XData; % Get the X data from the plot
%             newX = [xdata optimValues.iteration]; % Add the new iteration
%             plotHandle.XData = newX; % Put the X data into the plot
%             ydata = plotHandle.YData; % Get the Y data from the plot
%             newY = [ydata irange]; % Add the new value
%             plotHandle.YData = newY; % Put the Y data into the plot
%         end
%         if toc(getappdata(gcf,'t0')) > 1/30 % If 1/30 s has passed
%             drawnow % Show the plot
%             setappdata(gcf,'t0',tic); % Reset the timer
%         end
%         
        
        % write the candidate to file...
        fid = fopen('layupDesignCandidates.txt','a');
        for ii=1:size(optimValues.swarm,1)
            fprintf( fid, ' %.0f', optimValues.iteration );
            fprintf( fid, ' %f', optimValues.swarm(ii,:) );
            fprintf( fid, ' %f', optimValues.swarmfvals(ii) );
            fprintf( fid, '\r\n' );
        end
        %         fclose( fid ) ;
        %     case 'done'
%         % do nothing
% end


% optimValues = 
% 
%   struct with fields:
% 
%            bestfval: 2.2959e+04
%               bestx: [609.4776 125.7200 91.7267 89.1016 60.4185]
%           iteration: 0
%           funccount: 64
%            meanfval: 8.8377e+04
%     stalliterations: 0
%               swarm: [64�5 double]
%          swarmfvals: [64�1 double]



end
%%
function state = gaCustomPlot(options,state,flag)
%options, state, and flag are delivered from the MATLAB genetic algorithm functions

gennum = state.Generation;

% write the candidate to file...
fid = fopen('layupDesignCandidates.txt','a');
for jj=1:size(state.Population,1)
    fprintf( fid, ' %f', state.Generation );
    for ii = 1:size(state.Population,2)
        fprintf( fid, ' %f', state.Population(jj,ii) );
    end
    fprintf( fid, ' %f', state.Score(jj) );
    fprintf( fid, '\r\n' );
end
fclose( fid ) ;

end