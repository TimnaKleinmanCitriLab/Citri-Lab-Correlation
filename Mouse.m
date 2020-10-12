classdef Mouse < handle
    %MOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        CONST_MOUSE_SAVE_PATH = "W:\shared\Timna\Gal Projects\Mice";
        CONST_RAW_FILE_PATH = "\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig";
        
        % Task
        CONST_DATA_BY_CLOUD = "CueInCloud_comb_cloud.mat";
        CONST_DATA_BY_CUE = "CueInCloud_comb_cue.mat";
        CONST_DATA_BY_LICK = "CueInCloud_comb_lick.mat";
        CONST_DATA_BY_MOVEMENT = "CueInCloud_comb_movement.mat";
        CONST_DATA_BY_ONSET = "CueInCloud_comb_t_onset.mat";
        
        CONST_TASK_TRIAL_TIME = 20;
        
        % Passive
        CONST_PASSIVE_DATA = "passive\Passive_comb.mat";
        
        CONST_PASSIVE_STATES = ["awake", "anes"];
        CONST_PASSIVE_SOUND_TYPES = ["BBN", "FS"];
        CONST_PASSIVE_TIMES = ["pre", "post"];
        
        CONST_PASSIVE_TRIAL_TIME = 5;
    end
    
    properties
        Name
        GcampJrgecoReversed
        ObjectPath
        
        RawMatFile
        Info
        ProcessedRawData
    end
    
    methods
        %========== Constructor Functions ==========
        function obj = Mouse(name, gcampJrgecoReversed, listType)
            % MOUSE Construct an instance of this class
            obj.Name = name;
            obj.GcampJrgecoReversed = gcampJrgecoReversed;
            obj.ObjectPath = obj.CONST_MOUSE_SAVE_PATH + "\" + name + ".mat" ;
            
            obj.createMatFiles();
            
            % Task
            obj.createTaskInfo();
            obj.createAndStraightenTaskData();
            
            % Passive
            obj.createPassiveDataAndInfo();
            
            save(obj.ObjectPath, "obj");
            obj.addToList(listType);
        end
        
        function createMatFiles(obj)
            % Both for Task and for Passive - stores the mat files for the
            % raw data as a Mouse property.
            
            % Task
            fileBeg = obj.CONST_RAW_FILE_PATH + "\" + obj.Name + "\";
            obj.RawMatFile.Task.onset = matfile(fileBeg + obj.CONST_DATA_BY_ONSET);
            % obj.RawMatFile.Task.cloud = matfile(fileBeg + obj.CONST_DATA_BY_CLOUD);
            obj.RawMatFile.Task.cue = matfile(fileBeg + obj.CONST_DATA_BY_CUE);
            obj.RawMatFile.Task.lick = matfile(fileBeg + obj.CONST_DATA_BY_LICK);
            % obj.RawMatFile.Task.movement = matfile(fileBeg + obj.CONST_DATA_BY_MOVEMENT);
            
            % Passive
            obj.RawMatFile.Passive = matfile(fileBeg + obj.CONST_PASSIVE_DATA);
        end
        
        function createTaskInfo(obj)
            % Creates info for different task divisions (by cue, cloud,..)
            % and adds information about the day of the task.
            
            tInfo = obj.RawMatFile.Task.onset.t_info;
            obj.Info.Task.onset = tInfo;
            % obj.Info.Task.cloud =                   % TODO!
            obj.Info.Task.cue = tInfo((tInfo.plot_result ~= -1), :);       % All trials that are not premature
            obj.Info.Task.lick = tInfo((~isnan(tInfo.first_lick)), :);     % All trials that had a lick (including omissions that had a lick)
            % obj.Info.Task.movement =                % TODO!
            
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
        
        function createPassiveDataAndInfo(obj)
            % This function divides the passive data and info into it's
            % appropriate sections (by BBN/FS, pre/post, awake/anesthetized).
            % It then saves the results into the relevant mouse propreties.
            
            tInfo = obj.RawMatFile.Passive.t_info;
            gcampPassive = obj.RawMatFile.Passive.all_trials;
            jrgecoPassive = obj.RawMatFile.Passive.af_trials;
            
            obj.Info.Passive.exists = array2table(zeros(0,3));
            obj.Info.Passive.exists.Properties.VariableNames = {'state', 'soundType', 'time'};
            
            for state = obj.CONST_PASSIVE_STATES
                for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                    for time = obj.CONST_PASSIVE_TIMES
                        relevantLines = strcmp(tInfo.cond, (time) + "_" + (state)) & strcmp(tInfo.type, (soundType));
                        if any(relevantLines) % There is a recording of this type
                            % Add to existing list
                            curRow = table(state, soundType, time);
                            obj.Info.Passive.exists = [obj.Info.Passive.exists; curRow];
                            
                            % Save info
                            obj.Info.Passive.(state).(soundType).(time) = tInfo(relevantLines, :);
                            
                            % Save data
                            obj.ProcessedRawData.Passive.(state).(soundType).(time).gcamp = gcampPassive(relevantLines, :);
                            obj.ProcessedRawData.Passive.(state).(soundType).(time).jrgeco = jrgecoPassive(relevantLines, :);
                        end
                    end
                end
            end
        end
        
        function createAndStraightenTaskData(obj)
            % Normalizes / straightens the data of each day of tasks so it
            % has same baseline (calculated by correct licks)
            [gcampDifference, jrgecoDifference] = obj.getDayDifferences();
            
            fields = fieldnames(obj.Info.Task);
            
            for index = 1:numel(fields)
                divideBy = fields{index};
                info = obj.Info.Task.(divideBy);
                
                gcampTrials = obj.RawMatFile.Task.(divideBy).all_trials;
                jrgecoTrials = obj.RawMatFile.Task.(divideBy).af_trials;
                
                normGcampData = gcampTrials - gcampDifference(1);          % subtract intercept (1st day / correct)
                normJrgecoData = jrgecoTrials - jrgecoDifference(1);       % subtract intercept (1st day / correct)
                
                for indx = 2:length(unique(info.day))
                    normGcampData(info.day == indx, :) = normGcampData(info.day == indx, :) - gcampDifference(indx); % remove each days' intercept
                    normJrgecoData(info.day == indx, :) = normJrgecoData(info.day == indx, :) - jrgecoDifference(indx); % remove each days' intercept
                end
                
                obj.ProcessedRawData.Task.(divideBy).gcamp = normGcampData;
                obj.ProcessedRawData.Task.(divideBy).jrgeco = normJrgecoData;
                
            end
        end
        
        function addToList(obj, listType)
            % Adds the mouses path to the given mouse list. If no list is
            % exists, it creats a new list
            listFullPath = MouseList.CONST_LIST_SAVE_PATH + "\" + listType + ".mat";
            
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
            [gcampSignal, jrgecoSignal, trialTime, signalTitle] = obj.getSignals(descriptionVector);
            
            numTrials = size(gcampSignal, 1);
            
            gcampSignal = obj.downSampleAndReshape(gcampSignal, downSampleFactor);
            jrgecoSignal = obj.downSampleAndReshape(jrgecoSignal, downSampleFactor);
            
            % jrgecoSignal = jrgecoSignal + 4;                             % So one can see both on the same figure
            
            timeVector = linspace(0, numTrials * trialTime, size(gcampSignal, 2));
            
            % Plot
            figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            
            plot(ax, timeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            hold on;
            plot(ax, timeVector, jrgecoSignal, 'LineWidth', 2, 'Color', '#990099');
            hold off;
            
            title({"Signal From: " +  signalTitle, "Mouse: " + obj.Name}, 'Interpreter', 'none', 'FontSize', 12) % TODO - Fix
            
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            
            legend(gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best', 'Interpreter', 'none')
            xlabel("Time (sec)", 'FontSize', 14)
            ylabel("zscored \DeltaF/F", 'FontSize', 14)
            xlim([0 100])
            
        end
        
        function plotComparisonCorrelation(obj)
            % Plots correlations of the whole signal by all the different
            % possible categories - plots both each one as a scatter plot,
            % and then all of them together for comparison.
            % correlationTable = obj.createComparisonCorrelationTable();
            
            obj.ComparisonCorrelationScatterPlot()
            obj.ComparisonCorrelationBar()
        end
        
        function plotSlidingCorrelation(obj, descriptionVector, timeWindow, timeShift, downSampleFactor)
            % Plots the gcamp + jrgeco signals from all the mouses sessions
            % (task or passive) and also plots the sliding window
            % correlation.
            
            % Generate Data
            [gcampSignal, jrgecoSignal, trialTime, signalTitle] = obj.getSignals(descriptionVector);
            totalTime = size(gcampSignal, 1) * trialTime;
            
            gcampSignal = reshape(gcampSignal', 1, []);
            jrgecoSignal = reshape(jrgecoSignal', 1, []);
            
            [correlationVector, correlationTimeVector] = obj.createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, totalTime);
            
            gcampSignal = downsample(gcampSignal, downSampleFactor);
            jrgecoSignal = downsample(jrgecoSignal, downSampleFactor);
            signalTimeVector = linspace(0, totalTime, size(gcampSignal, 2));
            
            % Plot
            obj.helperPlotSlidingCorrelation(gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift, signalTitle)
        end
        
        function plotComparisonSlidingCorrelation(obj, timeWindow, timeShift)
            % Plots a comparison of sliding window histogram for all
            % different categories.
            
            histogramMatrix = [];
            types = [''];
            histogramEdges = linspace(-1, 1, 101);                          % Creates x - 1 bins
            
            typeFields = fieldnames(obj.ProcessedRawData.Passive);
            
            for typeIndex = 1:numel(typeFields)
                curType = typeFields{typeIndex};
                
                conditionFields = fieldnames(obj.ProcessedRawData.Passive.(curType));
                
                for conditionIndex = 1:numel(conditionFields)
                    curCondition = conditionFields{conditionIndex};
                    
                    [gcampSignal, jrgecoSignal, trialTime, signalTitle] = getSignals(obj, ["Passive", (curType), (curCondition)]);
                    totalTime = size(gcampSignal, 1) * trialTime;
                    gcampSignal = reshape(gcampSignal', 1, []);
                    jrgecoSignal = reshape(jrgecoSignal', 1, []);
                    
                    [correlationVector, ~] = obj.createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, totalTime);
                    [binCount,~] = histcounts(correlationVector, histogramEdges, 'Normalization', 'probability');
                    histogramMatrix = [histogramMatrix, binCount'];
                    type = signalTitle;
                    types = [types, type, ''];
                    
                end
            end
            
            [gcampSignal, jrgecoSignal, trialTime, ~] = getSignals(obj, ["Task", "onset"]);
            totalTime = size(gcampSignal, 1) * trialTime;
            gcampSignal = reshape(gcampSignal', 1, []);
            jrgecoSignal = reshape(jrgecoSignal', 1, []);
            
            [correlationVector, ~] = obj.createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, totalTime);
            [binCount,~] = histcounts(correlationVector, histogramEdges, 'Normalization', 'probability');
            histogramMatrix = [histogramMatrix, binCount'];
            type = "Task";
            types = [types, type];
            
            % Plot
            fig = figure("Name", "Comparison Sliding Window Correlation of mouse " + obj.Name, "NumberTitle", "off");
            ax = axes;
            
            ax.YLabel.String = 'correlation';
            imagesc(ax, [0, size(histogramMatrix, 2)-1], [1, -1], histogramMatrix) % Limits are 1 to -1 so 1 will be up and -1 down, need to change ticks too
            colorbar
            %             ax.YTick = -1:-0.2:1;
            ax.YTickLabel = 1:-0.2:-1;                                     % TODO - Fix!
            ax.XTickLabel = types;
            ax.TickLabelInterpreter = 'none';
            xtickangle(ax,-30)
            title(ax, {"Comparison Sliding Window Correlation for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, 'Interpreter', 'none')
            line(ax, [-0.5, size(types, 2)], [0, 0], 'Color', 'black')
        end
        
        % ================ Helpers ================
        % ==== General ====
        function [gcampSignal, jrgecoSignal, trialTime, signalTitle] = getSignals(obj, descriptionVector)
            % Recives a vector with information on the wanted signal:
            % For Task signals ["Task", "divideBy"],
            %      for example ["Task", "lick"]
            % For Passive signals ["Passive", "state", "soundType", "time"],
            %         for example ["Passive", "awake", "BBN", "post"]
            if obj.signalExists(descriptionVector)
                
                if descriptionVector(1) == "Task"                              % Task
                    cutBy = descriptionVector(2);
                    gcampSignal = obj.ProcessedRawData.Task.(cutBy).gcamp;
                    jrgecoSignal = obj.ProcessedRawData.Task.(cutBy).jrgeco;
                    trialTime = obj.CONST_TASK_TRIAL_TIME;
                    signalTitle = "Task cut by " + cutBy;
                elseif descriptionVector(1) == "Passive"                       % Passive
                    state = descriptionVector(2);
                    soundType = descriptionVector(3);
                    time = descriptionVector(4);
                    gcampSignal = obj.ProcessedRawData.Passive.(state).(soundType).(time).gcamp;
                    jrgecoSignal = obj.ProcessedRawData.Passive.(state).(soundType).(time).jrgeco;
                    trialTime = obj.CONST_PASSIVE_TRIAL_TIME;
                    signalTitle = (time) + " " + (state) + " " + (soundType);
                elseif descriptionVector(1) == "Free"                          % Free
                    %%%%%%% TODO %%%%%%
                end
                
            else
                error("Problem with given description vector");
            end
        end
        
        function [exists] = signalExists(obj, descriptionVector)
            if descriptionVector(1) == "Task"                              % Task
                divideBy = descriptionVector(2);
                if divideBy == "onset" || divideBy == "lick" || ...
                        divideBy == "cue" || divideBy == "movement" || ...
                        divideBy == "cloud"
                    exists = true;
                else
                    exists = false;
                end
                
            elseif descriptionVector(1) == "Passive"                       % Passive
                existTable = obj.Info.Passive.exists;
                
                state = descriptionVector(2);
                soundType = descriptionVector(3);
                time = descriptionVector(4);
                
                relevantLines = existTable.state == (state) & ...
                    existTable.soundType == (soundType) & ...
                    existTable.time == (time);
                if any(relevantLines)
                    exists = true;
                else
                    exists = false;
                end
            elseif descriptionVector(1) == "Free"                          % Free
                exists = true;
            else
                exists = false;
            end
        end
        
        function [gcampType, jrgecoType] = findGcampJrgecoType(obj)
            % Returns the brain area of gcamp and area of geco in this
            % mouse
            if obj.GcampJrgecoReversed
                gcampType = obj.JRGECO;
                jrgecoType = obj.GCAMP;
            else
                gcampType = obj.GCAMP;
                jrgecoType = obj.JRGECO;
            end
        end
        
        % ==== Constructor ====
        
        function [gcampDifference, jrgecoDifference] = getDayDifferences(obj)
            % Creates for each day how much one needs to add in order to have
            % same baseline (calculated by correct licks)
            gcampTrials = obj.RawMatFile.Task.onset.all_trials;
            jrgecoTrials = obj.RawMatFile.Task.onset.af_trials;
            
            recordingDays = categorical(obj.Info.Task.onset.day);
            recordingOutcome = categorical(obj.Info.Task.onset.trial_result);
            
            % Gcamp
            gRecordingBase = double(mean(gcampTrials(:, 1000:5000), 2));    % From 1 to 5 seconds
            gRecordingSet = table(gRecordingBase, recordingDays, recordingOutcome, 'VariableNames', {'baseline', 'day', 'outcome'});
            G = fitlme(gRecordingSet, 'baseline ~ outcome + day');         % also can use fitglm: especially if want to do interaction Keep in mind to fit to a random effect (1|day).
            gcampDifference = G.Coefficients.Estimate;
            
            % Geco
            jRecordingBase = double(mean(jrgecoTrials(:, 1000:5000), 2));       % From 1 to 5 seconds
            jRecordingSet = table(jRecordingBase, recordingDays, recordingOutcome, 'VariableNames', {'baseline', 'day', 'outcome'});
            J = fitlme(jRecordingSet, 'baseline ~ outcome + day');         % also can use fitglm: especially if want to do interaction Keep in mind to fit to a random effect (1|day).
            jrgecoDifference = J.Coefficients.Estimate;
            
            % NOTE - 3 last indexes of differences aren't relevant
        end
        
        % ==== Plots ====
        function helperPlotSlidingCorrelation(obj, gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift, signalTitle)
            % Creats the plots for the PlotSlidingCorrelation function
            
            fig = figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            correlationPlot = subplot(2, 1, 1);
            signalPlot = subplot(2, 1, 2);
            
            plot(correlationPlot, correlationTimeVector, correlationVector, 'LineWidth', 2, 'Color', 'Black');
            xlim(correlationPlot, [0 50])
            ylim(correlationPlot, [-1 1])
            line(correlationPlot, [0 correlationTimeVector(size(correlationTimeVector, 2))], [0 0], 'Color', '#C0C0C0')
            
            plot(signalPlot, signalTimeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            hold on
            plot(signalPlot, signalTimeVector, jrgecoSignal, 'LineWidth', 2, 'Color', '#990099');
            hold off
            xlim(signalPlot, [0 50])
            
            title(correlationPlot, {"Sliding Window Correlation -",  "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, 'FontSize', 13, 'Interpreter', 'none')
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            title(signalPlot, "Signal from " +  signalTitle + " for mouse " + obj.Name, 'FontSize', 13, 'Interpreter', 'none')
            
            legend(signalPlot, gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best')
            
            xlabel(correlationPlot, "Time (sec)")
            xlabel(signalPlot, "Time (sec)")
            ylabel(correlationPlot, "correlation")
            ylabel(signalPlot, "zscored \DeltaF/F")
        end
        
        function ComparisonCorrelationScatterPlot(obj)
            % Plot scatter plot of comaprison correlation
            fig = figure("Name", "Comparing correlations of mouse " + obj.Name, "NumberTitle", "off", "position", [498,113,1069,767]);
            passiveAmount = (size(obj.CONST_PASSIVE_STATES, 2) * size(obj.CONST_PASSIVE_SOUND_TYPES, 2) * size(obj.CONST_PASSIVE_TIMES, 2));
            index = 1;
            
            % Passive
            for time = obj.CONST_PASSIVE_TIMES
                for state = obj.CONST_PASSIVE_STATES
                    for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                        curPlot = subplot(3, passiveAmount / 2, index);
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        
                        obj.drawScatterPlot(curPlot, descriptionVector);
                        title(curPlot, (time) + " " + (state) + " " + (soundType), 'Interpreter', 'none')
                        
                        index = index + 1;
                    end
                end
            end
            
            % Task
            curPlot = subplot(3, passiveAmount / 2, index);
            descriptionVector = ["Task", "onset"];
            
            obj.drawScatterPlot(curPlot, descriptionVector);
            title(curPlot, "Task" , 'Interpreter', 'none')
        end
        
        function drawScatterPlot(obj, curPlot, descriptionVector)
            if obj.signalExists(descriptionVector)
                [gcampSignal, jrgecoSignal, ~, ~] = obj.getSignals(descriptionVector);
                
                [gcampType, jrgecoType] = obj.findGcampJrgecoType();
                
                gcampDownSampled = obj.downSampleAndReshape(gcampSignal, 100);
                jrgecoDownSampled = obj.downSampleAndReshape(jrgecoSignal, 100);
                
                scatter(curPlot, gcampDownSampled, jrgecoDownSampled, 10,'filled');
                
                % Best fit line
                coefficients = polyfit(gcampSignal,  jrgecoSignal, 1);
                fitted = polyval(coefficients, gcampSignal);
                line(curPlot, gcampSignal, fitted, 'Color', 'black', 'LineStyle', '--')
                
                xlabel(gcampType + " (gcamp)")
                ylabel(jrgecoType + " (jrgeco)")
                
                % Find axes limits
                yLimits = ylim(curPlot);
                xLimits = xlim(curPlot);
                
                minTick = min([xLimits(1), yLimits(1)]);
                maxTick = max([xLimits(2), yLimits(2)]);
                xlim(curPlot, [minTick, maxTick])
                ylim(curPlot, [minTick, maxTick])
            end
        end
        
        function ComparisonCorrelationBar(obj)
            % Plot bars that represent the comaprison between the
            % correlations of all the possible categories.
            
            fig = figure("Name", "Results of comparing correlations of mouse " + obj.Name, "NumberTitle", "off");
            ax = axes;
            
            correlations = [];
            xLabels = [];
            
            % Passive
            for state = obj.CONST_PASSIVE_STATES
                for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                    for time = obj.CONST_PASSIVE_TIMES
                        
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        curCorrelation = obj.getWholeSignalCorrelation(descriptionVector);
                        
                        correlations = [correlations, curCorrelation];
                        xLabels = [xLabels, (time) + ' ' + (state) + ' ' + (soundType)];
                    end
                end
            end
            
            descriptionVector = ["Task", "onset"];
            curCorrelation = obj.getWholeSignalCorrelation(descriptionVector);
            correlations = [correlations, curCorrelation];
            xLabels = [xLabels, "Task"];
            
            % Create Plot
            categories = categorical(xLabels);
            categories = reordercats(categories,xLabels);
            bar(ax, categories, correlations);
            set(ax,'TickLabelInterpreter','none')
            title(ax, "Results of comparing correlations of mouse " + obj.Name, 'Interpreter', 'none')
            ylabel("Correlation")
            
            minY = min(correlations);
            maxY = max(correlations);
            
            if (minY < 0) && (0 < maxY)
                ylim(ax, [-1, 1])
            elseif (0 < maxY)                                              % for sure 0 <= minY
                ylim(ax, [0, 1])
            else
                ylim(ax, [-1, 0])
            end
        end
        
        function correlation = getWholeSignalCorrelation(obj, descriptionVector)
            % Returns the correlation between gcamp and jrgeco for the
            % given description vector. If no signal exists returns 0.
            if obj.signalExists(descriptionVector)
                [gcampSignal, jrgecoSignal, ~, ~] = obj.getSignals(descriptionVector);
                gcampSignal = obj.downSampleAndReshape(gcampSignal, 1);
                jrgecoSignal = obj.downSampleAndReshape(jrgecoSignal, 1);
                correlation = corr(gcampSignal', jrgecoSignal');
            else
                correlation = 0;
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
            if obj.GcampJrgecoReversed
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
            [gcampSignal, jrgecoSignal, trialTime, ~] = getSignals(obj, descriptionVector);
            
            rows = size(gcampSignal,1);
            cols = size(gcampSignal, 2);
            timeVector = linspace(-trialTime, trialTime, size(gcampSignal, 2) * 2 - 1);
            gcampXjrgeco = zeros(rows, cols * 2 - 1);
            
            for index = 1:rows
                gcampXjrgeco(index,:) = xcorr(gcampSignal(index,:), jrgecoSignal(index,:), 'normalized');  %TODO - think if should be normalized here or at the end
            end
            gcampXjrgeco = sum(gcampXjrgeco) / rows;
            plot(timeVector, gcampXjrgeco)
        end
        
        function plotAllSessionsSmooth(obj, descriptionVector)
            % Plots the gcamp + jrgeco signals from all the mouses sessions
            % (task or passive)
            
            % Generate Data
            [gcampSignal, jrgecoSignal, trialTime, ~] = obj.getSignals(descriptionVector);
            
            numTrials = size(gcampSignal, 1);
            
            
            gcampSignal = reshape(gcampSignal', 1, []);
            jrgecoSignal = reshape(jrgecoSignal', 1, []);
            gcampSignal = smooth(gcampSignal', 500)';
            jrgecoSignal = smooth(jrgecoSignal', 500)';
            
            % jrgecoSignal = jrgecoSignal + 4;                               % So one can see both on the same figure
            
            timeVector = linspace(0, numTrials * trialTime, size(gcampSignal, 2));
            
            % Plot
            figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            
            plot(ax, timeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            hold on;
            plot(ax, timeVector, jrgecoSignal, 'LineWidth', 2, 'Color', '#990099');
            hold off;
            
            title("Signal from all " +  descriptionVector(1) + "s of kind " + descriptionVector(end) + " for mouse " + obj.Name, 'Interpreter', 'none', 'FontSize', 12) % TODO - Fix
            
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            
            legend(gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best', 'Interpreter', 'none')
            xlabel("Time (sec)", 'FontSize', 14)
            ylabel("zscored \DeltaF/F", 'FontSize', 14)
            xlim([0 100])
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
        
        function [correlationVector, timeVector] = createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, totalTime)
            % Creats a vector that represents the sliding correlation
            % between the given signals, acoording to the given time window
            % and time shift. It returns both a vector that represents the
            % sliding correlation, and a time vector that corresponds with
            % it.
            fs = size(gcampSignal, 2) / totalTime;                          %!!!! TODO - think if this is the right calc vs. timeVector
            
            SamplesInTimeWindow = round(fs * timeWindow);
            SamplesInMovement = round(fs * timeShift);
            
            startWindowIndexVector = 1:SamplesInMovement:size(gcampSignal, 2) - SamplesInTimeWindow + 1;
            correlationVector = zeros(1, size(startWindowIndexVector, 2));
            
            for loopIndex = 1:size(startWindowIndexVector, 2)
                
                startIndex = startWindowIndexVector(loopIndex);
                lastIndex = startIndex + SamplesInTimeWindow - 1;
                
                gcampVector = gcampSignal(startIndex : lastIndex);
                jrgecoVector = jrgecoSignal(startIndex : lastIndex);
                
                correlation = corr(gcampVector', jrgecoVector');
                correlationVector(loopIndex) = correlation;
            end
            endTime = (lastIndex - 1)/ fs;                                 % Index start from 1, time from 0
            
            timeVector = linspace(0, endTime, size(correlationVector, 2));
            timeVector = timeVector + (timeWindow / 2);                    % Correlation will show in the middle of time window and not on beginning
        end
        
    end
end

