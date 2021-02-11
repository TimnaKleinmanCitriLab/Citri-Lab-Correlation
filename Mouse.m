classdef Mouse < handle
    %MOUSE class - Not supposed to be used directly but through sub-classes
    % of mouse type (OfcAccMouse etc.)
    
    properties (Constant)
        
        % General
        CONST_MOUSE_SAVE_PATH = "W:\shared\Timna\Gal Projects\Mice";
        CONST_RAW_FILE_PATH = "\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig";
        TIMES_TO_SHUFFLE = 1;
        
        % Task
        CONST_TASK_DATA_BY_CLOUD = "CueInCloud_comb_cloud.mat";
        CONST_TASK_DATA_BY_CUE = "CueInCloud_comb_cue.mat";
        CONST_TASK_DATA_BY_LICK = "CueInCloud_comb_lick.mat";
        CONST_TASK_DATA_BY_MOVEMENT = "CueInCloud_comb_movement.mat";
        CONST_TASK_DATA_BY_ONSET = "CueInCloud_comb_t_onset.mat";
        
        CONST_TASK_OUTCOMES = ["premature", "correct", "late", "omitted"]
        
        CONST_TASK_TRIAL_TIME = 20;
        CONST_TASK_TIME_BEFORE = 5;
        
        % Passive
        CONST_PASSIVE_DATA = "passive\Passive_comb.mat";
        
        CONST_PASSIVE_STATES = ["awake", "anes"]; % otherwise ["awake", "anes"]
        CONST_PASSIVE_SOUND_TYPES = ["BBN", "FS"];
        CONST_PASSIVE_TIMES = ["pre", "post"];
        
        CONST_PASSIVE_TRIAL_TIME = 5;
        
        % Free
        CONST_FREE_DATA_CONCAT = "free\Free_comb.mat";
        CONST_FREE_DATA_BY_MOVEMENT = "free\Free_comb_movement.mat";
        
        CONST_CUT_FREE_TIME = 20;
        
    end
    
    properties
        RawName
        Name
        Number
        Cage
        
        GcampJrgecoReversed
        ObjectPath
        
        RawMatFile
        Info
        ProcessedRawData
    end
    
    methods
        % ===================== Constructor Functions =====================
        % ============= Main ============
        function obj = Mouse(name, gcampJrgecoReversed, listType)
            % Constructs an instance of this class - saves it to the
            % constant path and adds it to it's relevant MouseList
            
            obj.organizeMouseName(name);
            obj.GcampJrgecoReversed = gcampJrgecoReversed;
            obj.ObjectPath = obj.CONST_MOUSE_SAVE_PATH + "\" + name + ".mat" ;
            
            obj.createMatFiles();
            
            % Task
            obj.createTaskInfo();
            obj.createAndStraightenTaskData();
            
            % Passive
            obj.createPassiveDataAndInfo();
            
            % Free
            obj.createAndStrightenFreeData();
            
            save(obj.ObjectPath, "obj");
            obj.addToList(listType);
        end
        
        function organizeMouseName(obj, name)
            % Takes the raw mouse name and saves it as a readable, "nice'
            % name. e.g. rawName = 1_from406 -> number = 1, cage = 406
            % name = 1 from 406
            obj.RawName = name;
            
            [obj.Number, remain] = strtok(name, '_');
            
            obj.Cage = extractAfter(remain, 5);                            % 5 because of '_from'
            
            obj.Name = obj.Number + " from " + obj.Cage;
        end
        
        function createMatFiles(obj)
            % For Task, Passive and Free - stores the mat files for the
            % raw data as a Mouse property.
            
            % Task
            fileBeg = obj.CONST_RAW_FILE_PATH + "\" + obj.RawName + "\";
            obj.RawMatFile.Task.onset = matfile(fileBeg + obj.CONST_TASK_DATA_BY_ONSET);
            obj.RawMatFile.Task.cloud = matfile(fileBeg + obj.CONST_TASK_DATA_BY_CLOUD);
            obj.RawMatFile.Task.cue = matfile(fileBeg + obj.CONST_TASK_DATA_BY_CUE);
            obj.RawMatFile.Task.lick = matfile(fileBeg + obj.CONST_TASK_DATA_BY_LICK);
            obj.RawMatFile.Task.movement = matfile(fileBeg + obj.CONST_TASK_DATA_BY_MOVEMENT);
            
            % Passive
            obj.RawMatFile.Passive = matfile(fileBeg + obj.CONST_PASSIVE_DATA);
            
            % Free
            obj.RawMatFile.Free.concat = matfile(fileBeg + obj.CONST_FREE_DATA_CONCAT);
            obj.RawMatFile.Free.movement = matfile(fileBeg + obj.CONST_FREE_DATA_BY_MOVEMENT);
        end
        
        function createTaskInfo(obj)
            % Organizes info for different task divisions (by cue, cloud,..)
            % and adds information about the day of the task.
            
            tInfo = obj.RawMatFile.Task.onset.t_info;
            obj.Info.Task.onset = tInfo;
            % obj.Info.Task.cloud =                   % TODO - think how to cut by cloud
            obj.Info.Task.cue = tInfo((tInfo.plot_result ~= -1), :);       % All trials that are not premature
            obj.Info.Task.lick = tInfo((~isnan(tInfo.first_lick)), :);     % All trials that had a lick (including omissions that had a lick)
            % obj.Info.Task.movement =                % TODO - think how to cut by movement
            
            % Add day to info
            tInfo = obj.RawMatFile.Task.onset.t_info;
            sessionBreaks = find(tInfo.trial_number == 1);
            sessionBreaks = [sessionBreaks; size(tInfo, 1) + 1];
            
            recordingDays = [];
            
            for index = 1:(length(sessionBreaks) - 1)
                recordingDays(sessionBreaks(index):sessionBreaks(index + 1) - 1) = index;      % Tags each recording day
            end
            
            recordingDays = categorical(recordingDays');
            
            obj.Info.Task.onset.day = double(recordingDays);
            % obj.Info.Task.cloud.day =              % TODO - add after adding info
            obj.Info.Task.cue.day = double(recordingDays(tInfo.plot_result ~= -1));
            obj.Info.Task.lick.day = double(recordingDays(~isnan(tInfo.first_lick)));
            % obj.Info.Task.movement.day =           % TODO - add after adding info
        end
        
        function createPassiveDataAndInfo(obj)
            % This function divides the passive data and info into it's
            % appropriate sections (by BBN/FS, pre/post, awake/anesthetized).
            % It then saves the results into the relevant mouse properties.
            % It also saves as a mouse property a "exist" table that saves
            % all the existing passive data names.
            
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
                            
                            % Fix jrgeco baseline to zero
                            gcampData = gcampPassive(relevantLines, :);
                            
                            jrgecoData = jrgecoPassive(relevantLines, :);
                            jrgecoData = jrgecoData - mean(jrgecoData, 'all');
                            
                            % Save data
                            obj.ProcessedRawData.Passive.(state).(soundType).(time).gcamp = gcampData;
                            obj.ProcessedRawData.Passive.(state).(soundType).(time).jrgeco = jrgecoData;
                        end
                    end
                end
            end
        end
        
        function createAndStraightenTaskData(obj)
            % Normalizes / straightens the data of each day of tasks so it
            % has same baseline (calculated by correct licks)
            % The code is taken from Gals MouseSummary class, and
            % normalize_data function
            [gcampDifference, jrgecoDifference] = obj.getDayDifferences();
            
            fields = fieldnames(obj.Info.Task);
            
            for index = 1:numel(fields)
                divideBy = fields{index};
                info = obj.Info.Task.(divideBy);
                
                gcampTrials = obj.RawMatFile.Task.(divideBy).all_trials;
                jrgecoTrials = obj.RawMatFile.Task.(divideBy).af_trials;
                
                normGcampData = gcampTrials - gcampDifference(1);          % subtract intercept (1st day / correct)
                normJrgecoData = jrgecoTrials - jrgecoDifference(1);       % subtract intercept (1st day / correct)
                
                for index = 2:length(unique(info.day))
                    normGcampData(info.day == index, :) = normGcampData(info.day == index, :) - gcampDifference(index); % remove each days' intercept
                    normJrgecoData(info.day == index, :) = normJrgecoData(info.day == index, :) - jrgecoDifference(index); % remove each days' intercept
                end
                
                obj.ProcessedRawData.Task.(divideBy).gcamp = normGcampData;
                obj.ProcessedRawData.Task.(divideBy).jrgeco = normJrgecoData;
                
            end
        end
        
        function addToList(obj, listType)
            % Adds the mouses' path to the given mouse list. If no list
            % exists, it creates a new list and then adds it.
            listFullPath = MouseList.CONST_LIST_SAVE_PATH + "\" + listType + ".mat";
            
            if ~ isfile(listFullPath)
                mouseList = MouseList(listType);
            else
                mouseList = load(listFullPath).obj;
            end
            
            mouseList.add(obj);
        end
        
        function createAndStrightenFreeData(obj)
            
            % Load Free that is concat
            
            tInfo = obj.RawMatFile.Free.concat.t_info;
            gcampFree = obj.RawMatFile.Free.concat.all_trials;
            jrgecoFree = obj.RawMatFile.Free.concat.af_trials;
            postGecoMean = 0;
            
            for rowIndex = 1:size(tInfo, 1)
                if tInfo.display(rowIndex) > 0                             % Should display
                    % Get time- pre / post
                    time = tInfo.pre_or_post(rowIndex, :);                 % Needs to be only one of pre and one of post
                    
                    % Extract signals from cell
                    gcampData = gcampFree(rowIndex);
                    gcampData = gcampData{:};
                    jrgecoData = jrgecoFree(rowIndex);
                    jrgecoData = jrgecoData{:};
                    
                    % Fix jrgeco baseline to zero
                    if (time == "post")
                        postGecoMean = mean(jrgecoData);
                    end
                    jrgecoData = jrgecoData - mean(jrgecoData);
                    
                    % Save data
                    obj.ProcessedRawData.Free.concat.(time).gcamp = gcampData;
                    obj.ProcessedRawData.Free.concat.(time).jrgeco = jrgecoData;
                end
            end
            % tInfo(tInfo.display <= 0,:) = [];                               % Delete info for rows that aren't displayed
            obj.Info.Free.general = tInfo;
            
            % Load Free by movement
            obj.Info.Free.movement = obj.RawMatFile.Free.movement.t_info;
            gcampData = obj.RawMatFile.Free.movement.all_trials;
            jrgecoData = obj.RawMatFile.Free.movement.af_trials;
            
            % Fix jrgeco baseline to zero - acoording to mean of all the signal!
            jrgecoData = jrgecoData - postGecoMean;
            
            obj.ProcessedRawData.Free.movement.post.gcamp = gcampData;
            obj.ProcessedRawData.Free.movement.post.jrgeco = jrgecoData;
            
        end
        
        % ============= Helpers =============
        function [gcampDifference, jrgecoDifference] = getDayDifferences(obj)
            % Creates for each day how much one needs to add in order to have
            % same baseline (calculated by correct licks)
            % The code is taken from Gals MouseSummary class, and
            % get_day_difference function
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
        
        % ============================= Plot ==============================
        % ============= General =============
        function plotAllSessions(obj, descriptionVector, smoothFactor, downsampleFactor)
            % Plots the gcamp and jrGeco signals from all the mouses'
            % sessions according to the description vector (see vectors
            % structure in the function getRawSignals).
            % The function first smooths the signal, then down samples it
            % and at last plots it.
            
            [gcampSignal, jrgecoSignal, timeVector, signalTitle] = obj.dataForPlotAllSessions(descriptionVector, smoothFactor, downsampleFactor);
            % gcampSignal = gcampSignal + 4;                                 % So on can see easier
            
            obj.drawAllSessions(gcampSignal, jrgecoSignal, timeVector, signalTitle, smoothFactor, downsampleFactor)
        end
        
        function plotCutSignal(obj, descriptionVector, smoothFactor, downsampleFactor)
            [gcampSignal, jrgecoSignal, signalTitle, totalTime, ~] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            timeVector = linspace(0, totalTime, size(gcampSignal, 2));
            timeVector = timeVector - 5;
            
            obj.drawCutSessions(gcampSignal, jrgecoSignal, timeVector, signalTitle, smoothFactor, downsampleFactor)
        end
        
        % =========== Correlation ===========
        function plotComparisonCorrelation(obj, smoothFactor, downsampleFactor)
            % Plots correlations of the whole signal by all the different
            % possible categories - plots each one as a scatter plot,
            % and then all of them together for comparison.
            
            obj.plotCorrelationScatterPlot(smoothFactor, downsampleFactor)
            obj.plotCorrelationBar(smoothFactor, downsampleFactor)
        end
        
        function plotCorrelationScatterPlot(obj, smoothFactor, downsampleFactor)
            % Plots scatter plot of the whole signal of all the different
            % possible categories (empty plot for a category that has no
            % data, eg. a mouse that didnt have a pre-awake-FS recording
            % session).
            % It also plots the best fit line for the scatter plot.
            % The function first smooths the signal, then down samples it
            % and at last plots it and finds the best fitting line.
            
            fig = figure("Name", "Scatter plot of signals for mouse " + obj.Name, "NumberTitle", "off", "position", [498,113,1069,767]);
            passiveAmount = (size(obj.CONST_PASSIVE_STATES, 2) * size(obj.CONST_PASSIVE_SOUND_TYPES, 2) * size(obj.CONST_PASSIVE_TIMES, 2));
            index = 1;
            
            % Passive
            for time = obj.CONST_PASSIVE_TIMES
                for state = obj.CONST_PASSIVE_STATES
                    for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                        curPlot = subplot(4, passiveAmount / 2, index);
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        
                        obj.drawScatterPlot(curPlot, descriptionVector, smoothFactor, downsampleFactor);
                        title(curPlot, (time) + " " + (state) + " " + (soundType), 'Interpreter', 'none')
                        
                        index = index + 1;
                    end
                end
            end
            
            % Free
            curPlot = subplot(4, passiveAmount / 2, index);
            descriptionVector = ["Free", "Pre"];
            obj.drawScatterPlot(curPlot, descriptionVector, smoothFactor, downsampleFactor);
            title(curPlot, "Free - pre" , 'Interpreter', 'none')
            index = index + 1;
            curPlot = subplot(4, passiveAmount / 2, index);
            descriptionVector = ["Free", "post"];
            obj.drawScatterPlot(curPlot, descriptionVector, smoothFactor, downsampleFactor);
            title(curPlot, "Free - post" , 'Interpreter', 'none')
            index = index + 1;
            
            
            % Task
            curPlot = subplot(4, passiveAmount / 2, index);
            descriptionVector = ["Task", "onset"];
            
            obj.drawScatterPlot(curPlot, descriptionVector, smoothFactor, downsampleFactor);
            title(curPlot, "Task" , 'Interpreter', 'none')
            
            sgtitle({"Scatter plot of signals for mouse " + obj.Name, "\fontsize{7}Smoothed by: " + smoothFactor + ", then down sampled by: " + downsampleFactor})
        end
        
        function plotCorrelationBar(obj, smoothFactor, downsampleFactor)
            % Plot bars that represent the comparison between the
            % correlations of all the possible categories (no bar for a
            % category that has no data, eg. a mouse that didnt have a
            % pre-awake-FS recording session).
            % The function first smooths the signals, then down samples them
            % and at last calculates their correlation and plots it.
            
            [correlationVec, xLabels] = obj.dataForPlotCorrelationBar(smoothFactor, downsampleFactor);
            obj.drawBar(correlationVec, xLabels, "Results of comparing correlations of mouse " + obj.Name, "Correlation", smoothFactor, downsampleFactor, true)
            
        end
        
        % ======= Sliding Correlation ====                                                                                                                                   ===
        function plotSlidingCorrelationAll(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the gcamp and jrgeco signals from all the mouses'
            % sessions according to the description vector (see vectors
            % structure in the function getRawSignals).
            % It then plots the sliding window correlation.
            % The function first smooths the signal, then down samples it
            % and at last calculates the sliding correlation and plots it.
            
            [gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, signalTitle] = obj.dataForPlotSlidingCorrelationAll(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor);
            obj.drawSlidingCorrelation(gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift, signalTitle, smoothFactor, downsampleFactor)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Tactical\" + obj.Name + "\Sliding Correlation Zoom - " + signalTitle)
            obj.drawSlidingCorrelationAllHeatmap(gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift, signalTitle, smoothFactor, downsampleFactor)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Tactical\" + obj.Name + "\Sliding Correlation Heatmap Over Time - " + signalTitle)
            
        end
        
        function plotSlidingCorrelationAllWithMovement(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the gcamp and jrgeco signals from all the mouses'
            % sessions according to the description vector (see vectors
            % structure in the function getRawSignals).
            % It then plots the sliding window correlation.
            % The function first smooths the signal, then down samples it
            % and at last calculates the sliding correlation and plots it.
            
            [gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, signalTitle] = obj.dataForPlotSlidingCorrelationAll(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor);
            obj.drawSlidingCorrelation(gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift, signalTitle, smoothFactor, downsampleFactor)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Tactical\" + obj.Name + "\Sliding Correlation Zoom - " + signalTitle)
            % obj.drawSlidingCorrelationAllHeatmap(gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift, signalTitle, smoothFactor, downsampleFactor)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Tactical\" + obj.Name + "\Sliding Correlation Heatmap Over Time - " + signalTitle)
            
        end
        
        function plotComparisonSlidingCorrelation(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots summary of the sliding correlations by all the different
            % possible categories - plots a comparison heatmap and a
            % comparison bar of mean / median
            
            obj.plotSlidingCorrelationHeatmap(timeWindow, timeShift, smoothFactor, downsampleFactor)
            obj.plotSlidingCorrelationBar(timeWindow, timeShift, smoothFactor, downsampleFactor)
        end
        
        function plotSlidingCorrelationHeatmap(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots heatmap of the histogram of the sliding window
            % correlation values for all possible categories (A histogram of
            % zeros for a category that has no data, eg. a mouse that didnt
            % have a pre-awake-FS recording session).
            % The function first smooths the signal, then down samples it
            % and at last calculates the sliding windows, it's relevant
            % histogram and plots the heatmap.
            
            [histogramMatrix, labels] = dataForPlotSlidingCorrelationHeatmap(obj, timeWindow, timeShift, smoothFactor, downsampleFactor);
            obj.drawSlidingCorrelationHeatmap(histogramMatrix, labels, timeWindow, timeShift, smoothFactor, downsampleFactor)
            obj.drawSlidingCorrelationHistogram(histogramMatrix, labels, timeWindow, timeShift, smoothFactor, downsampleFactor)
            %             obj.drawBar(skewness(histogramMatrix), labels, "Skewness of of sliding window correlation values for mouse " + obj.Name, "Skewness", smoothFactor, downsampleFactor, false)
        end
        
        function plotSlidingCorrelationBar(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plot bars that represent the mean / median of the sliding
            % window values of all the possible categories (no bar for a
            % category that has no data, eg. a mouse that didnt have a
            % pre-awake-FS recording session).
            % The function first smooths the signals, then down samples them
            % then calculates the sliding window, and at last calculates
            % the mean / median of it's values.
            
            [medianSlidingCorrelationVec, varSlidingCorrelationVec, xLabels] = obj.dataForPlotSlidingCorrelationBar(timeWindow, timeShift, smoothFactor, downsampleFactor);
            
            obj.drawBar(medianSlidingCorrelationVec, xLabels, "Median of sliding window correlation values for mouse " + obj.Name, "Median of sliding window correlation values", smoothFactor, downsampleFactor, true)
            obj.drawBar(varSlidingCorrelationVec, xLabels, "Variance of sliding window correlation values for mouse " + obj.Name, "Variance", smoothFactor, downsampleFactor, false)
            
        end
        
        function plotSlidingCorrelationTaskByOutcome(obj, straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            [signalTimeVector, outcomesMeanGcamp, outcomesSEMGcamp, outcomesMeanJrgeco, outcomesSEMJrgeco, slidingTimeVector, outcomeFullSliding, outcomesMeanSliding, outcomesSEMSliding, signalTitle] = obj.dataForPlotSlidingCorrelationTaskByOutcome(straightenedBy, -5, 15, timeWindow, timeShift, smoothFactor, downsampleFactor);
            
            % Draw
            figureTitle = {"Sliding Window Correlation from " + signalTitle + " for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)};
            obj.drawTaskByOutcome("sliding window", [-5, 15], signalTimeVector, outcomesMeanGcamp, outcomesSEMGcamp, outcomesMeanJrgeco, outcomesSEMJrgeco, [-5, 15],  slidingTimeVector, outcomeFullSliding, outcomesMeanSliding, outcomesSEMSliding, figureTitle, smoothFactor, downsampleFactor)
        end
        
        function plotSlidingCorrelationOmissionLick(obj, straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            lickTypesOrder = ["No Lick", "Lick"];
            
            % Get Data
            descriptionVector = ["Task", straightenedBy];
            [fullGcampSignal, fullJrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            tInfo = obj.Info.Task.(straightenedBy);
            
            outcome = "omitted";
            gcampSignalNoLick = fullGcampSignal((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :);
            jrgecoSignalNoLick = fullJrgecoSignal((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :);
            
            gcampSignalLick = fullGcampSignal((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :);
            jrgecoSignalLick = fullJrgecoSignal((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :);
            
            noLickCorrMatrix = [];
            
            for rowIndx = 1:size(gcampSignalNoLick, 1)
                [correlationVector, slidingTimeVector] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignalNoLick(rowIndx, :), jrgecoSignalNoLick(rowIndx, :), fs);
                noLickCorrMatrix = [noLickCorrMatrix; correlationVector];
            end
            
            noLickCorrMatrix = obj.sortCorrelationByStraightenedBy(noLickCorrMatrix, tInfo((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :), straightenedBy);
            
            lickCorrMatrix = [];
            for rowIndx = 1:size(gcampSignalLick, 1)
                [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignalLick(rowIndx, :), jrgecoSignalLick(rowIndx, :), fs);
                lickCorrMatrix = [lickCorrMatrix; correlationVector];
            end
            
            lickCorrMatrix = obj.sortCorrelationByStraightenedBy(lickCorrMatrix, tInfo((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :), straightenedBy);
            
            meanGcampNoLick = mean(gcampSignalNoLick,1 );
            SEMGcampNoLick = std(gcampSignalNoLick, 1)/sqrt(size(gcampSignalNoLick, 1));
            meanJrgecoNoLick = mean(jrgecoSignalNoLick, 1);
            SEMJrgecoNoLick = std(jrgecoSignalNoLick, 1)/sqrt(size(jrgecoSignalNoLick, 1));
            meanSlidingNoLick = mean(noLickCorrMatrix, 1);
            SEMSlidingNoLick = std(noLickCorrMatrix, 1)/sqrt(size(noLickCorrMatrix, 1));
            
            meanGcampLick = mean(gcampSignalLick);
            SEMGcampLick = std(gcampSignalLick, 1)/sqrt(size(gcampSignalLick, 1));
            meanJrgecoLick = mean(jrgecoSignalLick);
            SEMJrgecoLick = std(jrgecoSignalLick, 1)/sqrt(size(jrgecoSignalLick, 1));
            meanSlidingLick = mean(lickCorrMatrix);
            SEMSlidingLick = std(lickCorrMatrix, 1)/sqrt(size(lickCorrMatrix, 1));
            
            signalTimeVector = linspace(- 5, trialTime - 5, size(fullGcampSignal, 2));
            slidingTimeVector = slidingTimeVector - 5;
            
            % Plot
            meanGcamp = [meanGcampNoLick; meanGcampLick];
            SEMGcamp = [SEMGcampNoLick; SEMGcampLick];
            meanJrgeco = [meanJrgecoNoLick; meanJrgecoLick];
            SEMJrgeco = [SEMJrgecoNoLick; SEMJrgecoLick];
            corrFullMatrix = [{noLickCorrMatrix}; {lickCorrMatrix}];
            meanSliding = [meanSlidingNoLick; meanSlidingLick];
            SEMSliding = [SEMSlidingNoLick; SEMSlidingLick];
            
            figureTitle = {"Omission sliding window correlation from " + signalTitle + " for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)};
            obj.drawOmissionLick("Sliding winodw",  lickTypesOrder, [-5, 15], signalTimeVector, meanGcamp, SEMGcamp, meanJrgeco, SEMJrgeco, [-5, 15], slidingTimeVector, corrFullMatrix, meanSliding, SEMSliding, figureTitle, smoothFactor, downsampleFactor)
        end
        
        % ======= Cross Correlation =======
        function plotCrossAndAutoCorrelation(obj, descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
            
            [firstXSecond, timeVector, signalTitle] = obj.dataForPlotCrossCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
            [firstXfirst, secondXsecond, ~, ~] = obj.dataForPlotAutoCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
            
            first = obj.GCAMP;
            second = obj.JRGECO;
            
            obj.drawCrossCorrelation([firstXSecond; firstXfirst], timeVector, lim, ["Cross", "Auto - " + first], signalTitle, "Cross and Auto Correlation Between " + first + " and " + second, smoothFactor, downsampleFactor, shouldReshape)
        end
        
        function plotCrossCorrelation(obj, descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
            [firstXSecond, timeVector, signalTitle] = obj.dataForPlotCrossCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
            
            first = obj.GCAMP;
            second = obj.JRGECO;
            
            obj.drawCrossCorrelation([firstXSecond], timeVector, lim, ["Cross"], signalTitle, "Cross Correlation Between " + first + " and " + second, smoothFactor, downsampleFactor, shouldReshape)
        end
        
        function plotAutoCorrelation(obj, descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
            [gcampXgcamp, jrgecoXjrgeco, timeVector, signalTitle] = obj.dataForPlotAutoCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
            
            obj.drawCrossCorrelation([gcampXgcamp; jrgecoXjrgeco], timeVector, lim, ["Auto Gcamps", "Auto JrGeco"], signalTitle, "Auto Correlation", smoothFactor, downsampleFactor, shouldReshape)
        end
        
        function plotCrossCorrelationTaskByOutcome(obj, straightenedBy, smoothFactor, downsampleFactor)
            
            % Get Data
            descriptionVector = ["Task", straightenedBy];
            [fullGcampSignal, fullJrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            tInfo = obj.Info.Task.(straightenedBy);
            
            outcomesAmount = size(obj.CONST_TASK_OUTCOMES, 2);
            xCorrelationLen = round(fs * trialTime) * 2 + 1;
            outcomesMeanGcamp = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesSEMGcamp = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesMeanJrgeco = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesSEMJrgeco = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesFullCross = cell(outcomesAmount, 1);
            outcomesMeanCross = zeros(outcomesAmount, xCorrelationLen);
            outcomesSEMCross = zeros(outcomesAmount, xCorrelationLen);
            
            for outcomeIndx = 1:outcomesAmount
                outcome = obj.CONST_TASK_OUTCOMES(outcomeIndx);
                outcomeGcampSignal = fullGcampSignal(tInfo.trial_result == outcome, :);
                outcomeJrgecoSignal = fullJrgecoSignal(tInfo.trial_result == outcome, :);
                
                outcomeXCorrMatrix = zeros(size(outcomeGcampSignal, 1), xCorrelationLen);
                
                for rowIndx = 1:size(outcomeGcampSignal, 1)
                    [xCorrelationVector, xCorrTimeVector] = obj.getWholeCrossCorrelation(0, trialTime, outcomeGcampSignal(rowIndx, :), outcomeJrgecoSignal(rowIndx, :), fs);
                    outcomeXCorrMatrix(rowIndx, :) = xCorrelationVector;
                end
                
                outcomeXCorrMatrix = obj.sortCorrelationByStraightenedBy(outcomeXCorrMatrix, tInfo(tInfo.trial_result == outcome, :), straightenedBy);
                
                outcomesMeanGcamp(outcomeIndx, :) = mean(outcomeGcampSignal);
                outcomesSEMGcamp(outcomeIndx, :) = std(outcomeGcampSignal, 1)/sqrt(size(outcomeGcampSignal, 1));        % TODO - ask Gal
                outcomesMeanJrgeco(outcomeIndx, :) = mean(outcomeJrgecoSignal);
                outcomesSEMJrgeco(outcomeIndx, :) = std(outcomeJrgecoSignal, 1)/sqrt(size(outcomeJrgecoSignal, 1));
                
                if size(outcomeXCorrMatrix, 1) == 0
                    outcomesMeanCross(outcomeIndx, :) = zeros(1, size(outcomesMeanCross, 2));
                    outcomesSEMCross(outcomeIndx, :) = zeros(1, size(outcomesMeanCross, 2));
                    outcomesFullCross(outcomeIndx, 1) = {zeros(1, size(outcomesMeanCross, 2))};
                else
                    outcomesMeanCross(outcomeIndx, :) = mean(outcomeXCorrMatrix);
                    outcomesSEMCross(outcomeIndx, :) = std(outcomeXCorrMatrix, 1)/sqrt(size(outcomeXCorrMatrix, 1));
                    outcomesFullCross(outcomeIndx, 1) = {outcomeXCorrMatrix};
                end
            end
            
            signalTimeVector = linspace(- 5, trialTime - 5, size(fullGcampSignal, 2));
            
            % Draw
            figureTitle = {"Cross Correlation from " + signalTitle, "Between " + obj.GCAMP + " and " + obj.JRGECO, "Mouse " + obj.Name};
            obj.drawTaskByOutcome("cross correlation", [-5, 15], signalTimeVector, outcomesMeanGcamp, outcomesSEMGcamp, outcomesMeanJrgeco, outcomesSEMJrgeco, [-5, 5],  xCorrTimeVector, outcomesFullCross, outcomesMeanCross, outcomesSEMCross, figureTitle, smoothFactor, downsampleFactor)
        end
        
        function plotCrossCorrelationOmissionLick(obj, straightenedBy, smoothFactor, downsampleFactor)
            
            lickTypesOrder = ["No Lick", "Lick"];
            
            % Get Data
            descriptionVector = ["Task", straightenedBy];
            [fullGcampSignal, fullJrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            tInfo = obj.Info.Task.(straightenedBy);
            
            outcome = "omitted";
            xCorrelationLen = round(fs * trialTime) * 2 + 1;
            
            gcampSignalNoLick = fullGcampSignal((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :);
            jrgecoSignalNoLick = fullJrgecoSignal((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :);
            
            gcampSignalLick = fullGcampSignal((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :);
            jrgecoSignalLick = fullJrgecoSignal((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :);
            
            noLickCorrMatrix = zeros(size(gcampSignalNoLick, 1), xCorrelationLen);
            
            for rowIndx = 1:size(gcampSignalNoLick, 1)
                [xCorrelationVector, xCorrTimeVector] = obj.getWholeCrossCorrelation(0, trialTime, gcampSignalNoLick(rowIndx, :), jrgecoSignalNoLick(rowIndx, :), fs);
                noLickCorrMatrix(rowIndx, :) = xCorrelationVector;
            end
            
            noLickCorrMatrix = obj.sortCorrelationByStraightenedBy(noLickCorrMatrix, tInfo((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :), straightenedBy);
            
            lickCorrMatrix = zeros(size(gcampSignalLick, 1), xCorrelationLen);
            
            for rowIndx = 1:size(gcampSignalLick, 1)
                [xCorrelationVector, ~] = obj.getWholeCrossCorrelation(0, trialTime, gcampSignalLick(rowIndx, :), jrgecoSignalLick(rowIndx, :), fs);
                lickCorrMatrix(rowIndx, :) = xCorrelationVector;
            end
            
            lickCorrMatrix = obj.sortCorrelationByStraightenedBy(lickCorrMatrix, tInfo((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :), straightenedBy);
            
            meanGcampNoLick = mean(gcampSignalNoLick,1 );
            SEMGcampNoLick = std(gcampSignalNoLick, 1)/sqrt(size(gcampSignalNoLick, 1));
            meanJrgecoNoLick = mean(jrgecoSignalNoLick, 1);
            SEMJrgecoNoLick = std(jrgecoSignalNoLick, 1)/sqrt(size(jrgecoSignalNoLick, 1));
            meanXCorrNoLick = mean(noLickCorrMatrix, 1);
            SEMXCorrNoLick = std(noLickCorrMatrix, 1)/sqrt(size(noLickCorrMatrix, 1));
            
            meanGcampLick = mean(gcampSignalLick);
            SEMGcampLick = std(gcampSignalLick, 1)/sqrt(size(gcampSignalLick, 1));
            meanJrgecoLick = mean(jrgecoSignalLick);
            SEMJrgecoLick = std(jrgecoSignalLick, 1)/sqrt(size(jrgecoSignalLick, 1));
            meanXCorrLick = mean(lickCorrMatrix);
            SEMXCorrLick = std(lickCorrMatrix, 1)/sqrt(size(lickCorrMatrix, 1));
            
            signalTimeVector = linspace(- 5, trialTime - 5, size(fullGcampSignal, 2));
            
            % Plot
            meanGcamp = [meanGcampNoLick; meanGcampLick];
            SEMGcamp = [SEMGcampNoLick; SEMGcampLick];
            meanJrgeco = [meanJrgecoNoLick; meanJrgecoLick];
            SEMJrgeco = [SEMJrgecoNoLick; SEMJrgecoLick];
            corrFullMatrix = [{noLickCorrMatrix}; {lickCorrMatrix}];
            meanXCorr = [meanXCorrNoLick; meanXCorrLick];
            SEMXCorr = [SEMXCorrNoLick; SEMXCorrLick];
            
            figureTitle = {"Omission cross correlation from " + signalTitle, "Between " + obj.GCAMP + " and " + obj.JRGECO, "Mouse " + obj.Name};
            obj.drawOmissionLick("Cross correlation",  lickTypesOrder, [-5, 15], signalTimeVector, meanGcamp, SEMGcamp, meanJrgeco, SEMJrgeco, [-5, 5], xCorrTimeVector, corrFullMatrix, meanXCorr, SEMXCorr, figureTitle, smoothFactor, downsampleFactor)
        end
        
        function plotCrossCorrelationTaskByOutcomeBeginning(obj, straightenedBy, smoothFactor, downsampleFactor)
            
            % Get Data
            descriptionVector = ["Task", straightenedBy];
            [fullGcampSignal, fullJrgecoSignal, signalTitle, ~, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            SamplesInBeginning = round(fs * obj.CONST_TASK_TIME_BEFORE);
            fullGcampSignal = fullGcampSignal(:, 1:SamplesInBeginning);
            fullJrgecoSignal = fullJrgecoSignal(:, 1:SamplesInBeginning);
            tInfo = obj.Info.Task.(straightenedBy);
            
            outcomesAmount = size(obj.CONST_TASK_OUTCOMES, 2);
            xCorrelationLen = round(fs * obj.CONST_TASK_TIME_BEFORE) * 2 + 1;
            outcomesMeanGcamp = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesSEMGcamp = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesMeanJrgeco = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesSEMJrgeco = zeros(outcomesAmount, size(fullGcampSignal, 2));
            outcomesFullCross = cell(outcomesAmount, 1);
            outcomesMeanCross = zeros(outcomesAmount, xCorrelationLen);
            outcomesSEMCross = zeros(outcomesAmount, xCorrelationLen);
            
            for outcomeIndx = 1:outcomesAmount
                outcome = obj.CONST_TASK_OUTCOMES(outcomeIndx);
                outcomeGcampSignal = fullGcampSignal(tInfo.trial_result == outcome, :);
                outcomeJrgecoSignal = fullJrgecoSignal(tInfo.trial_result == outcome, :);
                
                outcomeXCorrMatrix = zeros(size(outcomeGcampSignal, 1), xCorrelationLen);
                
                for rowIndx = 1:size(outcomeGcampSignal, 1)
                    [xCorrelationVector, xCorrTimeVector] = obj.getWholeCrossCorrelation(0, obj.CONST_TASK_TIME_BEFORE, outcomeGcampSignal(rowIndx, :), outcomeJrgecoSignal(rowIndx, :), fs);
                    outcomeXCorrMatrix(rowIndx, :) = xCorrelationVector;
                end
                
                outcomeXCorrMatrix = obj.sortCorrelationByStraightenedBy(outcomeXCorrMatrix, tInfo(tInfo.trial_result == outcome, :), straightenedBy);
                
                outcomesMeanGcamp(outcomeIndx, :) = mean(outcomeGcampSignal);
                outcomesSEMGcamp(outcomeIndx, :) = std(outcomeGcampSignal, 1)/sqrt(size(outcomeGcampSignal, 1));        % TODO - ask Gal
                outcomesMeanJrgeco(outcomeIndx, :) = mean(outcomeJrgecoSignal);
                outcomesSEMJrgeco(outcomeIndx, :) = std(outcomeJrgecoSignal, 1)/sqrt(size(outcomeJrgecoSignal, 1));
                
                if size(outcomeXCorrMatrix, 1) == 0
                    outcomesMeanCross(outcomeIndx, :) = zeros(1, size(outcomesMeanCross, 2));
                    outcomesSEMCross(outcomeIndx, :) = zeros(1, size(outcomesMeanCross, 2));
                    outcomesFullCross(outcomeIndx, 1) = {zeros(1, size(outcomesMeanCross, 2))};
                else
                    outcomesMeanCross(outcomeIndx, :) = mean(outcomeXCorrMatrix);
                    outcomesSEMCross(outcomeIndx, :) = std(outcomeXCorrMatrix, 1)/sqrt(size(outcomeXCorrMatrix, 1));
                    outcomesFullCross(outcomeIndx, 1) = {outcomeXCorrMatrix};
                end
            end
            
            signalTimeVector = linspace(- 5, 0, size(fullGcampSignal, 2));
            
            % Draw
            figureTitle = {"Cross Correlation from " + signalTitle, "Between " + obj.GCAMP + " and " + obj.JRGECO, "Mouse " + obj.Name};
            obj.drawTaskByOutcome("cross correlation", [-5, 0], signalTimeVector, outcomesMeanGcamp, outcomesSEMGcamp, outcomesMeanJrgeco, outcomesSEMJrgeco, [-5, 5],  xCorrTimeVector, outcomesFullCross, outcomesMeanCross, outcomesSEMCross, figureTitle, smoothFactor, downsampleFactor)
        end
        
        function plotCrossCorrelationOmissionLickTimeWindow(obj, straightenedBy, startTime, endTime, smoothFactor, downsampleFactor)
            
            lickTypesOrder = ["No Lick", "Lick"];
            
            % Get Data
            descriptionVector = ["Task", straightenedBy];
            [gcampSignal, jrgecoSignal, signalTitle, ~, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            samplesStart = max(round(fs * (startTime + 5)), 1);                   % + 5 cause time starts at -5
            samplesEnd = min(round(fs * (endTime + 5)), size(gcampSignal , 2));% + 5 cause time starts at -5
            
            cutGcampSignal = gcampSignal(:, samplesStart:samplesEnd);
            cutJrgecoSignal = jrgecoSignal(:, samplesStart:samplesEnd);
            tInfo = obj.Info.Task.(straightenedBy);
            
            outcome = "omitted";
            xCorrelationLen = round(fs * (endTime - startTime)) * 2 + 1;
            
            gcampSignalNoLick = cutGcampSignal((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :);
            jrgecoSignalNoLick = cutJrgecoSignal((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :);
            
            gcampSignalLick = cutGcampSignal((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :);
            jrgecoSignalLick = cutJrgecoSignal((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :);
            
            noLickCorrMatrix = zeros(size(gcampSignalNoLick, 1), xCorrelationLen);
            
            for rowIndx = 1:size(gcampSignalNoLick, 1)
                [xCorrelationVector, xCorrTimeVector] = obj.getWholeCrossCorrelation(0, endTime - startTime, gcampSignalNoLick(rowIndx, :), jrgecoSignalNoLick(rowIndx, :), fs);
                noLickCorrMatrix(rowIndx, :) = xCorrelationVector;
            end
            
            noLickCorrMatrix = obj.sortCorrelationByStraightenedBy(noLickCorrMatrix, tInfo((tInfo.trial_result == outcome) & (isnan(tInfo.first_lick)), :), straightenedBy);
            
            lickCorrMatrix = zeros(size(gcampSignalLick, 1), xCorrelationLen);
            
            for rowIndx = 1:size(gcampSignalLick, 1)
                [xCorrelationVector, ~] = obj.getWholeCrossCorrelation(0, endTime - startTime, gcampSignalLick(rowIndx, :), jrgecoSignalLick(rowIndx, :), fs);
                lickCorrMatrix(rowIndx, :) = xCorrelationVector;
            end
            
            lickCorrMatrix = obj.sortCorrelationByStraightenedBy(lickCorrMatrix, tInfo((tInfo.trial_result == outcome) & (~(isnan(tInfo.first_lick))), :), straightenedBy);
            
            meanGcampNoLick = mean(gcampSignalNoLick,1 );
            SEMGcampNoLick = std(gcampSignalNoLick, 1)/sqrt(size(gcampSignalNoLick, 1));
            meanJrgecoNoLick = mean(jrgecoSignalNoLick, 1);
            SEMJrgecoNoLick = std(jrgecoSignalNoLick, 1)/sqrt(size(jrgecoSignalNoLick, 1));
            meanXCorrNoLick = mean(noLickCorrMatrix, 1);
            SEMXCorrNoLick = std(noLickCorrMatrix, 1)/sqrt(size(noLickCorrMatrix, 1));
            
            meanGcampLick = mean(gcampSignalLick);
            SEMGcampLick = std(gcampSignalLick, 1)/sqrt(size(gcampSignalLick, 1));
            meanJrgecoLick = mean(jrgecoSignalLick);
            SEMJrgecoLick = std(jrgecoSignalLick, 1)/sqrt(size(jrgecoSignalLick, 1));
            meanXCorrLick = mean(lickCorrMatrix);
            SEMXCorrLick = std(lickCorrMatrix, 1)/sqrt(size(lickCorrMatrix, 1));
            
            signalTimeVector = linspace(startTime, endTime, size(cutGcampSignal, 2));
            
            % Plot
            meanGcamp = [meanGcampNoLick; meanGcampLick];
            SEMGcamp = [SEMGcampNoLick; SEMGcampLick];
            meanJrgeco = [meanJrgecoNoLick; meanJrgecoLick];
            SEMJrgeco = [SEMJrgecoNoLick; SEMJrgecoLick];
            corrFullMatrix = [{noLickCorrMatrix}; {lickCorrMatrix}];
            meanXCorr = [meanXCorrNoLick; meanXCorrLick];
            SEMXCorr = [SEMXCorrNoLick; SEMXCorrLick];
            
            figureTitle = {"Omission cross correlation from " + signalTitle, "Between " + obj.GCAMP + " and " + obj.JRGECO, "Mouse " + obj.Name};
            obj.drawOmissionLick("Cross correlation",  lickTypesOrder, [startTime, endTime], signalTimeVector, meanGcamp, SEMGcamp, meanJrgeco, SEMJrgeco, [-(endTime - startTime), (endTime - startTime)], xCorrTimeVector, corrFullMatrix, meanXCorr, SEMXCorr, figureTitle, smoothFactor, downsampleFactor)
        end
        
        % ============= Helpers =============
        % === get data ===
        function [gcampSignal, jrgecoSignal, timeVector, signalTitle] = dataForPlotAllSessions(obj, descriptionVector, smoothFactor, downsampleFactor)
            % Returns the relevant signals smoothed and down sampled and a
            % fitting time vector to the plotAllSessions function
            
            [gcampSignal, jrgecoSignal, signalTitle, totalTime, ~] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, true);
            
            timeVector = linspace(0, totalTime, size(gcampSignal, 2));
        end
        
        function [correlationVec, xLabels] = dataForPlotCorrelationBar(obj, smoothFactor, downsampleFactor)
            % Returns a vector of correlations between the smoothed and
            % down sampled signals for each possible category.
            % It also returns a matching vector that holds all the
            % category names (xLabels).
            % This function is a helper for the plotCorrelationBar function
            
            correlationVec = [];
            xLabels = [];
            
            % Passive
            for state = obj.CONST_PASSIVE_STATES
                for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                    for time = obj.CONST_PASSIVE_TIMES
                        
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        curCorrelation = obj.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                        
                        correlationVec = [correlationVec, curCorrelation];
                        xLabels = [xLabels, (time) + ' ' + (state) + ' ' + (soundType)];
                    end
                end
            end
            
            % Task
            descriptionVector = ["Task", "onset"];
            curCorrelation = obj.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
            correlationVec = [correlationVec, curCorrelation];
            xLabels = [xLabels, "Task"];
            
            % Free
            descriptionVector = ["Free", "Pre"];
            curCorrelation = obj.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
            correlationVec = [correlationVec, curCorrelation];
            xLabels = [xLabels, "Free - pre"];
            
            descriptionVector = ["Free", "post"];
            curCorrelation = obj.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
            correlationVec = [correlationVec, curCorrelation];
            xLabels = [xLabels, "Free - post"];
        end
        
        function correlation = getWholeSignalCorrelation(obj, descriptionVector, smoothFactor, downsampleFactor, shouldShuffel)
            % Returns the correlation between gcamp and jrgeco for the
            % given description vector. If no signal exists returns zero.
            % If shouldSuffel is true shuffles TIMES_TO_SHUFFLE times and
            % then returns the maximum
            
            if obj.signalExists(descriptionVector)
                
                [gcampSignal, jrgecoSignal, ~, ~, ~] = getInformationDownsampleAndSmooth(obj, descriptionVector, smoothFactor, downsampleFactor, true);
                
                if shouldShuffel
                    correlation = -1;
                    
                    for i = 1:obj.TIMES_TO_SHUFFLE
                        idx = randperm(length(gcampSignal));
                        gcampSignal(idx) = gcampSignal;
                        % jrgecoSignal(idx) = jrgecoSignal;
                        curCorrelation = corr(gcampSignal', jrgecoSignal');
                        
                        correlation = max(correlation, curCorrelation);
                    end
                    
                else
                    correlation = corr(gcampSignal', jrgecoSignal');
                end
                
            else
                correlation = 0;
            end
        end
        
        function correlation = getWholeSignalCorrelationNoLick(obj, timeToRemove, smoothFactor, downsampleFactor, shouldShuffel)
            % Returns the correlation between gcamp and jrgeco for the
            % CONCAT task by onset after removing the lick. If no signal
            % exists returns zero.
            % If shouldSuffel is true shuffles TIMES_TO_SHUFFLE times and
            % then returns the maximum
            
            [gcampSignal, jrgecoSignal, ~] = obj.getConcatTaskNoLick(timeToRemove, smoothFactor, downsampleFactor);
            
            if shouldShuffel
                correlation = -1;
                
                for i = 1:obj.TIMES_TO_SHUFFLE
                    idx = randperm(length(gcampSignal));
                    gcampSignal(idx) = gcampSignal;
                    % jrgecoSignal(idx) = jrgecoSignal;
                    curCorrelation = corr(gcampSignal', jrgecoSignal');
                    
                    correlation = max(correlation, curCorrelation);
                end
                
            else
                correlation = corr(gcampSignal', jrgecoSignal');
            end
        end
        
        function [gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, signalTitle] = dataForPlotSlidingCorrelationAll(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns the relevant signals smoothed and down sampled, a
            % fitting time vector for the signals, a vector of the sliding
            % window correlation and a time vector for it.
            % This function is a helper for the plotSlidingCorrelation func
            
            [gcampSignal, jrgecoSignal, signalTitle, totalTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, true);
            [correlationVector, correlationTimeVector] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
            
            signalTimeVector = linspace(0, totalTime, size(gcampSignal, 2));
        end
        
        function [histogramMatrix, labels] = dataForPlotSlidingCorrelationHeatmap(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns a vector of histograms (a matrix) of the sliding
            % correlation values between the smoothed and down sampled
            % signals for each possible category.
            % It also returns a matching vector that holds all the
            % category names (labels).
            % This function is a helper for the
            % plotSlidingCorrelationHeatmap function
            
            histogramMatrix = [];
            labels = [];
            
            % Passive
            for state = obj.CONST_PASSIVE_STATES
                for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                    for time = obj.CONST_PASSIVE_TIMES
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        binCount = obj.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                        
                        histogramMatrix = [histogramMatrix, binCount'];
                        labels = [labels, (time) + ' ' + (state) + ' ' + (soundType)];
                    end
                end
            end
            
            % Task
            descriptionVector = ["Task", "onset"];
            binCount = obj.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
            
            histogramMatrix = [histogramMatrix, binCount'];
            labels = [labels, "Task"];
            
            % Free
            descriptionVector = ["Free", "pre"];
            binCount = obj.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
            histogramMatrix = [histogramMatrix, binCount'];
            labels = [labels, "Free - pre"];
            
            descriptionVector = ["Free", "post"];
            binCount = obj.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
            histogramMatrix = [histogramMatrix, binCount'];
            labels = [labels, "Free - post"];
            
        end
        
        function binCount = getWholeSignalSlidingBincount(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, shouldShuffel)
            % Returns the bin count of the sliding window values.
            % If no signal exists returns a vector of zeros.
            numOfBins = 100;
            
            if obj.signalExists(descriptionVector)
                histogramEdges = linspace(-1, 1, numOfBins + 1);           % Creates x - 1 bins
                [gcampSignal, jrgecoSignal, ~, ~, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, true);
                
                if shouldShuffel
                    idx = randperm(length(gcampSignal));
                    gcampSignal(idx) = gcampSignal;
                    %                     jrgecoSignal(idx) = jrgecoSignal;
                end
                
                [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
                
                [binCount,~] = histcounts(correlationVector, histogramEdges, 'Normalization', 'probability');
            else
                binCount = zeros(1, numOfBins);
            end
        end
        
        function [medianSlidingCorrelationVec, varSlidingCorrelationVec, xLabels] = dataForPlotSlidingCorrelationBar(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns a vector of the means and another of the medians of
            % the sliding window correlation for each possible category.
            % It also returns a matching vector that holds all the
            % category names (xLabels).
            % This function is a helper for the
            % plotSlidingCorrelationBar function
            
            medianSlidingCorrelationVec = [];
            varSlidingCorrelationVec = [];
            xLabels = [];
            
            % Passive
            for state = obj.CONST_PASSIVE_STATES
                for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                    for time = obj.CONST_PASSIVE_TIMES
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        
                        [curMedianSlidingCorrelation, curVarSlidingCorrelation] = obj.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                        medianSlidingCorrelationVec = [medianSlidingCorrelationVec, curMedianSlidingCorrelation];
                        varSlidingCorrelationVec = [varSlidingCorrelationVec, curVarSlidingCorrelation];
                        
                        xLabels = [xLabels, (time) + ' ' + (state) + ' ' + (soundType)];
                        
                    end
                end
            end
            
            % Task
            descriptionVector = ["Task", "onset"];
            [curMedianSlidingCorrelation, curVarSlidingCorrelation] = obj.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
            medianSlidingCorrelationVec = [medianSlidingCorrelationVec, curMedianSlidingCorrelation];
            varSlidingCorrelationVec = [varSlidingCorrelationVec, curVarSlidingCorrelation];
            
            xLabels = [xLabels, "Task"];
            
            % Free
            descriptionVector = ["Free", "pre"];
            [curMedianSlidingCorrelation, curVarSlidingCorrelation] = obj.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
            medianSlidingCorrelationVec = [medianSlidingCorrelationVec, curMedianSlidingCorrelation];
            varSlidingCorrelationVec = [varSlidingCorrelationVec, curVarSlidingCorrelation];
            xLabels = [xLabels, "Free - pre"];
            
            descriptionVector = ["Free", "post"];
            [curMedianSlidingCorrelation, curVarSlidingCorrelation] = obj.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
            medianSlidingCorrelationVec = [medianSlidingCorrelationVec, curMedianSlidingCorrelation];
            varSlidingCorrelationVec = [varSlidingCorrelationVec, curVarSlidingCorrelation];
            xLabels = [xLabels, "Free - post"];
        end
        
        function [medianSlidingCorrelation, varSlidingCorrelation] = getWholeSignalSlidingMedian(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, shouldShuffel)
            % Returns the mean and median of the sliding window correlation
            % for the given description vector CONCAT. If no signal exists returns
            % zero. If shouldShuffel is true shuffles TIMES_TO_SHUFFLE
            % times and - returns the maximum correlation and the maximum
            % variance (even if it isn't from the same shuffle)
            
            if obj.signalExists(descriptionVector)
                [gcampSignal, jrgecoSignal, ~, ~, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, true);
                
                if shouldShuffel
                    medianSlidingCorrelation = -1;
                    varSlidingCorrelation = 0;
                    
                    for i = 1:obj.TIMES_TO_SHUFFLE
                        idx = randperm(length(gcampSignal));
                        gcampSignal(idx) = gcampSignal;
                        % jrgecoSignal(idx) = jrgecoSignal;
                        
                        [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
                        
                        medianSlidingCorrelation = max(medianSlidingCorrelation, median(correlationVector));
                        varSlidingCorrelation = max(varSlidingCorrelation, var(correlationVector));
                    end
                else
                    [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
                    medianSlidingCorrelation = median(correlationVector);
                    varSlidingCorrelation = var(correlationVector);
                end
                
                
            else
                medianSlidingCorrelation = 0;
                varSlidingCorrelation = 0;
                
            end
        end
        
        function [medianSlidingCorrelation, varSlidingCorrelation] = getWholeSignalSlidingMedianNoLick(obj, timeWindow, timeShift, smoothFactor, downsampleFactor, shouldShuffel)
            % Returns the mean and median of the sliding window correlation
            % for the CONCAT task by onset after removing the lick. If no
            % signal exists returns zero. If shouldShuffel is true shuffles
            % TIMES_TO_SHUFFLE times and - returns the maximum correlation
            % and the maximum variance (even if it isn't from the same shuffle)
            
            [gcampSignal, jrgecoSignal, fs] = obj.getConcatTaskNoLick(smoothFactor, downsampleFactor);
            
            if shouldShuffel
                medianSlidingCorrelation = -1;
                varSlidingCorrelation = 0;
                
                for i = 1:obj.TIMES_TO_SHUFFLE
                    idx = randperm(length(gcampSignal));
                    gcampSignal(idx) = gcampSignal;
                    
                    [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
                    
                    medianSlidingCorrelation = max(medianSlidingCorrelation, median(correlationVector));
                    varSlidingCorrelation = max(varSlidingCorrelation, var(correlationVector));
                end
            else
                [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
                medianSlidingCorrelation = median(correlationVector);
                varSlidingCorrelation = var(correlationVector);
            end
            
        end
        
        function [firstXSecond, timeVector, signalTitle, maxLag] = dataForPlotCrossCorrelation(obj, descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
            % Returns the cross correlation between the first signal and
            % the second (reversed gcamp and geco if reversed in mouse)
            
            if shouldReshape
                [gcampSignal, jrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, true);
                
            else
                [gcampSignal, jrgecoSignal, trialTime, fs, signalTitle] = obj.getRawSignals(descriptionVector);
                
                smoothedGcampSignal = zeros(size(gcampSignal, 1), size(gcampSignal, 2));
                smoothedJrgecoSignal = zeros(size(gcampSignal, 1), size(gcampSignal, 2));
                
                for index = 1:size(gcampSignal, 1)
                    smoothedGcampSignal(index,:) = smooth(gcampSignal(index,:)', smoothFactor)';
                    smoothedJrgecoSignal(index,:) = smooth(jrgecoSignal(index,:)', smoothFactor)';
                end
                
                gcampSignal = downsample(smoothedGcampSignal', downsampleFactor)';
                jrgecoSignal = downsample(smoothedJrgecoSignal', downsampleFactor)';
                fs = fs / downsampleFactor;
            end
            
            [firstXSecond, timeVector] = obj.getWholeCrossCorrelation(maxLag, trialTime, gcampSignal, jrgecoSignal, fs);
        end
        
        function [firstXSecond, timeVector] = getWholeCrossCorrelation(obj, maxLag, trialTime, gcampSignal, jrgecoSignal, fs)
            if maxLag == 0
                maxLag = trialTime;
            end
            
            if obj.GcampJrgecoReversed
                temp = gcampSignal;
                gcampSignal = jrgecoSignal;
                jrgecoSignal = temp;
            end
            
            rows = size(gcampSignal, 1);
            
            timeVector = linspace(-maxLag, maxLag, round(fs * maxLag) * 2 + 1);
            firstXSecond = zeros(rows, round(fs * maxLag) * 2 + 1);
            
            for index = 1:rows
                firstXSecond(index,:) = xcorr(gcampSignal(index,:), jrgecoSignal(index,:), round(fs * maxLag), 'normalized');               % TODO - think if should normalize before or after
            end
            
            firstXSecond = sum(firstXSecond, 1) / rows;
        end
        
        function [firstXfirst, secondXsecond, timeVector, signalTitle, maxLag] = dataForPlotAutoCorrelation(obj, descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
            [gcampSignal, jrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, shouldReshape);
            
            if maxLag == 0
                maxLag = trialTime;
            end
            
            if obj.GcampJrgecoReversed
                temp = gcampSignal;
                gcampSignal = jrgecoSignal;
                jrgecoSignal = temp;
            end
            
            rows = size(gcampSignal, 1);
            
            timeVector = linspace(-maxLag, maxLag, round(fs * maxLag) * 2 + 1);
            firstXfirst = zeros(rows, round(fs * maxLag) * 2 + 1);
            secondXsecond = zeros(rows, round(fs * maxLag) * 2 + 1);
            
            for index = 1:rows
                firstXfirst(index,:) = xcorr(gcampSignal(index,:), round(fs * maxLag), 'normalized');
                secondXsecond(index,:) = xcorr(jrgecoSignal(index,:), round(fs * maxLag), 'normalized');
            end
            firstXfirst = sum(firstXfirst, 1) / rows;
            secondXsecond = sum(secondXsecond, 1) / rows;
        end
        
        function [signalTimeVector, cutGcampSignal, cutJrgecoSignal, slidingTimeVector, SlidingMeanInTimePeriod, signalTitle]  = dataForPlotSlidingCorrelation(obj, descriptionVector, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns a sliding correlation vector for a time period in
            % the cut task (meaning somewhere between -5 and 15)
            
            % Get Data
            [fullGcampSignal, fullJrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            
            SamplesStart = max(round(fs * (startTime + 5)), 1);                    % + 5 cause time starts at -5
            SamplesEnd = min(round(fs * (endTime + 5)), size(fullGcampSignal , 2));% + 5 cause time starts at -5
            cutGcampSignal = fullGcampSignal(:, SamplesStart:SamplesEnd);
            cutJrgecoSignal = fullJrgecoSignal(:, SamplesStart:SamplesEnd);
            
            allOutcumesSlidingCorrMatrix = [];
            
            for rowIndx = 1:size(cutGcampSignal, 1)
                [correlationVector, slidingTimeVector] = obj.getSlidingCorrelation(timeWindow, timeShift, cutGcampSignal(rowIndx, :), cutJrgecoSignal(rowIndx, :), fs);
                % if timeWindow < 2
                    % correlationVector = smooth(correlationVector', 10)';
                % end
                allOutcumesSlidingCorrMatrix = [allOutcumesSlidingCorrMatrix; correlationVector];
            end
            
            SlidingMeanInTimePeriod = mean(allOutcumesSlidingCorrMatrix);
            
            % Time vectors
            signalTimeVector = linspace(- 5, trialTime - 5, size(cutGcampSignal, 2));
            slidingTimeVector = slidingTimeVector - 5;
        end
        
        function [signalTimeVector, noLickCutGcamp, noLickCutJrgeco, slidingTimeVector, SlidingMeanInTimePeriod, signalTitle]  = dataForPlotSlidingCorrelationTaskNoLick(obj, straightenedBy, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns a sliding correlation vector for the time period in
            % the cut task (meaning somewhere between -5 and 15) only for
            % trials that have no lick
            
            % Get Data
            descriptionVector = ["Task", straightenedBy];
            [fullGcampSignal, fullJrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            
            tInfo = obj.Info.Task.(straightenedBy);
            
            SamplesStart = max(round(fs * (startTime + 5)), 1);                    % + 5 cause time starts at -5
            SamplesEnd = min(round(fs * (endTime + 5)), size(fullGcampSignal , 2));% + 5 cause time starts at -5
            cutGcampSignal = fullGcampSignal(:, SamplesStart:SamplesEnd);
            cutJrgecoSignal = fullJrgecoSignal(:, SamplesStart:SamplesEnd);
            
            noLickCutGcamp = cutGcampSignal(isnan(tInfo.first_lick), :); % Optional -  & tInfo.cue_int == 1
            noLickCutJrgeco = cutJrgecoSignal(isnan(tInfo.first_lick), :); % Optional -  & tInfo.cue_int == 1
            
            allOutcumesSlidingCorrMatrix = [];
            
            for rowIndx = 1:size(noLickCutGcamp, 1)
                [correlationVector, slidingTimeVector] = obj.getSlidingCorrelation(timeWindow, timeShift, noLickCutGcamp(rowIndx, :), noLickCutJrgeco(rowIndx, :), fs);
                % if timeWindow < 2
                % correlationVector = smooth(correlationVector', 10)';
                % end
                allOutcumesSlidingCorrMatrix = [allOutcumesSlidingCorrMatrix; correlationVector];
            end
            
            SlidingMeanInTimePeriod = mean(allOutcumesSlidingCorrMatrix);
            
            % Time vectors
            signalTimeVector = linspace(- 5, trialTime - 5, size(noLickCutGcamp, 2));
            slidingTimeVector = slidingTimeVector - 5;
        end
        
        function [signalTimeVector, outcomesMeanGcamp, outcomesSEMGcamp, outcomesMeanJrgeco, outcomesSEMJrgeco, slidingTimeVector, outcomeFullSliding, outcomesMeanSliding, outcomesSEMSliding, signalTitle]  = dataForPlotSlidingCorrelationTaskByOutcome(obj, straightenedBy, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns a sliding correlation vector for the time period in
            % the cut task (meaning somewhere between -5 and 15) for each
            % possible outcome
            
            % Init
            descriptionVector = ["Task", straightenedBy];
            [fullGcampSignal, fullJrgecoSignal, signalTitle, trialTime, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            
            SamplesStart = max(round(fs * (startTime + 5)), 1);                    % + 5 cause time starts at -5
            SamplesEnd = min(round(fs * (endTime + 5)), size(fullGcampSignal , 2));% + 5 cause time starts at -5
            cutGcampSignal = fullGcampSignal(:, SamplesStart:SamplesEnd);
            cutJrgecoSignal = fullJrgecoSignal(:, SamplesStart:SamplesEnd);
            
            tInfo = obj.Info.Task.(straightenedBy);
            
            outcomesAmount = size(obj.CONST_TASK_OUTCOMES, 2);
            outcomesMeanGcamp = zeros(outcomesAmount, size(cutGcampSignal, 2));
            outcomesSEMGcamp = zeros(outcomesAmount, size(cutGcampSignal, 2));
            outcomesMeanJrgeco = zeros(outcomesAmount, size(cutGcampSignal, 2));
            outcomesSEMJrgeco = zeros(outcomesAmount, size(cutGcampSignal, 2));
            outcomeFullSliding = cell(outcomesAmount, 1);
            outcomesMeanSliding = [];
            outcomesSEMSliding = [];
            
            % By outcomes
            for outcomeIndx = 1:outcomesAmount
                outcome = obj.CONST_TASK_OUTCOMES(outcomeIndx);
                outcomeGcampSignal = cutGcampSignal(tInfo.trial_result == outcome, :);
                outcomeJrgecoSignal = cutJrgecoSignal(tInfo.trial_result == outcome, :);
                
                outcomeSlidingCorrMatrix = [];
                
                for rowIndx = 1:size(outcomeGcampSignal, 1)
                    [correlationVector, slidingTimeVector] = obj.getSlidingCorrelation(timeWindow, timeShift, outcomeGcampSignal(rowIndx, :), outcomeJrgecoSignal(rowIndx, :), fs);
                    %                     if timeWindow < 2
                    %                         correlationVector = smooth(correlationVector', 10)';
                    %                     end
                    outcomeSlidingCorrMatrix = [outcomeSlidingCorrMatrix; correlationVector];
                end
                
                outcomeSlidingCorrMatrix = obj.sortCorrelationByStraightenedBy(outcomeSlidingCorrMatrix, tInfo(tInfo.trial_result == outcome, :), straightenedBy);
                
                outcomesMeanGcamp(outcomeIndx, :) = mean(outcomeGcampSignal);
                outcomesSEMGcamp(outcomeIndx, :) = std(outcomeGcampSignal, 1)/sqrt(size(outcomeGcampSignal, 1));
                outcomesMeanJrgeco(outcomeIndx, :) = mean(outcomeJrgecoSignal);
                outcomesSEMJrgeco(outcomeIndx, :) = std(outcomeJrgecoSignal, 1)/sqrt(size(outcomeJrgecoSignal, 1));
                
                if size(outcomeSlidingCorrMatrix, 2) == 0
                    slidingWindowSize = 1:round(fs * timeShift):size(cutGcampSignal, 2) - round(fs * timeWindow) + 1;  % Size of sliding window
                    outcomesMeanSliding = [outcomesMeanSliding; zeros(1, size(slidingWindowSize, 2))];
                    outcomesSEMSliding = [outcomesSEMSliding; zeros(1, size(slidingWindowSize, 2))];
                    outcomeFullSliding(outcomeIndx, 1) = {zeros(1, size(slidingWindowSize, 2))};
                else
                    outcomesMeanSliding = [outcomesMeanSliding; mean(outcomeSlidingCorrMatrix)];
                    outcomesSEMSliding = [outcomesSEMSliding; std(outcomeSlidingCorrMatrix, 1)/sqrt(size(outcomeSlidingCorrMatrix, 1))];
                    outcomeFullSliding(outcomeIndx, 1) = {outcomeSlidingCorrMatrix};
                end
            end
            
            % Time vectors
            signalTimeVector = linspace(- 5, trialTime - 5, size(cutGcampSignal, 2));
            slidingTimeVector = slidingTimeVector - 5;
        end
        
        % ==== draw ====
        function drawAllSessions(obj, gcampSignal, jrgecoSignal, timeVector, signalTitle, smoothFactor, downsampleFactor)
            % Draws the plot for the plotAllSessions function.
            
            figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            
            plot(ax, timeVector, gcampSignal, 'LineWidth', 1.5, 'Color', '#009999');
            hold on;
            plot(ax, timeVector, jrgecoSignal, 'LineWidth', 1.5, 'Color', '#990099');
            hold off;
            
            title(ax, {"Signal From: " +  signalTitle, "Mouse: " + obj.Name, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor}, 'FontSize', 12) % TODO - Fix
            
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            
            legend(gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best', 'Interpreter', 'none')
            xlabel("Time (sec)", 'FontSize', 14)
            ylabel("zscored \DeltaF/F", 'FontSize', 14)
            xlim([0 100])
            
        end
        
        function drawCutSessions(obj, gcampSignal, jrgecoSignal, timeVector, signalTitle, smoothFactor, downsampleFactor)
            % Draws the plot for the plotAllSessions function.
            
            figure("Name", "Signal from cut sessions of mouse " + obj.Name, "NumberTitle", "off");
            ax = gca;
            
            meanGcamp = mean(gcampSignal, 1);
            SEMGcamp = std(gcampSignal, 1)/sqrt(size(gcampSignal, 1));
            
            meanJrgeco = mean(jrgecoSignal, 1);
            SEMJrgeco = std(jrgecoSignal, 1)/sqrt(size(jrgecoSignal, 1));
            
            gcampLine = shadedErrorBar(timeVector, meanGcamp, SEMGcamp, 'r').mainLine;
            hold on;
            jrgecoLine = shadedErrorBar(timeVector, meanJrgeco, SEMJrgeco, 'b').mainLine;
            hold off;
            
            title(ax, {"Cut Signal From: " +  signalTitle, "Mouse: " + obj.Name, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor}, 'FontSize', 12) % TODO - Fix
            
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            
            legend([gcampLine, jrgecoLine], gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best', 'Interpreter', 'none')
            xlabel("Time (sec)", 'FontSize', 14)
            ylabel("zscored \DeltaF/F", 'FontSize', 14)
            xlim([-5 15])
            
        end
        
        function drawScatterPlot(obj, curPlot, descriptionVector, smoothFactor, downsampleFactor)
            % Draws the scatter plot for the plotCorrelationScatterPlot
            % function. In order to have all the scatter plots on the same
            % window (figure) it receives the plot and doesn't create it
            % itself.
            
            if obj.signalExists(descriptionVector)
                [gcampSignal, jrgecoSignal, ~, ~, ~] = getInformationDownsampleAndSmooth(obj, descriptionVector, smoothFactor, downsampleFactor, true);
                
                [gcampType, jrgecoType] = obj.findGcampJrgecoType();
                
                scatter(curPlot, gcampSignal, jrgecoSignal, 5,'filled');
                
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
        
        function drawSlidingCorrelation(obj, gcampSignal, jrgecoSignal, signalTimeVector, slidingCorrelation, correlationTimeVector, timeWindow, timeShift, signalTitle, smoothFactor, downsampleFactor)
            % Draws the plots for the plotSlidingCorrelationAll function
            
            fig = figure("Name", "Sliding window correlation for all sessions of mouse " + obj.Name, "NumberTitle", "off");
            correlationPlot = subplot(2, 1, 1);
            signalPlot = subplot(2, 1, 2);
            
            plot(correlationPlot, correlationTimeVector, slidingCorrelation, 'LineWidth', 2, 'Color', 'Black');
            xlim(correlationPlot, [0 50])
            ylim(correlationPlot, [-1 1])
            line(correlationPlot, [0 correlationTimeVector(size(correlationTimeVector, 2))], [0 0], 'Color', '#C0C0C0')
            
            plot(signalPlot, signalTimeVector, gcampSignal, 'LineWidth', 2, 'Color', '#009999');
            hold on
            plot(signalPlot, signalTimeVector, jrgecoSignal, 'LineWidth', 2, 'Color', '#990099');
            hold off
            xlim(signalPlot, [0 50])
            
            title(correlationPlot, {"\fontsize{5}", "\fontsize{14}Sliding Window"}, 'FontWeight', 'normal')
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            title(signalPlot, {"\fontsize{5}", "\fontsize{14}Signals"}, 'FontWeight', 'normal')
            
            xlabel(correlationPlot, "Time (sec)")
            xlabel(signalPlot, "Time (sec)")
            ylabel(correlationPlot, "correlation")
            ylabel(signalPlot, "zscored \DeltaF/F")
            
            sgtitle({"Sliding Window Correlation from " + signalTitle + " for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor}, 'FontWeight', 'bold')
            
            % Add movement
            movementTimes = obj.Info.Free.movement;
            hold(correlationPlot, 'on')
            hold(signalPlot, 'on')
            
            correlationYLim = ylim(correlationPlot);
            signalYLim = ylim(signalPlot);
            
            for i = 1:size(movementTimes, 1)
                curOnset = movementTimes.onset(i);
                curOffset = movementTimes.offset(i);
                
                f = fill(correlationPlot, [curOnset, curOnset, curOffset, curOffset], [correlationYLim(1), correlationYLim(2), correlationYLim(2), correlationYLim(1)], 'y');
                set(f,'FaceAlpha',0.1);
                
                f = fill(signalPlot, [curOnset, curOnset, curOffset, curOffset], [signalYLim(1), signalYLim(2), signalYLim(2), signalYLim(1)], 'y');
                set(f,'FaceAlpha',0.1);
            end
            
            ylim(correlationPlot, correlationYLim)
            ylim(signalPlot, signalYLim)
            
            hold(correlationPlot, 'off')
            hold(signalPlot, 'off')
            
            legend(signalPlot, gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best')
            
        end
        
        function drawSlidingCorrelationAllHeatmap(obj, gcampSignal, jrgecoSignal, signalTimeVector, slidingCorrelation, correlationTimeVector, timeWindow, timeShift, signalTitle, smoothFactor, downsampleFactor)
            % Draws a heatmap over time of the sliding correlation, plots
            % it for the plotSlidingCorrelationAll function
            
            fig = figure("Name", "Sliding window correlation for all sessions of mouse " + obj.Name, "NumberTitle", "off");
            slidingPlot = subplot(3, 1, 1);
            heatmapPlot = subplot(3, 1, 2);
            signalPlot = subplot(3, 1, 3);
            
            % plot sliding
            plot(slidingPlot, correlationTimeVector, slidingCorrelation, 'LineWidth', 0.5, 'Color', 'Black');
            ylim(slidingPlot, [-1 1])
            xlim(slidingPlot, [0 max(correlationTimeVector)])
            line(slidingPlot, [0 correlationTimeVector(size(correlationTimeVector, 2))], [0 0], 'Color', '#C0C0C0')
            
            % Heatmap Sliding
            % p = pcolor(correlationPlot, slidingCorrelation, 'LineStyle', 'none');
            colormap(winter)
            slidingCorrelation = smooth(slidingCorrelation', 10)';
            imagesc(heatmapPlot, slidingCorrelation);
            cBar = colorbar(slidingPlot);
            ylabel(cBar, 'Correlation', 'Rotation',270)
            cBar.Label.VerticalAlignment = 'bottom';
            
            % Signal
            plot(signalPlot, signalTimeVector, gcampSignal, 'LineWidth', 0.5, 'Color', '#009999');
            hold on
            plot(signalPlot, signalTimeVector, jrgecoSignal, 'LineWidth', 0.5, 'Color', '#990099');
            hold off
            % xlim(signalPlot, [0 50])
            
            title(heatmapPlot, {"\fontsize{5}", "\fontsize{14}Sliding Window"}, 'FontWeight', 'normal')
            title(heatmapPlot, {"\fontsize{5}", "\fontsize{14}Sliding Window Heatmap"}, 'FontWeight', 'normal')
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            title(signalPlot, {"\fontsize{5}", "\fontsize{14}Signals"}, 'FontWeight', 'normal')
            
            legend(signalPlot, gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best')
            
            xlabel(slidingPlot, "Time (sec)")
            xlabel(heatmapPlot, "Time (sec)")
            xlabel(signalPlot, "Time (sec)")
            ylabel(slidingPlot, "correlation")
            ylabel(signalPlot, "zscored \DeltaF/F")
            
            sgtitle({"Sliding Window Correlation from " + signalTitle + " for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor}, 'FontWeight', 'bold')
        end
        
        function drawSlidingCorrelationHeatmap(obj, histogramMatrix, labels, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Draws the plots for the plotSlidingCorrelationHeatmap function
            
            % Heatmap
            fig = figure("Name", "Comparison Sliding Window Correlation for mouse " + obj.Name, "NumberTitle", "off");
            ax = axes;
            
            ax.YLabel.String = 'correlation';
            imagesc(ax, [0, size(histogramMatrix, 2)-1], [1, -1], histogramMatrix) % Limits are 1 to -1 so 1 will be up and -1 down, need to change ticks too
            cBar = colorbar;
            ylabel(cBar, 'Probability', 'Rotation',270)
            cBar.Label.VerticalAlignment = 'bottom';
            ax.YTickLabel = 1:-0.2:-1;                                     % TODO - Fix!
            ax.XTickLabel = labels;
            ax.TickLabelInterpreter = 'none';
            xtickangle(ax, -30)
            title(ax, {"Sliding Window Heatmap for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            line(ax, [-0.5, size(labels, 2)], [0, 0], 'Color', 'black')
        end
        
        function drawSlidingCorrelationHistogram(obj, histogramMatrix, labels, timeWindow, timeShift, smoothFactor, downsampleFactor)
            fig = figure();
            ax = axes;
            x = [-0.99: 0.02: 0.99];
            xLabels = [];
            
            for index = 5:size(histogramMatrix, 2)
                smoothed = histogramMatrix(:,index)';
                if labels(index) ~= "Task"
                    smoothed = smooth(smoothed', 5)';
                end
                plot(x, smoothed, 'LineWidth', 1.5)
                hold on
                xLabels = [xLabels, labels(index)];
            end
            hold off
            
            ax.XLabel.String = 'Correlation';
            ax.YLabel.String = 'Amount';
            legend(xLabels, 'Location', 'best')
            
            title(ax, {"Sliding Window Histogram for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            
        end
        
        function drawBar(obj, vector, xLabels, figureTitle, yLable, smoothFactor, downsampleFactor, oneToMinusOne)
            % Draws a bar graph according to the vector, where the xLabels
            % are the categories, and all the other arguments are for the
            % title and lables.
            
            fig = figure("Name", "Results of mouse " + obj.Name, "NumberTitle", "off");
            ax = axes;
            categories = categorical(xLabels);
            categories = reordercats(categories,xLabels);
            bar(ax, categories, vector);
            set(ax,'TickLabelInterpreter','none')
            title(ax, {figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            ylabel(yLable)
            
            minY = min(vector);
            maxY = max(vector);
            
            if oneToMinusOne
                if (minY < 0) && (0 < maxY)
                    ylim(ax, [-1, 1])
                elseif (0 < maxY)                                              % for sure 0 <= minY
                    ylim(ax, [0, 1])
                else
                    ylim(ax, [-1, 0])
                end
            end
        end
        
        function drawCrossCorrelation(obj, crossSignalList, timeVector, lim, legendList, signalTitle, CrossType, smoothFactor, downsampleFactor, shouldReshape)
            % Draws the plot for the plotCrossCorrelation function.
            fig = figure();
            
            ax = gca;
            
            for idx = 1:size(crossSignalList, 1)
                plot(ax, timeVector, crossSignalList(idx,:), 'LineWidth', 1.5);
                hold on
            end
            hold off
            
            legend(legendList, 'Location', 'best')
            set(0,'DefaultLegendAutoUpdate','off')
            
            [gcampType, jrgecoType] = obj.findGcampJrgecoType();
            
            title(ax, {CrossType,  signalTitle, "Mouse: " + obj.Name, "\fontsize{9}" + gcampType + " = gcamp" + ", " + jrgecoType + " = jrGeco", "Concatenated: " + shouldReshape, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor}, 'FontSize', 12)
            
            xlabel("Time Shift (sec)", 'FontSize', 14)
            ylabel("Cross Correlation (normalized)", 'FontSize', 14)
            
            yline(ax, 0, 'Color', [192, 192, 192]/255)
            xline(ax, 0, 'Color', [192, 192, 192]/255)
            xlim(ax, [-lim, lim])
        end
        
        function drawTaskByOutcome(obj, corrType, signalLimits, signalTimeVector, outcomesMeanGcamp, outcomesSEMGcamp, outcomesMeanJrgeco, outcomesSEMJrgeco, corrLimits,  corrTimeVector, outcomesFullCorr, outcomesMeanCorr, outcomesSEMCorr, figureTitle, smoothFactor, downsampleFactor)
            fig = figure('position', [249,170,1387,757]);
            outcomesAmount = size(obj.CONST_TASK_OUTCOMES, 2);
            
            for outcomeIndx = 1:outcomesAmount
                % Signal
                signalAx = subplot(3, outcomesAmount, outcomeIndx);
                
                outGcamp = shadedErrorBar(signalTimeVector, outcomesMeanGcamp(outcomeIndx, :), outcomesSEMGcamp(outcomeIndx, :), 'b');
                hold(signalAx, 'on')
                outJrgeco = shadedErrorBar(signalTimeVector, outcomesMeanJrgeco(outcomeIndx, :), outcomesSEMJrgeco(outcomeIndx, :), 'r');
                hold(signalAx, 'off')
                
                if outcomeIndx == outcomesAmount
                    [gcampType, jrgecoType] = obj.findGcampJrgecoType();
                    legend(signalAx, [outGcamp.mainLine, outJrgeco.mainLine], [gcampType + "\fontsize{7} gcamp", jrgecoType + "\fontsize{7} geco"])
                    set(0,'DefaultLegendAutoUpdate','off')
                end
                
                title(signalAx, "Mean signal for " + obj.CONST_TASK_OUTCOMES(outcomeIndx), 'Interpreter', 'none')
                line(signalAx, signalLimits, [0 0], 'Color', '#C0C0C0')
                yl = ylim(signalAx);
                line(signalAx, [0, 0], yl, 'Color', '#C0C0C0')
                xlim(signalAx, signalLimits)
                ylim(signalAx, yl)
                
                % Heatmap
                heatmapAx = subplot(3, outcomesAmount, outcomeIndx + outcomesAmount);
                
                currSliding = outcomesFullCorr(outcomeIndx, 1);
                currSliding = currSliding{:};
                im = imagesc(heatmapAx, currSliding);
                im.XData = linspace(corrLimits(1), corrLimits(2), size(currSliding, 2));
                
                title(heatmapAx, "Heatmap of " + corrType + " for " + obj.CONST_TASK_OUTCOMES(outcomeIndx), 'Interpreter', 'none')
                xlim(heatmapAx, corrLimits);
                ylim(heatmapAx, [0, size(currSliding, 1)]);
                hold on
                line(heatmapAx, [0 0], [0 size(currSliding, 1)], 'Color', 'black')
                hold off
                
                % Corr
                corrAx = subplot(3, outcomesAmount, outcomeIndx + outcomesAmount * 2);
                
                shadedErrorBar(corrTimeVector, outcomesMeanCorr(outcomeIndx, :), outcomesSEMCorr(outcomeIndx, :), 'b');
                
                title(corrAx, "Mean " + corrType + " for " + obj.CONST_TASK_OUTCOMES(outcomeIndx), 'Interpreter', 'none')
                line(corrAx, corrLimits, [0 0], 'Color', '#C0C0C0')
                xlim(corrAx, corrLimits)
                ylim(corrAx, [-0.5, 0.5])
                line(corrAx, [0, 0], [-1, 1], 'Color', '#C0C0C0')
            end
            
            sgtitle([figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor], 'FontWeight', 'bold')
            
        end
        
        function drawOmissionLick(obj, corrType, lickTypesOrder, signalLimits, signalTimeVector, meanGcamp, SEMGcamp, meanJrgeco, SEMJrgeco, corrLimits, corrTimeVector, corrFullMatrix, meanCorr, SEMCorr, figureTitle, smoothFactor, downsampleFactor)
            % Draw Plots
            fig = figure('position', [558,165,874,757]);
            lickTypeAmount = size(lickTypesOrder, 2);                           % Only Lick and No Lick
            
            for lickTypeIndx = 1:lickTypeAmount
                lickType = lickTypesOrder(lickTypeIndx);
                
                % Signal
                signalAx = subplot(3, lickTypeAmount, lickTypeIndx);
                
                outGcamp = shadedErrorBar(signalTimeVector, meanGcamp(lickTypeIndx, :), SEMGcamp(lickTypeIndx, :), 'b');
                hold(signalAx, 'on')
                outJrgeco = shadedErrorBar(signalTimeVector, meanJrgeco(lickTypeIndx, :), SEMJrgeco(lickTypeIndx, :), 'r');
                hold(signalAx, 'off')
                if lickTypeIndx == lickTypeAmount
                    [gcampType, jrgecoType] = obj.findGcampJrgecoType();
                    legend(signalAx, [outGcamp.mainLine, outJrgeco.mainLine], [gcampType + "\fontsize{7} gcamp", jrgecoType + "\fontsize{7} geco"])
                    set(0,'DefaultLegendAutoUpdate','off')
                end
                
                title(signalAx, "Mean signal for omission - " + lickType, 'Interpreter', 'none')
                line(signalAx, signalLimits, [0 0], 'Color', '#C0C0C0')
                yl = ylim(signalAx);
                line(signalAx, [0, 0], yl, 'Color', '#C0C0C0')
                xlim(signalAx, signalLimits)
                ylim(yl)
                
                % Heatmap
                heatmapAx = subplot(3, lickTypeAmount, lickTypeIndx + lickTypeAmount);
                lickTypeCorrMatrix = corrFullMatrix(lickTypeIndx);
                lickTypeCorrMatrix = lickTypeCorrMatrix{:};
                
                im = imagesc(heatmapAx, lickTypeCorrMatrix);
                
                title(heatmapAx, "Heatmap of " + corrType + " for " + lickType, 'Interpreter', 'none')
                im.XData = linspace(corrLimits(1), corrLimits(2), size(lickTypeCorrMatrix, 2));
                xlim(heatmapAx, corrLimits);
                ylim(heatmapAx, [0, size(lickTypeCorrMatrix, 1)]);
                hold on
                line(heatmapAx, [0 0], [0 size(lickTypeCorrMatrix, 1)], 'Color', 'black')
                hold off
                
                % Corr
                corrAx = subplot(3, lickTypeAmount, lickTypeIndx + lickTypeAmount * 2);
                
                shadedErrorBar(corrTimeVector, meanCorr(lickTypeIndx, :), SEMCorr(lickTypeIndx, :), 'b');
                
                [~, lagIndex] = max(meanCorr(lickTypeIndx, :));
                
                title(corrAx, {"Mean " + corrType + " for omission - " + lickType, "Lag of - " + corrTimeVector(lagIndex)},'Interpreter', 'none')
                line(corrAx, corrLimits, [0 0], 'Color', '#C0C0C0')
                xlim(corrAx, corrLimits)
                ylim(corrAx, [-0.5, 0.5])
                line(corrAx, [0, 0], [-1, 1], 'Color', '#C0C0C0')
            end
            
            sgtitle([figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor], 'FontWeight', 'bold')
        end
        
        % ======================== General Helpers ========================
        function [gcampSignal, jrgecoSignal, trialTime, fs, signalTitle] = getRawSignals(obj, descriptionVector)
            % Returns the raw gcamp and jrGeco signals, along with the
            % relevant time of each trial (each row in of the signal), the
            % frequency sample (fs) of the signal and a title that explains
            % the signal. The function returns the data according to the
            % given description vector:
            % For Task signals - ["Task", "divideBy"],
            %      for example ["Task", "lick"]
            % For Passive signal - ["Passive", "state", "soundType", "time"],
            %         for example ["Passive", "awake", "BBN", "post"]
            % If there is no such signal, raises an error.
            
            if obj.signalExists(descriptionVector)
                
                if descriptionVector(1) == "Task"                          % Task
                    cutBy = descriptionVector(2);
                    gcampSignal = obj.ProcessedRawData.Task.(cutBy).gcamp;
                    jrgecoSignal = obj.ProcessedRawData.Task.(cutBy).jrgeco;
                    trialTime = obj.CONST_TASK_TRIAL_TIME;
                    fs = size(gcampSignal, 2) / trialTime;
                    signalTitle = "Task cut by " + cutBy;
                elseif descriptionVector(1) == "Passive"                   % Passive
                    state = descriptionVector(2);
                    soundType = descriptionVector(3);
                    time = descriptionVector(4);
                    gcampSignal = obj.ProcessedRawData.Passive.(state).(soundType).(time).gcamp;
                    jrgecoSignal = obj.ProcessedRawData.Passive.(state).(soundType).(time).jrgeco;
                    trialTime = obj.CONST_PASSIVE_TRIAL_TIME;
                    fs = size(gcampSignal, 2) / trialTime;
                    signalTitle = (time) + " " + (state) + " " + (soundType);
                elseif descriptionVector(1) == "Free"                      % Free
                    cutBy = descriptionVector(2);
                    time = descriptionVector(3);
                    gcampSignal = obj.ProcessedRawData.Free.(cutBy).(time).gcamp;
                    jrgecoSignal = obj.ProcessedRawData.Free.(cutBy).(time).jrgeco;
                    fs = obj.Info.Free.general.fs(1);                              % All fs are suppoed to be the same - change if not!
                    trialTime = obj.CONST_CUT_FREE_TIME;
                    if (cutBy == "concat")
                        trialTime = round(size(gcampSignal, 2) / fs);
                    end
                    signalTitle = "Free " + time +  " - " + cutBy;
                end
                
            else
                error("Problem with given description vector. Should be one of the following:" + newline +...
                    "For Task signals - [Task, divideBy]" +  newline +...
                    "For Passive signal - [Passive, state, soundType, time]");
            end
        end
        
        function [exists] = signalExists(obj, descriptionVector)
            % Returns true if the signal specified in the description
            % vector exists, and false otherwise.
            % For an explanation on how the description vector should be
            % built, look at the description of the function getRawSignals.
            
            if descriptionVector(1) == "Task"                              % Task
                cutBy = descriptionVector(2);
                if cutBy == "onset" || cutBy == "lick" || ...
                        cutBy == "cue" || cutBy == "movement" || ...
                        cutBy == "cloud"
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
            elseif descriptionVector(1) == "Free" && isfield(obj.ProcessedRawData,"Free")   % Free
                cutBy = descriptionVector(2);
                time = descriptionVector(3);
                if cutBy == "movement" && time == "post"
                    exists = true;
                elseif cutBy == "concat" && isfield(obj.ProcessedRawData.Free.concat, time)
                    exists = true;
                else
                    exists = false;
                end
            else
                exists = false;
            end
        end
        
        function [gcampType, jrgecoType] = findGcampJrgecoType(obj)
            % Returns the brain area of gcamp and area of jrGeco in this
            % mouse
            if obj.GcampJrgecoReversed
                gcampType = obj.JRGECO;
                jrgecoType = obj.GCAMP;
            else
                gcampType = obj.GCAMP;
                jrgecoType = obj.JRGECO;
            end
        end
        
        function [gcampSignal, jrgecoSignal, signalTitle, totalTime, fs] = getInformationDownsampleAndSmooth(obj, descriptionVector, smoothFactor, downsampleFactor, shouldReshape)
            % Returns the signals (according to the description vector)
            % after first concatenating each one to a continuous signal
            % then smoothing them and then down sampling them.
            % It also returns basic data about the signals - their title,
            % the total time (of the continuous signal) and the sampling
            % per second (fs).
            % If there is no such signal, raises an error
            
            if shouldReshape
                [gcampSignal, jrgecoSignal, trialTime, fs, signalTitle] = obj.getRawSignals(descriptionVector);
                
                totalTime = size(gcampSignal, 1) * trialTime;
                
                gcampSignal = reshape(gcampSignal', 1, []);
                jrgecoSignal = reshape(jrgecoSignal', 1, []);
                
                gcampSignal = smooth(gcampSignal', smoothFactor)';
                jrgecoSignal = smooth(jrgecoSignal', smoothFactor)';
                
                gcampSignal = downsample(gcampSignal, downsampleFactor);
                jrgecoSignal = downsample(jrgecoSignal, downsampleFactor);
                fs = fs / downsampleFactor;
                
            else
                [gcampSignal, jrgecoSignal, trialTime, fs, signalTitle] = obj.getRawSignals(descriptionVector);
                
                totalTime = trialTime;
                
                smoothedGcampSignal = zeros(size(gcampSignal, 1), size(gcampSignal, 2));
                smoothedJrgecoSignal = zeros(size(gcampSignal, 1), size(gcampSignal, 2));
                
                for index = 1:size(gcampSignal, 1)
                    smoothedGcampSignal(index,:) = smooth(gcampSignal(index,:)', smoothFactor)';
                    smoothedJrgecoSignal(index,:) = smooth(jrgecoSignal(index,:)', smoothFactor)';
                end
                
                gcampSignal = downsample(smoothedGcampSignal', downsampleFactor)';
                jrgecoSignal = downsample(smoothedJrgecoSignal', downsampleFactor)';
                fs = fs / downsampleFactor;
            end
        end
        
        function [gcampSignal, jrgecoSignal, fs] = getConcatTaskNoLick(obj, timeToRemove, smoothFactor, downsampleFactor)
            % Returns the signals (according to the description vector)
            % after first concatenating each one to a continuous signal
            % then smoothing them and then down sampling them.
            % It also returns basic data about the signals - their title,
            % the total time (of the continuous signal) and the sampling
            % per second (fs).
            % If there is no such signal, raises an error
            
            windowBefore = 0.25;
            
            % Get data
            [gcampSignal, jrgecoSignal, ~, fs, ~] = obj.getRawSignals(["Task", "onset"]);
            amountOfTrials = size(gcampSignal, 1);
            samplesInTrial = size(gcampSignal, 2);
            samplesInTimeWindow = round(fs * (timeToRemove + windowBefore));
             
            % Concat and get data ready
            gcampSignal = reshape(gcampSignal', 1, []);
            jrgecoSignal = reshape(jrgecoSignal', 1, []);
            
            gcampSignal = smooth(gcampSignal', smoothFactor)';
            jrgecoSignal = smooth(jrgecoSignal', smoothFactor)';
            
            trialBegSample = 1:samplesInTrial:size(gcampSignal, 2);
            lickTimes = obj.Info.Task.onset.first_lick;
            startLickSample = trialBegSample' + round(fs * (lickTimes + 5 - windowBefore));
            endLickSample = startLickSample + samplesInTimeWindow - 1;
            
            gcampLickData = zeros(size(lickTimes, 1), samplesInTimeWindow);
            jrgecoLickData = zeros(size(gcampLickData));
            
            for trialIdx = 1:amountOfTrials
                if ~isnan(lickTimes(trialIdx))                             % There was a lick
                    % Save the lick aside
                    gcampLickData(trialIdx, :) = gcampSignal(1, startLickSample(trialIdx):endLickSample(trialIdx));
                    jrgecoLickData(trialIdx, :) = jrgecoSignal(1, startLickSample(trialIdx):endLickSample(trialIdx));
                    
                    % Remove the lick
                    gcampSignal(1, startLickSample(trialIdx):endLickSample(trialIdx)) = nan;
                    jrgecoSignal(1, startLickSample(trialIdx):endLickSample(trialIdx)) = nan;
                else
                    gcampLickData(trialIdx, :) = nan(1, samplesInTimeWindow);
                    jrgecoLickData(trialIdx, :) = nan(1, samplesInTimeWindow);
                end
            end
            
            gcampSignal=(gcampSignal(~isnan(gcampSignal)));
            jrgecoSignal=(jrgecoSignal(~isnan(jrgecoSignal)));
            
            gcampSignal = downsample(gcampSignal, downsampleFactor);
            jrgecoSignal = downsample(jrgecoSignal, downsampleFactor);
            
            fs = fs / downsampleFactor;
        end
        
        function slidingMeanInTimePeriod = getSlidingCorrelationForTimeWindowInTask(obj,  descriptionVector, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            % Get Data
            [fullGcampSignal, fullJrgecoSignal, ~, ~, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, false);
            
            SamplesStart = max(round(fs * (startTime + 5)), 1);                    % + 5 cause time starts at -5
            SamplesEnd = min(round(fs * (endTime + 5)), size(fullGcampSignal , 2));% + 5 cause time starts at -5
            cutGcampSignal = fullGcampSignal(:, SamplesStart:SamplesEnd);
            cutJrgecoSignal = fullJrgecoSignal(:, SamplesStart:SamplesEnd);
            
            % Overall Sliding in time period
            allOutcumesSlidingCorrMatrix = [];
            
            for rowIndx = 1:size(cutGcampSignal, 1)
                [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, cutGcampSignal(rowIndx, :), cutJrgecoSignal(rowIndx, :), fs);
                if timeWindow < 2
                    correlationVector = smooth(correlationVector', 10)';
                end
                allOutcumesSlidingCorrMatrix = [allOutcumesSlidingCorrMatrix; correlationVector];
            end
            
            slidingMeanInTimePeriod = mean(allOutcumesSlidingCorrMatrix);
            
        end
        
    end
    
    methods (Static)
        % ============================= Plot ==============================
        % ============= Helpers =============
        function [correlationVector, timeVector] = getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs)
            % Creates a vector that represents the sliding correlation
            % between the given signals, according to the given time window
            % and time shift. It returns both a vector that represents the
            % sliding correlation, and a time vector that corresponds with
            % it.
            
            samplesInTimeWindow = round(fs * timeWindow);
            samplesInMovement = round(fs * timeShift);
            
            startWindowIndexVector = 1:samplesInMovement:size(gcampSignal, 2) - samplesInTimeWindow + 1;  % +1 becuase includes the begining point
            correlationVector = zeros(1, size(startWindowIndexVector, 2));
            
            for loopIndex = 1:size(startWindowIndexVector, 2)
                
                startIndex = startWindowIndexVector(loopIndex);
                lastIndex = startIndex + samplesInTimeWindow - 1;          % -1 becuase includes the begining point
                
                gcampVector = gcampSignal(startIndex : lastIndex);
                jrgecoVector = jrgecoSignal(startIndex : lastIndex);
                
                correlation = corr(gcampVector', jrgecoVector');
                correlationVector(loopIndex) = correlation;
            end
            endTime = (startIndex - 1)/ fs;                                 % Index start from 1, time from 0
            
            timeVector = linspace(0, endTime, size(correlationVector, 2));
            timeVector = timeVector + (timeWindow / 2);                    % Correlation will show in the middle of time window and not on beginning
        end
        
        function [sortedCorrelation] = sortCorrelationByStraightenedBy(correlation, fittingTInfo, straightenedBy)
            switch straightenedBy
                case "cue"
                    [~,order] = sort(fittingTInfo.cue_int);
                    sortedCorrelation = correlation(order, :);
                case "lick"
                    [~,order] = sort(fittingTInfo.is_light);
                    sortedCorrelation = correlation(order, :);
                case "onset"
                    [~,order] = sort(fittingTInfo.delay);
                    sortedCorrelation = correlation(order, :);
                    %                 otherwise
                    %                     sortedCorrelation = correlation;
            end
        end
        
    end
end
