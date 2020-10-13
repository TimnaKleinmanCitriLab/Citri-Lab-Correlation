classdef MouseList < handle
    %MouseList Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        CONST_FOLDER_DELIMITER = "\";
        
        CONST_LIST_SAVE_PATH = "W:\shared\Timna\Gal Projects\Mouse Lists";
    end
    
    properties
        Type
        ObjectPath
        MousePathList
        LoadedMouseList
    end
    
    methods
        %========== Constructor Functions ==========
        function obj = MouseList(listType)
            %MouseList Construct an instance of this class
            %   Detailed explanation goes here
            obj.Type = listType;
            obj.ObjectPath = obj.CONST_LIST_SAVE_PATH + obj.CONST_FOLDER_DELIMITER + listType + ".mat";
            
            save(obj.ObjectPath, "obj");
        end
        
        function add(obj, mouse)
            for index = 1:length(obj.MousePathList)
                if obj.MousePathList(index).Name == mouse.Name
                    obj.MousePathList(index).Path = mouse.ObjectPath;
                    save(obj.ObjectPath, "obj");
                    return;
                end
            end
            
            newMouse.Name = mouse.Name;
            newMouse.Path = mouse.ObjectPath;
            obj.MousePathList = [obj.MousePathList, newMouse];
            save(obj.ObjectPath, "obj");
        end
        
        function loadMice(obj)
            for mouseStruct = obj.MousePathList
                curMouse = load(mouseStruct.Path).obj;
                obj.LoadedMouseList = [obj.LoadedMouseList, curMouse];
            end
        end
        
        % ================ Plot ================
        function plotCorrelationScatterPlot(obj, descriptionVector)
           miceAmount = size(obj.LoadedMouseList, 2);
           [~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getSignals(descriptionVector);
           
           fig = figure("Name", "Comparing correlations of type " + signalTitle, "NumberTitle", "off");
           
           index = 1;
           
           for mouse = obj.LoadedMouseList
               curPlot = subplot(2, ceil(miceAmount / 2), index);
               mouse.drawScatterPlot(curPlot, descriptionVector)
               title(curPlot, {"Mouse " + mouse.Name}, 'Interpreter', 'none')
               index = index + 1;
           end
           sgtitle(fig, signalTitle)
        end
        
        function plotCorrelationBar(obj)
            [correlationMatrix, xLabels, mouseNames] = obj.calculateCorrelations();
            
            obj.helperPlotCorrelationBarByMouse(correlationMatrix, xLabels, mouseNames, "Whole signal correlations by mouse");
            obj.helperPlotCorrelationBarSummary(correlationMatrix, xLabels, "Whole signal correlations summary for all mice");
        end
        
        function plotSlidingCorrelationBar(obj, timeWindow, timeShift)
            [medianSlidingCorrelationMatrix, meanSlidingCorrelationMatrix, xLabels, mouseNames] = obj.calculateSlidingWindow(timeWindow, timeShift);
            
            obj.helperPlotCorrelationBarByMouse(medianSlidingCorrelationMatrix, xLabels, mouseNames, {"Median - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            obj.helperPlotCorrelationBarSummary(medianSlidingCorrelationMatrix, xLabels, {"Median - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            
            obj.helperPlotCorrelationBarByMouse(meanSlidingCorrelationMatrix, xLabels, mouseNames, {"Mean - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            obj.helperPlotCorrelationBarSummary(meanSlidingCorrelationMatrix, xLabels, {"Mean - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            
        end
        
        % ================ Helpers ================
        % ==== Plots ====
        function [correlationMatrix, finalXLabels, mouseNames] = calculateCorrelations(obj)
            correlationMatrix = [];
            finalXLabels = [];
            mouseNames = [];
            
            for mouse = obj.LoadedMouseList
                [correlationVec, currentXLabels] = mouse.dataForPlotCorrelationBar();
                
                correlationMatrix = [correlationMatrix, correlationVec'];
                finalXLabels = [finalXLabels, currentXLabels'];
                mouseNames = [mouseNames, mouse.Name];
            end
        end
        
        function [medianSlidingCorrelationMatrix, meanSlidingCorrelationMatrix, finalXLabels, mouseNames] = calculateSlidingWindow(obj, timeWindow, timeShift)
            medianSlidingCorrelationMatrix = [];
            meanSlidingCorrelationMatrix = [];
            finalXLabels = [];
            mouseNames = [];
            
            for mouse = obj.LoadedMouseList
                [medianSlidingCorrelationVec, meanSlidingCorrelationVec, currentXLabels] = mouse.dataForPlotSlidingCorrelationBar(timeWindow, timeShift);
                
                % Add to all
                medianSlidingCorrelationMatrix = [medianSlidingCorrelationMatrix, medianSlidingCorrelationVec'];
                meanSlidingCorrelationMatrix = [meanSlidingCorrelationMatrix, meanSlidingCorrelationVec'];
                finalXLabels = [finalXLabels, currentXLabels'];
                mouseNames = [mouseNames, mouse.Name];
                
            end
        end
    end
    
    methods (Static)
        % ================ Helpers ================
        function helperPlotCorrelationBarByMouse(matrix, xLabels, mouseNames, figureTitle)
            fig = figure("Name", figureTitle, "NumberTitle", "off");
            ax = axes;
            
            categories = categorical(xLabels);
            categories = reordercats(categories, xLabels(:,1));
            
            bar(ax, categories, matrix)
            set(ax,'TickLabelInterpreter','none')
            title(ax, figureTitle, 'Interpreter', 'none')
            ylabel("Correlation")
            legend(ax, mouseNames, 'Interpreter', 'none')
            
            minY = min(min(matrix));
            maxY = max(max(matrix));
            
            if (minY < 0) && (0 < maxY)
                ylim(ax, [-1, 1])
            elseif (0 < maxY)                                              % for sure 0 <= minY
                ylim(ax, [0, 1])
            else
                ylim(ax, [-1, 0])
            end
        end
        
        function helperPlotCorrelationBarSummary(matrix, xLabels, figureTitle)
            fig = figure("Name", figureTitle, "NumberTitle", "off");
            ax = axes;
            
%             correlationMean = mean(matrix, 2);
            correlationMean = sum(matrix,2) ./ sum(matrix~=0,2);
            
            categories = categorical(xLabels(:,1));
            categories = reordercats(categories, xLabels(:,1));
            
            bar(ax, categories, correlationMean)
            set(ax,'TickLabelInterpreter','none')
            title(ax, figureTitle, 'Interpreter', 'none')
            ylabel(["Correlation", "(mean of all mice)"])
            
            minY = min(min(correlationMean));
            maxY = max(max(correlationMean));
            
            if (minY < 0) && (0 < maxY)
                ylim(ax, [-1, 1])
            elseif (0 < maxY)                                              % for sure 0 <= minY
                ylim(ax, [0, 1])
            else
                ylim(ax, [-1, 0])
            end
        end %%% FIX!!!
    end
end

