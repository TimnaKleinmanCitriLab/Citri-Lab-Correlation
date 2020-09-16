classdef AudOfcMouse < Mouse
    %OFCAUDMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Aud'
        JRGECO = 'Ofc'
    end
    
    methods
        function obj = AudOfcMouse(name, gcampJrGecoReversed)
            %OFCAUDMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed);
        end
%         
%         function plotCrossCorrelationByCloud(obj, ax, timeVector)
%             obj.plotGeneralCrossCorrelation(ax, timeVector, obj.DATA_BY_CLOUD)
%         end
%         
%         function plotCrossCorrelationByCue(obj, ax, timeVector)
%             obj.plotGeneralCrossCorrelation(ax, timeVector, obj.DATA_BY_CUE)
%         end
%         
%         function plotCrossCorrelationByLick(obj, ax, timeVector)
%             obj.plotGeneralCrossCorrelation(ax, timeVector, obj.DATA_BY_LICK)
%         end
%         
%         function plotCrossCorrelationByMovement(obj, ax, timeVector)
%             obj.plotGeneralCrossCorrelation(ax, timeVector, obj.DATA_BY_MOVEMENT)
%         end
%         
%         function plotCrossCorrelationByOnset(obj, ax, timeVector)
%             obj.plotGeneralCrossCorrelation(ax, timeVector, obj.DATA_BY_ONSET)
%         end
%         
%         function plotGeneralCrossCorrelation(obj, ax, timeVector, dataFileName)
%             dataFile = matfile(obj.FILE_DIRECTORY + obj.FOLDER_DELIMITER + obj.Name + obj.FOLDER_DELIMITER + dataFileName);
%             audZScored = zscore(dataFile.all_trials')';                    % Needs to be z scored so upwards won't give too much weight
%             ofcZScored = zscore(dataFile.af_trials')';                     % Needs to be z scored so upwards won't give too much weight
%             
%             rows = size(ofcZScored,1);
%             cols = size(ofcZScored, 2);
%             ofcXAud = zeros(rows, cols * 2 - 1);
%             
%             for index = 1:rows
%                 ofcXAud(index,:) = xcorr(ofcZScored(index,:), audZScored(index,:), 'normalized');
%             end
%             ofcXAud = sum(ofcXAud) / rows;
%             plot(ax, timeVector, ofcXAud)
%         end
    end
end

