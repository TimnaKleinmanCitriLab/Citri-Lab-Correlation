classdef Mouse < handle
    %MOUSE class - Not supposed to be used directly but through sub-classes
    % of mouse type (OfcAccMouse etc.)
    
    properties (Constant)
        
        % General
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
        
        % Free
        CONST_FREE_DATA = "free\Free_comb.mat";
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
            obj.RawMatFile.Task.onset = matfile(fileBeg + obj.CONST_DATA_BY_ONSET);
            obj.RawMatFile.Task.cloud = matfile(fileBeg + obj.CONST_DATA_BY_CLOUD);
            obj.RawMatFile.Task.cue = matfile(fileBeg + obj.CONST_DATA_BY_CUE);
            obj.RawMatFile.Task.lick = matfile(fileBeg + obj.CONST_DATA_BY_LICK);
            obj.RawMatFile.Task.movement = matfile(fileBeg + obj.CONST_DATA_BY_MOVEMENT);
            
            % Passive
            obj.RawMatFile.Passive = matfile(fileBeg + obj.CONST_PASSIVE_DATA);
            
            % Free
            obj.RawMatFile.Free = matfile(fileBeg + obj.CONST_FREE_DATA);
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
            obj.drawAllSessions(gcampSignal, jrgecoSignal, timeVector, signalTitle, smoothFactor, downsampleFactor)       
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
                        curPlot = subplot(3, passiveAmount / 2, index);
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        
                        obj.drawScatterPlot(curPlot, descriptionVector, smoothFactor, downsampleFactor);
                        title(curPlot, (time) + " " + (state) + " " + (soundType), 'Interpreter', 'none')
                        
                        index = index + 1;
                    end
                end
            end
            
            % Task
            curPlot = subplot(3, passiveAmount / 2, index);
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
            obj.drawBar(correlationVec, xLabels, "Results of comparing correlations of mouse " + obj.Name, "Correlation", smoothFactor, downsampleFactor)
            
        end
        
        % ======= Sliding Correlation =======
        function plotSlidingCorrelation(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the gcamp and jrgeco signals from all the mouses'
            % sessions according to the description vector (see vectors
            % structure in the function getRawSignals).
            % It then plots the sliding window correlation.
            % The function first smooths the signal, then down samples it
            % and at last calculates the sliding correlation and plots it.
            
            [gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, signalTitle] = obj.dataForPlotSlidingCorrelation(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor);
            obj.drawSlidingCorrelation(gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, timeWindow, timeShift, signalTitle, smoothFactor, downsampleFactor)
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
            
        end
        
        function plotSlidingCorrelationBar(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plot bars that represent the mean / median of the sliding
            % window values of all the possible categories (no bar for a
            % category that has no data, eg. a mouse that didnt have a 
            % pre-awake-FS recording session).
            % The function first smooths the signals, then down samples them
            % then calculates the sliding window, and at last calculates
            % the mean / median of it's values.
            
            [meanSlidingCorrelationVec, medianSlidingCorrelationVec, xLabels] = obj.dataForPlotSlidingCorrelationBar(timeWindow, timeShift, smoothFactor, downsampleFactor);
            
            obj.drawBar(meanSlidingCorrelationVec, xLabels, "Mean of sliding window correlation values for mouse " + obj.Name, "Mean of sliding window correlation values", smoothFactor, downsampleFactor)
            obj.drawBar(medianSlidingCorrelationVec, xLabels, "Median of sliding window correlation values for mouse " + obj.Name, "Median of sliding window correlation values", smoothFactor, downsampleFactor)
        end
        
        % ============= Helpers =============
        % === get data ===
        function [gcampSignal, jrgecoSignal, timeVector, signalTitle] = dataForPlotAllSessions(obj, descriptionVector, smoothFactor, downsampleFactor)
            % Returns the relevant signals smoothed and down sampled and a
            % fitting time vector to the plotAllSessions function
            
            [gcampSignal, jrgecoSignal, signalTitle, totalTime, ~] = obj.getInformationReshapeDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor);
            
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
                        curCorrelation = obj.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor);
                        
                        correlationVec = [correlationVec, curCorrelation];
                        xLabels = [xLabels, (time) + ' ' + (state) + ' ' + (soundType)];
                    end
                end
            end
            
            % Task
            descriptionVector = ["Task", "onset"];
            curCorrelation = obj.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor);
            correlationVec = [correlationVec, curCorrelation];
            xLabels = [xLabels, "Task"];
        end
        
        function correlation = getWholeSignalCorrelation(obj, descriptionVector, smoothFactor, downsampleFactor)
            % Returns the correlation between gcamp and jrgeco for the
            % given description vector. If no signal exists returns zero.
            if obj.signalExists(descriptionVector)
                
                [gcampSignal, jrgecoSignal, ~, ~, ~] = getInformationReshapeDownsampleAndSmooth(obj, descriptionVector, smoothFactor, downsampleFactor);
                correlation = corr(gcampSignal', jrgecoSignal');
                
            else
                correlation = 0;
            end
        end
        
        function [gcampSignal, jrgecoSignal, signalTimeVector, correlationVector, correlationTimeVector, signalTitle] = dataForPlotSlidingCorrelation(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns the relevant signals smoothed and down sampled, a
            % fitting time vector for the signals, a vector of the sliding
            % window correlation and a time vector for it.
            % This function is a helper for the plotSlidingCorrelation func
            
            [gcampSignal, jrgecoSignal, signalTitle, totalTime, fs] = obj.getInformationReshapeDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor);
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
                        binCount = obj.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor);
                        
                        histogramMatrix = [histogramMatrix, binCount'];
                        labels = [labels, (time) + ' ' + (state) + ' ' + (soundType)];
                    end
                end
            end
            
            % Task
            descriptionVector = ["Task", "onset"];
            binCount = obj.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor);
            
            histogramMatrix = [histogramMatrix, binCount'];
            labels = [labels, "Task"];
        end
        
        function binCount = getWholeSignalSlidingBincount(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns the bin count of the sliding window values. 
            % If no signal exists returns a vector of zeros.
            numOfBins = 100;
            
            if obj.signalExists(descriptionVector)
                histogramEdges = linspace(-1, 1, numOfBins + 1);           % Creates x - 1 bins
                [gcampSignal, jrgecoSignal, ~, ~, fs] = obj.getInformationReshapeDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor);
                [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
                
                [binCount,~] = histcounts(correlationVector, histogramEdges, 'Normalization', 'probability');
            else
                binCount = zeros(1, numOfBins);
            end
        end
        
        function [meanSlidingCorrelationVec, medianSlidingCorrelationVec, xLabels] = dataForPlotSlidingCorrelationBar(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns a vector of the means and another of the medians of
            % the sliding window correlation for each possible category.
            % It also returns a matching vector that holds all the
            % category names (xLabels).
            % This function is a helper for the
            % plotSlidingCorrelationBar function
            
            medianSlidingCorrelationVec = [];
            meanSlidingCorrelationVec = [];
            xLabels = [];
            
            % Passive
            for state = obj.CONST_PASSIVE_STATES
                for soundType = obj.CONST_PASSIVE_SOUND_TYPES
                    for time = obj.CONST_PASSIVE_TIMES
                        descriptionVector = ["Passive", (state), (soundType), (time)];
                        
                        [curMeanSlidingCorrelation, curMedianSlidingCorrelation] = obj.getWholeSignalSlidingMeanAndMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor);
                        meanSlidingCorrelationVec = [meanSlidingCorrelationVec, curMeanSlidingCorrelation];
                        medianSlidingCorrelationVec = [medianSlidingCorrelationVec, curMedianSlidingCorrelation];
                        
                        xLabels = [xLabels, (time) + ' ' + (state) + ' ' + (soundType)];
                        
                    end
                end
            end
            
            % Task
            descriptionVector = ["Task", "onset"];
            [curMeanSlidingCorrelation, curMedianSlidingCorrelation] = obj.getWholeSignalSlidingMeanAndMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor);
            meanSlidingCorrelationVec = [meanSlidingCorrelationVec, curMeanSlidingCorrelation];
            medianSlidingCorrelationVec = [medianSlidingCorrelationVec, curMedianSlidingCorrelation];
            
            xLabels = [xLabels, "Task"];
        end
        
        function [meanSlidingCorrelation, medianSlidingCorrelation] = getWholeSignalSlidingMeanAndMedian(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns the mean and median of the sliding window correlation
            % for the given description vector. If no signal exists returns
            % zero.
            if obj.signalExists(descriptionVector)
                [gcampSignal, jrgecoSignal, ~, ~, fs] = obj.getInformationReshapeDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor);
                
                [correlationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, gcampSignal, jrgecoSignal, fs);
                meanSlidingCorrelation = mean(correlationVector);
                medianSlidingCorrelation = median(correlationVector);
                
            else
                meanSlidingCorrelation = 0;
                medianSlidingCorrelation = 0;
                
            end
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
        
        function drawScatterPlot(obj, curPlot, descriptionVector, smoothFactor, downsampleFactor)
            % Draws the scatter plot for the plotCorrelationScatterPlot
            % function. In order to have all the scatter plots on the same
            % window (figure) it receives the plot and doesn't create it
            % itself.
            
            if obj.signalExists(descriptionVector)
                [gcampSignal, jrgecoSignal, ~, ~, ~] = getInformationReshapeDownsampleAndSmooth(obj, descriptionVector, smoothFactor, downsampleFactor);
                
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
            % Draws the plots for the PlotSlidingCorrelation function
            
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
            
            legend(signalPlot, gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best')
            
            xlabel(correlationPlot, "Time (sec)")
            xlabel(signalPlot, "Time (sec)")
            ylabel(correlationPlot, "correlation")
            ylabel(signalPlot, "zscored \DeltaF/F")
            
            sgtitle({"Sliding Window Correlation from " + signalTitle + " for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor}, 'FontWeight', 'bold')
        end
        
        function drawSlidingCorrelationHeatmap(obj, histogramMatrix, labels, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Draws the plots for the plotSlidingCorrelationHeatmap function
            
            fig = figure("Name", "Comparison Sliding Window Correlation for mouse " + obj.Name, "NumberTitle", "off");
            ax = axes;
            
            ax.YLabel.String = 'correlation';
            imagesc(ax, [0, size(histogramMatrix, 2)-1], [1, -1], histogramMatrix) % Limits are 1 to -1 so 1 will be up and -1 down, need to change ticks too
            cBar = colorbar;
            ylabel(cBar, 'Probability', 'Rotation',270)
            cBar.Label.VerticalAlignment = 'bottom';
            % ax.YTick = -1:-0.2:1;
            ax.YTickLabel = 1:-0.2:-1;                                     % TODO - Fix!
            ax.XTickLabel = labels;
            ax.TickLabelInterpreter = 'none';
            xtickangle(ax, -30)
            title(ax, {"Sliding Window Heatmap for mouse " + obj.Name, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            line(ax, [-0.5, size(labels, 2)], [0, 0], 'Color', 'black')
        end
        
        function drawBar(obj, vector, xLabels, figureTitle, yLable, smoothFactor, downsampleFactor)
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
            
            if (minY < 0) && (0 < maxY)
                ylim(ax, [-1, 1])
            elseif (0 < maxY)                                              % for sure 0 <= minY
                ylim(ax, [0, 1])
            else
                ylim(ax, [-1, 0])
            end
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
                    %%%%%%% TODO %%%%%%
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
        
        function [gcampSignal, jrgecoSignal, signalTitle, totalTime, fs] = getInformationReshapeDownsampleAndSmooth(obj, descriptionVector, smoothFactor, downsampleFactor)
            % Returns the signals (according to the description vector) 
            % after first concatenating each one to a continuous signal
            % then smoothing them and then down sampling them.
            % It also returns basic data about the signals - their title,
            % the total time (of the continuous signal) and the sampling
            % per second (fs).
            % If there is no such signal, raises an error
            
            [gcampSignal, jrgecoSignal, trialTime, fs, signalTitle] = obj.getRawSignals(descriptionVector);
            
            totalTime = size(gcampSignal, 1) * trialTime;
            
            gcampSignal = reshape(gcampSignal', 1, []);
            jrgecoSignal = reshape(jrgecoSignal', 1, []);
            
            gcampSignal = smooth(gcampSignal', smoothFactor)';
            jrgecoSignal = smooth(jrgecoSignal', smoothFactor)';
            
            gcampSignal = downsample(gcampSignal, downsampleFactor);
            jrgecoSignal = downsample(jrgecoSignal, downsampleFactor);
            fs = fs / downsampleFactor;
            
        end
        
        % ============================== Old ==============================
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
            [gcampSignal, jrgecoSignal, trialTime, ~, ~] = getRawSignals(obj, descriptionVector);
            
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

