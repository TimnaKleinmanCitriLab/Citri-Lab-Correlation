classdef AudInAudOutMouse < Mouse
    %AUDINAUDOUTMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Aud in'
        JRGECO = 'Aud out'
    end
    
    methods
        function obj = AudInAudOutMouse(name, gcampJrGecoReversed)
            %AUDINAUDOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed);
        end
        
%          function plotCrossCorrelationByCloud(obj, ax, timeVector)
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
%             audInZScored = zscore(dataFile.all_trials')';                    % Needs to be z scored so upwards won't give too much weight
%             audOutZScored = zscore(dataFile.af_trials')';                     % Needs to be z scored so upwards won't give too much weight
%             
%             rows = size(audInZScored,1);
%             cols = size(audInZScored, 2);
%             audInXAudOut = zeros(rows, cols * 2 - 1);
%             
%             for index = 1:rows
%                 audInXAudOut(index,:) = xcorr(audInZScored(index,:), audOutZScored(index,:), 'normalized');
%             end
%             audInXAudOut = sum(audInXAudOut) / rows;
%             plot(ax, timeVector, audInXAudOut)
%         end
%         
%         
%         % Auto Correlation
%         function plotAutoCorrelationByOnset(obj, firstAx, secAx, timeVector)
%             obj.plotGeneralAutoCorrelation(firstAx, secAx, timeVector, obj.DATA_BY_ONSET)
%         end
%         
%         function plotGeneralAutoCorrelation(obj, firstAx, secAx, timeVector, dataFileName)
%             dataFile = matfile(obj.FILE_DIRECTORY + obj.FOLDER_DELIMITER + obj.Name + obj.FOLDER_DELIMITER + dataFileName);
%             audInZScored = zscore(dataFile.all_trials')';                    % Needs to be z scored so upwards won't give too much weight
%             audOutZScored = zscore(dataFile.af_trials')';                     % Needs to be z scored so upwards won't give too much weight
%             
%             rows = size(audInZScored,1);
%             cols = size(audInZScored, 2);
%             audInXAudIn = zeros(rows, cols * 2 - 1);
%             audOutXAudOut = zeros(rows, cols * 2 - 1);
%             
%             for index = 1:rows
%                 audInXAudIn(index,:) = xcorr(audInZScored(index,:), audInZScored(index,:), 'normalized');
%                 audOutXAudOut(index,:) = xcorr(audOutZScored(index,:), audOutZScored(index,:), 'normalized');
%             end
%             audInXAudIn = sum(audInXAudIn) / rows;
%             audOutXAudOut = sum(audOutXAudOut) / rows;
%             plot(firstAx, timeVector, audInXAudIn)                          % OTODO!!! Make sure that didn't switch first and second
%             plot(secAx, timeVector, audOutXAudOut)                          % OTODO!!! Make sure that didn't switch first and second
%         end
    end
end

