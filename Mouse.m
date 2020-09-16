classdef Mouse < handle
    %MOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        FOLDER_DELIMITER = "\";
        FILE_DIRECTORY = "\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig";
        
        DATA_BY_CLOUD = "CueInCloud_comb_cloud.mat";
        DATA_BY_CUE = "CueInCloud_comb_cue.mat";
        DATA_BY_LICK = "CueInCloud_comb_lick.mat";
        DATA_BY_MOVEMENT = "CueInCloud_comb_movement.mat";
        DATA_BY_ONSET = "CueInCloud_comb_t_onset.mat";
    end
    
    properties
        Name
        GcampJrGecoReversed
    end
    
    methods
        function obj = Mouse(name, gcampJrGecoReversed)
            %MOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj.Name = name;
            obj.GcampJrGecoReversed = gcampJrGecoReversed;
        end
        
        function plotMouseCrossCorrelations(obj, subPlots, timeVector)
            [plotByCloud, plotByCue, plotByLick, plotByMove, plotByOnset] = subPlots{:};
            
            obj.plotGeneralCrossCorrelation(plotByCloud, timeVector, obj.DATA_BY_CLOUD);
            obj.plotGeneralCrossCorrelation(plotByCue, timeVector, obj.DATA_BY_CUE);
            obj.plotGeneralCrossCorrelation(plotByLick, timeVector, obj.DATA_BY_LICK);
            obj.plotGeneralCrossCorrelation(plotByMove, timeVector, obj.DATA_BY_MOVEMENT);
            obj.plotGeneralCrossCorrelation(plotByOnset, timeVector, obj.DATA_BY_ONSET);
            
        end
        
        function plotGeneralCrossCorrelation(obj, ax, timeVector, dataFileName)
            dataFile = matfile(obj.FILE_DIRECTORY + obj.FOLDER_DELIMITER + obj.Name + obj.FOLDER_DELIMITER + dataFileName);
            if obj.GcampJrGecoReversed
                gcampLowered = dataFile.af_trials;
                jrgecoLowered = dataFile.all_trials;
            else
                gcampLowered = dataFile.all_trials;
                % gcampLowered = dataFile.all_trials - mean(dataFile.all_trials);% Needs to be lowered so upwards won't give too much weight
                % gcampLowered = zscore(dataFile.all_trials')';   % Another option
                jrgecoLowered = dataFile.af_trials;
                % jrgecoLowered = dataFile.af_trials - mean(dataFile.af_trials); % Needs to be lowered so upwards won't give too much weight
                %jrgecoLowered = zscore(dataFile.af_trials')';   % Another option
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

