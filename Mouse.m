classdef Mouse < handle
    %MOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        CONST_FOLDER_DELIMITER = "\";
        
        CONST_MOUSE_SAVE_PATH = "W:\shared\Timna\Gal Projects\Mice";
        CONST_RAW_FILE_PATH = "\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig";
        
        CONST_DATA_BY_CLOUD = "CueInCloud_comb_cloud.mat";
        CONST_DATA_BY_CUE = "CueInCloud_comb_cue.mat";
        CONST_DATA_BY_LICK = "CueInCloud_comb_lick.mat";
        CONST_DATA_BY_MOVEMENT = "CueInCloud_comb_movement.mat";
        CONST_DATA_BY_ONSET = "CueInCloud_comb_t_onset.mat";
        
        CONST_PASSIVE_DATA = "passive\Passive_comb.mat";
        
        CONST_TASK_TRIAL_TIME = 20;
        CONST_PASSIVE_TRIAL_TIME = 5;
    end
    
    properties
        Name
        GcampJrGecoReversed
        ObjectPath
        
        RawMatFile
        Info
        ProcessedRawData
    end
    
    methods
        %========== Constructor Functions ==========
        function obj = Mouse(name, gcampJrGecoReversed, listType)
            % MOUSE Construct an instance of this class
            obj.Name = name;
            obj.GcampJrGecoReversed = gcampJrGecoReversed;
            obj.ObjectPath = obj.CONST_MOUSE_SAVE_PATH + obj.CONST_FOLDER_DELIMITER + name + ".mat" ;
            
            obj.createMatFiles();
            obj.createTaskInfo();
            obj.straightenTaskData();
            obj.dividePassiveData();
            
            save(obj.ObjectPath, "obj");
            obj.addToList(listType);
        end
        
        function createMatFiles(obj)
            % Stores the mat files for the raw data - both for the task
            % and for the passive parts - as a Mouse property.
            
            % Task
            fileBeg = obj.CONST_RAW_FILE_PATH + obj.CONST_FOLDER_DELIMITER + obj.Name + obj.CONST_FOLDER_DELIMITER;
            obj.RawMatFile.Task.onset = matfile(fileBeg + obj.CONST_DATA_BY_ONSET);
            % obj.RawMatFile.Task.cloud = matfile(fileBeg + obj.CONST_DATA_BY_CLOUD);
            obj.RawMatFile.Task.cue = matfile(fileBeg + obj.CONST_DATA_BY_CUE);
            obj.RawMatFile.Task.lick = matfile(fileBeg + obj.CONST_DATA_BY_LICK);
            % obj.RawMatFile.Task.movement = matfile(fileBeg + obj.CONST_DATA_BY_MOVEMENT);
            
            % Passive
            obj.RawMatFile.Passive = matfile(fileBeg + obj.CONST_PASSIVE_DATA);
        end
        
        function createTaskInfo(obj)
            % Creates and stores as a mouse property the info of the task
            % and passive trials.
            
            % Create Task Info (by cue, cloud, ..)
            tInfo = obj.RawMatFile.Task.onset.t_info;
            obj.Info.Task.onset = tInfo;
            % obj.Info.Task.cloud =                   % TODO!
            obj.Info.Task.cue = tInfo((tInfo.plot_result ~= -1), :);       % All trials that are not premature
            obj.Info.Task.lick = tInfo((~isnan(tInfo.first_lick)), :);     % All trials that had a lick (including omissions that had a lick)
            % obj.Info.Task.movement =                % TODO!
            
            obj.Info.Passive = obj.RawMatFile.Passive.t_info;
            
            % Add day to info
            tInfo = obj.RawMatFile.Task.onset.t_info;
            sessionBreaks = find(tInfo.trial_number == 1);
            sessionBreaks = [sessionBreaks; size(tInfo, 1) + 1];
            
            recordingDays = [];
            
            for indx = 1:(length(sessionBreaks) - 1)
                recordingDays(sessionBreaks(indx):sessionBreaks(indx + 1) - 1) = indx;      % Tags each recording day
            end
            
            recordingDays = categorical(recordingDays');
            
            obj.Info.Task.onset.day = double(recordingDays);
            % obj.Info.Task.cloud.day = % TODO!
            obj.Info.Task.cue.day = double(recordingDays(tInfo.plot_result ~= -1));
            obj.Info.Task.lick.day = double(recordingDays(~isnan(tInfo.first_lick)));
            % obj.Info.Task.movement.day = % TODO!
        end
        
        function straightenTaskData(obj)
            % Normalizes / straightens the data of each day of tasks so it
            % has same baseline (calculated by correct licks)
            [gcampDifference, jrgecoDifference] = obj.getDayDifferences();
            
            fields = fieldnames(obj.Info.Task);
            
            for fieldIndex = 1:numel(fields)
                fieldName = fields{fieldIndex};
                info = obj.Info.Task.(fieldName);
                
                gcampTrials = obj.RawMatFile.Task.(fieldName).all_trials;
                jrgecoTrials = obj.RawMatFile.Task.(fieldName).af_trials;
                
                normGcampData = gcampTrials - gcampDifference(1);          % subtract intercept (1st day / correct)
                normJrgecoData = jrgecoTrials - jrgecoDifference(1);       % subtract intercept (1st day / correct)
                
                for indx = 2:length(unique(info.day))
                    normGcampData(info.day == indx, :) = normGcampData(info.day == indx, :) - gcampDifference(indx); % remove each days' intercept
                    normJrgecoData(info.day == indx, :) = normJrgecoData(info.day == indx, :) - jrgecoDifference(indx); % remove each days' intercept
                end
                
                obj.ProcessedRawData.Task.(fieldName).gcamp = normGcampData;
                obj.ProcessedRawData.Task.(fieldName).jrgeco = normJrgecoData;
                
            end
        end
        
        function dividePassiveData(obj)
            % This function divides the passive data into it's appropriate
            % sections (by BBN/FS and pre/post X awake/anesthetized). It
            % saves the results into the relevant mouse proprety
            tInfo = obj.Info.Passive;
            gcampPassive = obj.RawMatFile.Passive.all_trials;
            jrGecoPassive = obj.RawMatFile.Passive.af_trials;
            
            types = unique(tInfo.type);
            
            for typeIndex = 1:numel(types)
                curType = types{typeIndex};
                
                curTypeTInfo = tInfo(strcmp(tInfo.type,curType), :);
                conditions = unique(curTypeTInfo.cond);
                
                for conditionIndex = 1:numel(conditions)
                    curCondition = conditions{conditionIndex};
                    
                    obj.ProcessedRawData.Passive.(curType).(curCondition).gcamp = gcampPassive(strcmp(tInfo.type, curType) & strcmp(tInfo.cond, curCondition), :);
                    obj.ProcessedRawData.Passive.(curType).(curCondition).jrgeco = jrGecoPassive(strcmp(tInfo.type, curType) & strcmp(tInfo.cond, curCondition), :);
                end
            end
        end
        
        function addToList(obj, listType)
            % Adds the mouses path to the given mouse list. If no list is
            % exists, it creats a new list
            listFullPath = MouseList.CONST_LIST_SAVE_PATH + obj.CONST_FOLDER_DELIMITER + listType + ".mat";
            
            if ~ isfile(listFullPath)
                mouseList = MouseList(listType);
            else
                mouseList = load(listFullPath).obj;
            end
            
            mouseList.add(obj);
        end
        
        % ================ Plot ================
        function plotAllSessions(obj, descriptionVector, downSampleFactor)
            % Plots the gcamp + jrgeco signals from all the mouses sessions
            % (task or passive)
            
            % Generate Data
            [gcampSignal, jrGecoSignal, trialTime] = obj.getSignals(descriptionVector);
            
            numTrials = size(gcampSignal, 1);
            
            gcampSignal = obj.downSampleAndReshape(gcampSignal, downSampleFactor);
            jrGecoSignal = obj.downSampleAndReshape(jrGecoSignal, downSampleFactor);
            
            % jrGecoSignal = jrGecoSignal + 4;                               % So one can see both on the same figure
            
            timeVector = linspace(0, numTrials * trialTime, length(gcampSignal));
            
            % Plot
            figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            
            plot(ax, timeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            hold on;
            plot(ax, timeVector, jrGecoSignal, 'LineWidth', 2, 'Color', '#990099');
            hold off;
            
            title("Signal from all " +  descriptionVector(1) + "s of kind " + descriptionVector(2) + " for mouse " + obj.Name, 'Interpreter', 'none', 'FontSize', 12)
            
            [gcampType, jrgecoType] = obj.findGcampJrGecoType();
            
            legend(gcampType + " (gcamp)", jrgecoType + " (jrGeco)", 'Location', 'best', 'Interpreter', 'none')
            xlabel("Time (sec)", 'FontSize', 14)
            ylabel("zscored \DeltaF/F", 'FontSize', 14)
            xlim([0 100])
            
        end
        
        function plotSlidingCorrelation(obj, descriptionVector, timeWindow, timeShift, downSampleFactor)
            % Plots the gcamp + jrgeco signals from all the mouses sessions
            % (task or passive) and also plots the sliding window
            % correlation.
            
            % Generate Data
            [gcampSignal, jrGecoSignal, trialTime] = obj.getSignals(descriptionVector);
            totalTime = size(gcampSignal, 1) * trialTime;
            
            gcampSignal = reshape(gcampSignal', 1, []);
            jrGecoSignal = reshape(jrGecoSignal', 1, []);
            
            [correlationVector, correlationTimeVector] = obj.createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrGecoSignal, totalTime);
            
            gcampSignal = downsample(gcampSignal, downSampleFactor);
            jrGecoSignal = downsample(jrGecoSignal, downSampleFactor);
            signalTimeVector = linspace(0, totalTime, length(gcampSignal));
            
            % Plot
            obj.helperPlotSlidingCorrelation(descriptionVector, gcampSignal, jrGecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift)
        end
        
        function plotComparisonCorrelation(obj)
            % Plots correlations of the whole signal by all the different
            % possible categories - plots both each one as a scatter plot,
            % and then all of them together for comparison.
            
            correlationTable = obj.createComparisonCorrelationTable();
            
            obj.ComparisonCorrelationScatterPlot(correlationTable)
            obj.ComparisonCorrelationBar(correlationTable)
        end
        
        function plotComparisonSlidingCorrelation(obj, timeWindow, timeShift)
            % Plots a graph of means of sliding correlation by all the
            % different possible categories.
            
%             f = figure();
%             ax = gca;
            histogramMatrix = [];
            types = [];
            histogramEdges = linspace(-1, 1, 101);                          % Creates x - 1 bins
            yLabel = linspace(1, -1, length(histogramEdges) - 1);
            
            typeFields = fieldnames(obj.ProcessedRawData.Passive);
            
            for typeIndex = 1:numel(typeFields)
                curType = typeFields{typeIndex};
                
                conditionFields = fieldnames(obj.ProcessedRawData.Passive.(curType));
                
                for conditionIndex = 1:numel(conditionFields)
                    curCondition = conditionFields{conditionIndex};
                    
                    [gcampSignal, jrGecoSignal, trialTime] = getSignals(obj, ["Passive", (curType), (curCondition)]);
                    totalTime = size(gcampSignal, 1) * trialTime;
                    gcampSignal = reshape(gcampSignal', 1, []);
                    jrGecoSignal = reshape(jrGecoSignal', 1, []);
                    
                    [correlationVector, ~] = obj.createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrGecoSignal, totalTime);
                    [binCount,~] = histcounts(correlationVector, histogramEdges, 'Normalization', 'probability');
%                     histogram(ax, correlationVector, histogramEdges, 'Normalization', 'probability');
%                     hold on
                    histogramMatrix = [histogramMatrix, flip(binCount')];
                    type = "Passive " + (curType) + " " + (curCondition);
                    types = [types, type];
                    
                end
            end
            
            [gcampSignal, jrGecoSignal, trialTime] = getSignals(obj, ["Task", "onset"]);
            totalTime = size(gcampSignal, 1) * trialTime;
            gcampSignal = reshape(gcampSignal', 1, []);
            jrGecoSignal = reshape(jrGecoSignal', 1, []);

            [correlationVector, ~] = obj.createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrGecoSignal, totalTime);
            [binCount,~] = histcounts(correlationVector, histogramEdges, 'Normalization', 'probability');
            histogramMatrix = [histogramMatrix, flip(binCount')];
            type = "Task";
            types = [types, type];
%             histogram(ax, correlationVector, histogramEdges, 'Normalization', 'probability');
%             hold off
            
            fig = figure();
            heatmap(fig, types, yLabel, histogramMatrix);
            
        end
        
        % ================ Helpers ================
        % ==== General ====
        function [gcampDifference, jrgecoDifference] = getDayDifferences(obj)
            % Creates for each day how much one needs to add in order to have
            % same baseline (calculated by correct licks)
            gTrials = obj.RawMatFile.Task.onset.all_trials;
            jTrials = obj.RawMatFile.Task.onset.af_trials;
            
            recordingDays = categorical(obj.Info.Task.onset.day);
            recordingOutcome = categorical(obj.Info.Task.onset.trial_result);
            
            % Gcamp
            gRecordingBase = double(mean(gTrials(:, 1000:5000), 2));       % From 1 to 5 seconds
            gRecordingSet = table(gRecordingBase, recordingDays, recordingOutcome, 'VariableNames', {'baseline', 'day', 'outcome'});
            G = fitlme(gRecordingSet, 'baseline ~ outcome + day');         % also can use fitglm: especially if want to do interaction Keep in mind to fit to a random effect (1|day).
            gcampDifference = G.Coefficients.Estimate;
            
            % Geco
            jRecordingBase = double(mean(jTrials(:, 1000:5000), 2));       % From 1 to 5 seconds
            jRecordingSet = table(jRecordingBase, recordingDays, recordingOutcome, 'VariableNames', {'baseline', 'day', 'outcome'});
            J = fitlme(jRecordingSet, 'baseline ~ outcome + day');         % also can use fitglm: especially if want to do interaction Keep in mind to fit to a random effect (1|day).
            jrgecoDifference = J.Coefficients.Estimate;
            
            % NOTE - 3 last indexes of differences aren't relavent
        end
        
        function [gcampType, jrgecoType] = findGcampJrGecoType(obj)
            % Returns the brain area of gcamp and area of geco in this
            % mouse
            if obj.GcampJrGecoReversed
                gcampType = obj.JRGECO;
                jrgecoType = obj.GCAMP;
            else
                gcampType = obj.GCAMP;
                jrgecoType = obj.JRGECO;
            end
        end
        
        function [gcampSignal, jrGecoSignal, trialTime] = getSignals(obj, descriptionVector)
            % Recives a vector with information on the wanted signal:
            % For Task signals ["Task", "cutBy"],
            %      for example ["Task", "lick"]
            % For Passive signals ["Passive", "soundType", "condition"],
            %         for example ["Passive", "BBN", "post_awake"]
            
            if descriptionVector(1) == "Task"                              % Task
                cutBy = descriptionVector(2);
                gcampSignal = obj.ProcessedRawData.Task.(cutBy).gcamp;
                jrGecoSignal = obj.ProcessedRawData.Task.(cutBy).jrgeco;
                trialTime = obj.CONST_TASK_TRIAL_TIME;
            elseif descriptionVector(1) == "Passive"                       % Passive
                soundType = descriptionVector(2);
                condition = descriptionVector(3);
                gcampSignal = obj.ProcessedRawData.Passive.(soundType).(condition).gcamp;
                jrGecoSignal = obj.ProcessedRawData.Passive.(soundType).(condition).jrgeco;
                trialTime = obj.CONST_PASSIVE_TRIAL_TIME;
            elseif descriptionVector(1) == "Free"                          % Free
                %%%%%%% TODO %%%%%%
            else                                 
                disp("Problem with given description vector");
            end
        end
        
        % == Specific For Plots ==
        function helperPlotSlidingCorrelation(obj, descriptionVector, gcampSignal, jrGecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift)
            % Creats the plots for the PlotSlidingCorrelation function
            
            fig = figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            correlationPlot = subplot(2, 1, 1);
            signalPlot = subplot(2, 1, 2);
            
            plot(correlationPlot, correlationTimeVector, correlationVector, 'LineWidth', 2, 'Color', 'Black');
            xlim(correlationPlot, [0 50])
            ylim(correlationPlot, [-1 1])
            line(correlationPlot, [0 correlationTimeVector(length(correlationTimeVector))], [0 0], 'Color', '#C0C0C0')
            
            plot(signalPlot, signalTimeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            hold on
            plot(signalPlot, signalTimeVector, jrGecoSignal, 'LineWidth', 2, 'Color', '#990099');
            hold off
            xlim(signalPlot, [0 50])
            
            title(correlationPlot, "Sliding Window Correlation - Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), 'FontSize', 13, 'Interpreter', 'none')
            [gcampType, jrgecoType] = obj.findGcampJrGecoType();
            title(signalPlot, "Signal from all " +  descriptionVector(1) + "s of kind " + descriptionVector(2) + " for mouse " + obj.Name, 'FontSize', 13, 'Interpreter', 'none')
            
            legend(signalPlot, gcampType + " (gcamp)", jrgecoType + " (jrGeco)", 'Location', 'best')
            
            xlabel(correlationPlot, "Time (sec)")
            xlabel(signalPlot, "Time (sec)")
            ylabel(correlationPlot, "correlation")
            ylabel(signalPlot, "zscored \DeltaF/F")
        end
        
        function correlationTable = createComparisonCorrelationTable(obj)
            % Create data for correlation comparison
            correlationTable = array2table(zeros(0,4));
            correlationTable.Properties.VariableNames = {'kind', 'correlation', 'gcampSignal', 'jrGecoSignal'};
            
            typeFields = fieldnames(obj.ProcessedRawData.Passive);
            
            for typeIndex = 1:numel(typeFields)
                curType = typeFields{typeIndex};
                
                conditionFields = fieldnames(obj.ProcessedRawData.Passive.(curType));
                
                for conditionIndex = 1:numel(conditionFields)
                    curCondition = conditionFields{conditionIndex};
                    
                    kind = "Passive " + (curType) + " " + (curCondition);
                    gcampSignal =  {reshape(obj.ProcessedRawData.Passive.(curType).(curCondition).gcamp', 1, [])}; % Need to use cell to be able to concant different len vectors
                    jrGecoSignal = {reshape(obj.ProcessedRawData.Passive.(curType).(curCondition).jrgeco', 1, [])}; % Need to use cell to be able to concant different len vectors
                    correlation = corr(gcampSignal{:}', jrGecoSignal{:}');
                    
                    curRow = table(kind, correlation, gcampSignal, jrGecoSignal);
                    correlationTable = [correlationTable; curRow];
                end
            end
            
            kind = "Task";
            gcampSignal =  {reshape(obj.ProcessedRawData.Task.onset.gcamp', 1, [])};
            jrGecoSignal = {reshape(obj.ProcessedRawData.Task.onset.jrgeco', 1, [])};
            correlation = corr(gcampSignal{:}', jrGecoSignal{:}');
            
            curRow = table(kind, correlation, gcampSignal, jrGecoSignal);
            correlationTable = [correlationTable; curRow];
        end
        
        function ComparisonCorrelationScatterPlot(obj, correlationTable)
            % Plot scatter plot of comaprison correlation
            fig = figure("Name", "Comparing correlations of mouse " + obj.Name, "NumberTitle", "off", "Position", [211,137,1569,362]);
            amount = size(correlationTable, 1);
            
            [gcampType, jrgecoType] = obj.findGcampJrGecoType();
            
            for index = 1:amount
                curPlot = subplot(1, amount, index);
                
                curGcampSignal = correlationTable.gcampSignal(index);
                curGcampSignal = curGcampSignal{:};
                curJrGecoSignal = correlationTable.jrGecoSignal(index);
                curJrGecoSignal = curJrGecoSignal{:};
                gcampDownSampled = downsample(curGcampSignal, 100);
                jrGecoDownSampled = downsample(curJrGecoSignal, 100);
                
                scatter(curPlot, gcampDownSampled, jrGecoDownSampled, 10,'filled');
                
                % Best fit line
                coefficients = polyfit(curGcampSignal,  curJrGecoSignal, 1);
                fitted = polyval(coefficients, curGcampSignal);
                line(curPlot, curGcampSignal, fitted, 'Color', 'black', 'LineStyle', '--')
                
                title(curPlot, correlationTable.kind(index), 'Interpreter', 'none')
                xlabel(gcampType + " (gcamp)")
                ylabel(jrgecoType + " (jrGeco)")
            end
        end
        
        function ComparisonCorrelationBar(obj, correlationTable)
            % Plot bars that represent the comaprison between the 
            % correlations of all the possible categories.
            
            fig = figure("Name", "Results of comparing correlations of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            categories = categorical(correlationTable.kind);
            bar(ax, categories, correlationTable.correlation);
            set(ax,'TickLabelInterpreter','none')
            title(ax, "Results of comparing correlations of mouse " + obj.Name, 'Interpreter', 'none')
            ylabel("Correlation")
            
            minY = min(correlationTable.correlation);
            maxY = max(correlationTable.correlation);
            
            if (minY < 0) && (0 < maxY)
                ylim(ax, [-1, 1])
            elseif (0 < maxY)                                              % for sure 0 <= minY
                ylim(ax, [0, 1])
            else
                ylim(ax, [-1, 0])
            end
        end
        
        % ================ Old ================
        function plotMouseCrossCorrelations(obj, subPlots, timeVector)
            [plotByCloud, plotByCue, plotByLick, plotByMove, plotByOnset] = subPlots{:};
            
            % TODO - use for on Matfile - for idx = numel(Matfile) ... MatFile{idx}
            obj.plotGeneralCrossCorrelation(plotByCloud, timeVector, obj.DATA_BY_CLOUD);
            obj.plotGeneralCrossCorrelation(plotByCue, timeVector, obj.DATA_BY_CUE);
            obj.plotGeneralCrossCorrelation(plotByLick, timeVector, obj.DATA_BY_LICK);
            obj.plotGeneralCrossCorrelation(plotByMove, timeVector, obj.DATA_BY_MOVEMENT);
            obj.plotGeneralCrossCorrelation(plotByOnset, timeVector, obj.DATA_BY_ONSET);
            
        end
        
        function plotGeneralCrossCorrelation(obj, ax, timeVector, dataBy)
            dataFile = matfile(obj.FILE_DIRECTORY + obj.FOLDER_DELIMITER + obj.Name + obj.FOLDER_DELIMITER + dataBy);
            if obj.GcampJrGecoReversed
                gcampLowered = zscore(dataFile.af_trials')';
                jrgecoLowered = zscore(dataFile.all_trials')';
            else
                % gcampLowered = dataFile.all_trials;
                % gcampLowered = dataFile.all_trials - mean(dataFile.all_trials);% Needs to be lowered so upwards won't give too much weight
                gcampLowered = zscore(dataFile.all_trials')';   % Another option
                % jrgecoLowered = dataFile.af_trials;
                % jrgecoLowered = dataFile.af_trials - mean(dataFile.af_trials); % Needs to be lowered so upwards won't give too much weight
                jrgecoLowered = zscore(dataFile.af_trials')';   % Another option
            end
            
            rows = size(gcampLowered,1);
            cols = size(gcampLowered, 2);
            gcampXjrgeco = zeros(rows, cols * 2 - 1);
            
            for index = 1:rows
                gcampXjrgeco(index,:) = xcorr(gcampLowered(index,:), jrgecoLowered(index,:), 'normalized');
            end
            gcampXjrgeco = sum(gcampXjrgeco) / rows;
            plot(ax, timeVector, gcampXjrgeco)
        end
        
        function plotCrossCorrelation(obj, descriptionVector)
            [gcampSignal, jrGecoSignal, trialTime] = getSignals(obj, descriptionVector);
            % DELETE! 
            gcampSignal = gcampSignal - min(gcampSignal, [], 'all');
            
            
            
            timeVector = linspace(-trialTime, trialTime, length(gcampSignal) * 2 - 1);
            rows = size(gcampSignal,1);
            cols = size(gcampSignal, 2);
            gcampXjrgeco = zeros(rows, cols * 2 - 1);
            
            for index = 1:rows
                gcampXjrgeco(index,:) = xcorr(gcampSignal(index,:), jrGecoSignal(index,:), 'normalized');  %TODO - think if should be normalized here or at the end
            end
            gcampXjrgeco = sum(gcampXjrgeco) / rows;
            plot(timeVector, gcampXjrgeco)
        end
    end
    
    methods (Static)
        % ================ Helpers ================
        function finalSignal = downSampleAndReshape(rawSignal, downSampleFactor)
            % Receive a data in a matrix and a down sample factor
            % Returns a signal that is a vector and is down sampled
            finalSignal = reshape(rawSignal', 1, []);
            finalSignal = downsample(finalSignal, downSampleFactor);
        end
        
        function [correlationVector, timeVector] = createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrGecoSignal, totalTime)
            % Creats a vector that represents the sliding correlation
            % between the given signals, acoording to the given time window
            % and time shift. It returns both a vector that represents the
            % sliding correlation, and a time vector that corresponds with
            % it.
            fs = length(gcampSignal) / totalTime;                          %!!!! TODO - think if this is the right calc vs. timeVector
            
            SamplesInTimeWindow = round(fs * timeWindow);
            SamplesInMovement = round(fs * timeShift);
            
            startWindowIndexVector = 1:SamplesInMovement:length(gcampSignal) - SamplesInTimeWindow + 1;
            correlationVector = zeros(1, length(startWindowIndexVector));
            
            for loopIndex = 1:length(startWindowIndexVector)
                
                startIndex = startWindowIndexVector(loopIndex);
                lastIndex = startIndex + SamplesInTimeWindow - 1;
                
                gcampVector = gcampSignal(startIndex : lastIndex);
                jrGecoVector = jrGecoSignal(startIndex : lastIndex);
                
                correlation = corr(gcampVector', jrGecoVector');
                correlationVector(loopIndex) = correlation;
            end
            endTime = (lastIndex - 1)/ fs;                                 % Index start from 1, time from 0
            
            timeVector = linspace(0, endTime, length(correlationVector));
            timeVector = timeVector + (timeWindow / 2);                    % Correlation will show in the middle of time window and not on beginning
        end
        
    end
end

