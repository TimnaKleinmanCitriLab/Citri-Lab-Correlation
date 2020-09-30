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
    end
    
    properties
        Name
        GcampJrGecoReversed
        RawMatFile
        Info
        StraightenedData
        ObjectPath
    end
    
    methods
        % Constructor Functions
        function obj = Mouse(name, gcampJrGecoReversed, listType)
            %MOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj.Name = name;
            obj.GcampJrGecoReversed = gcampJrGecoReversed;
            obj.ObjectPath = obj.CONST_MOUSE_SAVE_PATH + obj.CONST_FOLDER_DELIMITER + name + ".mat" ;
            
            obj.createMatFiles();
            obj.createTrialsInfo();
            obj.straightenData();
            
            save(obj.ObjectPath, "obj");
            obj.addToList(listType);
        end
        
        function createMatFiles(obj)
            % Create matFiles
            fileBeg = obj.CONST_RAW_FILE_PATH + obj.CONST_FOLDER_DELIMITER + obj.Name + obj.CONST_FOLDER_DELIMITER;
            obj.RawMatFile.onset = matfile(fileBeg + obj.CONST_DATA_BY_ONSET);
            % obj.RawMatFile.cloud = matfile(fileBeg + obj.CONST_DATA_BY_CLOUD);
            obj.RawMatFile.cue = matfile(fileBeg + obj.CONST_DATA_BY_CUE);
            obj.RawMatFile.lick = matfile(fileBeg + obj.CONST_DATA_BY_LICK);
            % obj.RawMatFile.movement = matfile(fileBeg + obj.CONST_DATA_BY_MOVEMENT);
        end
        
        function createTrialsInfo(obj)
            % Create Trials Info (by cue, cloud, ..)
            tInfo = obj.RawMatFile.onset.t_info;
            obj.Info.onset = tInfo;
            % obj.Info.cloud = % TODO!
            obj.Info.cue = tInfo((tInfo.plot_result ~= -1), :); % All trials that are not premature
            obj.Info.lick = tInfo((~isnan(tInfo.first_lick)), :); % All trials that had a lick (including omissions that had a lick)
            % obj.Info.movement = % TODO!
            
            % Add day to info
            tInfo = obj.RawMatFile.onset.t_info;
            sessionBreaks = find(tInfo.trial_number == 1);
            sessionBreaks = [sessionBreaks; size(tInfo, 1) + 1];
            
            recordingDays = [];
            
            for indx = 1:(length(sessionBreaks) - 1)
                recordingDays(sessionBreaks(indx):sessionBreaks(indx + 1) - 1) = indx;      % Tags each recording day
            end
            
            recordingDays = categorical(recordingDays');
            
            obj.Info.onset.day = double(recordingDays);
            % obj.Info.cloud.day = % TODO!
            obj.Info.cue.day = double(recordingDays(tInfo.plot_result ~= -1));
            obj.Info.lick.day = double(recordingDays(~isnan(tInfo.first_lick)));
            % obj.Info.movement.day = % TODO!
        end
        
        function straightenData(obj)
            % Normalizes / straightens the data of each day so it has same
            % baseline (calculated by correct licks)
            dayDifferences = obj.getDayDifferences();
            [gcampDifference, jrgecoDifference] = dayDifferences{:};
            
            fields = fieldnames(obj.Info);
            
            for fieldIndex = 1:numel(fields)
                fieldName = fields{fieldIndex};
                info = obj.Info.(fieldName);
                
                gcampTrials = obj.RawMatFile.(fieldName).all_trials;
                jrgecoTrials = obj.RawMatFile.(fieldName).af_trials;
                
                normGcampData = gcampTrials - gcampDifference(1); % subtract intercept (1st day / correct)
                normJrgecoData = jrgecoTrials - jrgecoDifference(1); % subtract intercept (1st day / correct)
                
                for indx = 2:length(unique(info.day))
                    normGcampData(info.day == indx, :) = normGcampData(info.day == indx, :) - gcampDifference(indx); % remove each days' intercept
                    normJrgecoData(info.day == indx, :) = normJrgecoData(info.day == indx, :) - jrgecoDifference(indx); % remove each days' intercept
                end
                
                obj.StraightenedData.(fieldName).gcamp = normGcampData;
                obj.StraightenedData.(fieldName).jrgeco = normJrgecoData;
                
            end
        end
        
        function differences = getDayDifferences(obj)
            % Creates for each day how much need to add in order to have
            % same baseline (calculated by correct licks)
            gTrials = obj.RawMatFile.onset.all_trials;
            jTrials = obj.RawMatFile.onset.af_trials;
            
            recordingDays = categorical(obj.Info.onset.day);
            recordingOutcome = categorical(obj.Info.onset.trial_result);
            
            % Gcamp!!!
            gRecordingBase = double(mean(gTrials(:, 1000:5000), 2));  % From 1 to 5 seconds
            gRecordingSet = table(gRecordingBase, recordingDays, recordingOutcome, 'VariableNames', {'baseline', 'day', 'outcome'});
            G = fitlme(gRecordingSet, 'baseline ~ outcome + day'); %also can use fitglm: especially if want to do interaction Keep in mind to fit to a random effect (1|day).
            gcampDifference = G.Coefficients.Estimate;
            
            % Geco
            jRecordingBase = double(mean(jTrials(:, 1000:5000), 2));  % From 1 to 5 seconds
            jRecordingSet = table(jRecordingBase, recordingDays, recordingOutcome, 'VariableNames', {'baseline', 'day', 'outcome'});
            J = fitlme(jRecordingSet, 'baseline ~ outcome + day'); %also can use fitglm: especially if want to do interaction Keep in mind to fit to a random effect (1|day).
            jrgecoDifference = J.Coefficients.Estimate;
            
            % NOTE - 3 last indexes of differences aren't relavent
            differences = {gcampDifference, jrgecoDifference};
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
        
        % Other
        function plotAllSessions(obj, timeWindow)
%             f = figure("Name", "Signal from all sessions of mouse " + obj.Name, "NumberTitle", "off");
            
            [numTrials, trialLen] = size(obj.StraightenedData.onset.gcamp);
            
            timeVector = linspace(0, numTrials * timeWindow, numTrials * trialLen);
            
            gcampSignal = reshape(obj.StraightenedData.onset.gcamp', 1, []);
            jrGecoSignal = reshape(obj.StraightenedData.onset.jrgeco', 1, []);
            
            plot(timeVector, gcampSignal, 'LineWidth', 1);
            hold on;
            plot(timeVector, jrGecoSignal, 'LineWidth', 1);
            hold off;
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
end

