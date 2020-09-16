classdef OfcAccMouse < Mouse
    %ACCOFCMOUSE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (Constant)
         GCAMP = 'Ofc'
         JRGECO = 'Acc'
     end
    
    methods
        function obj = OfcAccMouse(name, gcampJrGecoReversed)
            %MOUSE Construct an instance of this class
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
%             if (obj.OfcIsGcamp)
%                 ofcZScored = zscore(dataFile.all_trials')';                % Needs to be z scored so upwards won't give too much weight
%                 accZScored = zscore(dataFile.af_trials')';                 % Needs to be z scored so upwards won't give too much weight
%             else
%                 accZScored = zscore(dataFile.all_trials')';                % Needs to be z scored so upwards won't give too much weight
%                 ofcZScored = zscore(dataFile.af_trials')';                 % Needs to be z scored so upwards won't give too much weight
%             end
%             
%             rows = size(accZScored,1);
%             cols = size(accZScored, 2);
%             accXOfc = zeros(rows, cols * 2 - 1);
%             
%             for index = 1:rows
%                 accXOfc(index,:) = xcorr(accZScored(index,:), ofcZScored(index,:), 'normalized');
%             end
%             accXOfc = sum(accXOfc) / rows;
%             plot(ax, timeVector, accXOfc)
%         end
    end
end

