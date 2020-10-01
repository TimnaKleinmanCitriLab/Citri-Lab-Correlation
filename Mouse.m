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
        
        CONST_TASK_TRIAL_LENGTH = 20;
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
        %%%%%%%%% Constructor Functions %%%%%%%%%
        function obj = Mouse(name, gcampJrGecoReversed, listType)
            %MOUSE Construct an instance of this class
            %   Detailed explanation goes here
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
            % Create Task Info (by cue, cloud, ..)
            tInfo = obj.RawMatFile.Task.onset.t_info;
            obj.Info.Task.onset = tInfo;
            % obj.Info.Task.cloud = % TODO!
            obj.Info.Task.cue = tInfo((tInfo.plot_result ~= -1), :);            % All trials that are not premature
            obj.Info.Task.lick = tInfo((~isnan(tInfo.first_lick)), :);          % All trials that had a lick (including omissions that had a lick)
            % obj.Info.Task.movement = % TODO!
            
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
            % Normalizes / straightens the data of each day so it has same
            % baseline (calculated by correct licks)
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
            tInfo = obj.RawMatFile.Passive.t_info;
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
            listFullPath = MouseList.CONST_LIST_SAVE_PATH + obj.CONST_FOLDER_DELIMITER + listType + ".mat";
            
            if ~ isfile(listFullPath)
                mouseList = MouseList(listType);
            else
                mouseList = load(listFullPath).obj;
            end
            
            mouseList.add(obj);
        end
        
        %%%%%%%%%%%%%% Other %%%%%%%%%%%%%%
        function plotAllSessions(obj, downSampleFactor)
            % Generate Data
            numTrials = size(obj.ProcessedRawData.Task.onset.gcamp, 1);
            
            gcampSignal = obj.downSampleAndReshape(obj.ProcessedRawData.Task.onset.gcamp, downSampleFactor);
            jrGecoSignal = obj.downSampleAndReshape(obj.ProcessedRawData.Task.onset.jrgeco, downSampleFactor);
            
            jrGecoSignal = jrGecoSignal + 4;                               % So one can see both on the same figure
            
            timeVector = linspace(0, numTrials * obj.CONST_TASK_TRIAL_LENGTH, length(gcampSignal));
            
            % Plot
            figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            
            plot(ax, timeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            hold on;
            plot(ax, timeVector, jrGecoSignal, 'LineWidth', 2, 'Color', '#990099');
            hold off;
            
            title("Signal from all sessions of mouse " + obj.Name, 'Interpreter', 'none', 'FontSize', 14)
            
            [gcampType, jrgecoType] = obj.findGcampJrGecoType();

            legend(gcampType + " (gcamp)", jrgecoType + " (jrGeco)", 'Location', 'best', 'Interpreter', 'none')
            xlabel("Time (sec)", 'FontSize', 14)
            ylabel("zscored \DeltaF/F", 'FontSize', 14)
            xlim([0 100])
            
        end
        
        function plotSlidingCorrelation(obj, timeWindow, timeShift, downSampleFactor)
            % Generate Data
            gcampSignal = obj.downSampleAndReshape(obj.ProcessedRawData.Task.onset.gcamp, downSampleFactor);
            jrGecoSignal = obj.downSampleAndReshape(obj.ProcessedRawData.Task.onset.jrgeco, downSampleFactor);
            totalTime = size(obj.ProcessedRawData.Task.onset.gcamp, 1) * obj.CONST_TASK_TRIAL_LENGTH;
            
            [correlationVector, correlationTimeVector] = obj.createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrGecoSignal, totalTime);
            signalTimeVector = linspace(0, totalTime, length(gcampSignal));
            
            % Plot
            obj.plotSlidingCorrelationHelper(gcampSignal, jrGecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift)
        end
        
        %%%%%%%%%%%%%% Helpers %%%%%%%%%%%%%%
        function [gcampDifference, jrgecoDifference] = getDayDifferences(obj)
            % Creates for each day how much need to add in order to have
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
            if obj.GcampJrGecoReversed
                gcampType = obj.JRGECO;
                jrgecoType = obj.GCAMP;
            else
                gcampType = obj.GCAMP;
                jrgecoType = obj.JRGECO;
            end
        end
        
        function plotSlidingCorrelationHelper(obj, gcampSignal, jrGecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift)
            fig = figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            correlationPlot = subplot(3, 1, 1);
            gcampPlot = subplot(3, 1, 2);
            jrGecoPlot = subplot(3, 1, 3);
            
            plot(correlationPlot, correlationTimeVector, correlationVector, 'LineWidth', 2, 'Color', 'Black');
            xlim(correlationPlot, [0 50])
            ylim(correlationPlot, [-1 1])
            line(correlationPlot, [0 correlationTimeVector(length(correlationTimeVector))], [0 0], 'Color', '#C0C0C0')
            
            plot(gcampPlot, signalTimeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            xlim(gcampPlot, [0 50])
            plot(jrGecoPlot, signalTimeVector, jrGecoSignal, 'LineWidth', 2, 'Color', '#990099');
            xlim(jrGecoPlot, [0 50])
            
            gcampYLim = ylim(gcampPlot);
            jrGecoYLim = ylim(jrGecoPlot);
            
            yMin = min(gcampYLim(1), jrGecoYLim(1));
            yMax = max(gcampYLim(2), jrGecoYLim(2));
            
            ylim(gcampPlot, [yMin, yMax]);
            ylim(jrGecoPlot, [yMin, yMax]);
            
            title(correlationPlot, "Sliding Window Correlation - Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), 'FontSize', 13)
            [gcampType, jrgecoType] = obj.findGcampJrGecoType();
            title(gcampPlot, "Signal of " + gcampType +" (gcamp)", 'FontSize', 13)
            title(jrGecoPlot, "Signal of " + jrgecoType +" (jrGeco)", 'FontSize', 13)
            
            xlabel(correlationPlot, "Time (sec)")
            xlabel(gcampPlot, "Time (sec)")
            xlabel(jrGecoPlot, "Time (sec)")
            ylabel(correlationPlot, "correlation")
            ylabel(gcampPlot, "zscored \DeltaF/F")
            ylabel(jrGecoPlot, "zscored \DeltaF/F")
            
        end
        
        %%%%%%%%%%%%%% Old %%%%%%%%%%%%%%
        function oddPlotAllSessions(obj, timeWindow, downSampleFactor)
            figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            numTrials = size(obj.ProcessedRawData.Task.onset.gcamp, 1);
            
            gcampSignal = downsample(obj.ProcessedRawData.Task.onset.gcamp', downSampleFactor)'; % TODO - think if downSampling should be done after reshaping or not
            %             jrGecoSignal = downsample(obj.ProcessedRawData.Task.onset.jrgeco', downSampleFactor)'; % TODO - think if downSampling should be done after reshaping or not
            
            gcampSignal = reshape(gcampSignal, 1, []);
            %             jrGecoSignal = reshape(jrGecoSignal, 1, []);
            
            timeVector = linspace(0, numTrials * timeWindow, length(gcampSignal));
            
            plot(ax, timeVector, gcampSignal, 'LineWidth', 1);
            %             hold on;
            %             plot(timeVector, jrGecoSignal, 'LineWidth', 1);
            %             hold off;
            xlim([0 200])
            
            
            figure("Name", "2 - " + "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax2 = gca;
            numTrials = size(obj.ProcessedRawData.Task.onset.gcamp, 1);
            
            gcampSignal2 = reshape(obj.ProcessedRawData.Task.onset.gcamp', 1, []);
            %             jrGecoSignal2 = reshape(obj.ProcessedRawData.Task.onset.jrgeco', 1, []);
            
            gcampSignal2 = downsample(gcampSignal2, downSampleFactor);
            %             jrGecoSignal2 = downsample(jrGecoSignal2, downSampleFactor);
            
            timeVector2 = linspace(0, numTrials * timeWindow, length(gcampSignal2));
            
            plot(ax2, timeVector2, gcampSignal2, 'LineWidth', 1);
            %             hold on;
            %             plot(ax2, timeVector2, jrGecoSignal2, 'LineWidth', 1);
            %             hold off;
            xlim([0 200])
            
            
            figure("Name", "Raw", "NumberTitle", "off");
            ax3 = gca;
            numTrials = size(obj.ProcessedRawData.Task.onset.gcamp, 1);
            
            gcampSignal3 = reshape(obj.ProcessedRawData.Task.onset.gcamp', 1, []);
            
            timeVector3 = linspace(0, numTrials * timeWindow, length(gcampSignal3));
            
            plot(ax3, timeVector3, gcampSignal3, 'LineWidth', 1);
            xlim([0 200])
        end
        
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
        
    end
    
    methods (Static)
        %%%%%%%%%%%%%% Helpers %%%%%%%%%%%%%%
        function finalSignal = downSampleAndReshape(rawSignal, downSampleFactor)
            finalSignal = reshape(rawSignal', 1, []);
            finalSignal = downsample(finalSignal, downSampleFactor);
        end
        
        function [correlationVector, timeVector] = createSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrGecoSignal, totalTime)
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
        end
        
    end
end

