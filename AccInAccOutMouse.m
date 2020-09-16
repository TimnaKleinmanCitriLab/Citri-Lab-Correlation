classdef AccInAccOutMouse < Mouse
    %ACCINACCOUTMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        GCAMP = 'Acc in'
        JRGECO = 'Acc out'
    end
    
    methods
        function obj = AccInAccOutMouse(name, gcampJrGecoReversed)
            %ACCINACCOUTMOUSE Construct an instance of this class
            %   Detailed explanation goes here
            obj@Mouse(name, gcampJrGecoReversed);
        end
        
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
%             accInZScored = zscore(dataFile.all_trials')';                    % Needs to be z scored so upwards won't give too much weight
%             accOutZScored = zscore(dataFile.af_trials')';                     % Needs to be z scored so upwards won't give too much weight
%             
%             rows = size(accInZScored,1);
%             cols = size(accInZScored, 2);
%             accInXAccOut = zeros(rows, cols * 2 - 1);
%             
%             for index = 1:rows
%                 accInXAccOut(index,:) = xcorr(accInZScored(index,:), accOutZScored(index,:), 'normalized');
%             end
%             accInXAccOut = sum(accInXAccOut) / rows;
%             plot(ax, timeVector, accInXAccOut)
%         end
    end
end

