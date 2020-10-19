classdef MouseList < handle
    %MouseList class - a class that holds lists of mice according to their
    % recording area
    
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
        % ================= Constructor and initialization ================
        function obj = MouseList(listType)
            % Constructs an empty instance of this class and saves to the
            % constant path.
            
            obj.Type = listType;
            obj.ObjectPath = obj.CONST_LIST_SAVE_PATH + obj.CONST_FOLDER_DELIMITER + listType + ".mat";
            
            save(obj.ObjectPath, "obj");
        end
        
        function add(obj, mouse)
            % Given a mouse, adds it to this list. If a mouse with the same
            % name exists, it puts the given mouse insted.
            for index = 1:size(obj.MousePathList, 2)
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
            % Loads all the mice in the list to a new list named
            % LoadedMouseList (before, there is only a list of the mice
            % paths in MousePathList)
            
            for mouseStruct = obj.MousePathList
                curMouse = load(mouseStruct.Path).obj;
                obj.LoadedMouseList = [obj.LoadedMouseList, curMouse];
            end
        end
        
        % ============================= Plot ==============================
        function plotCorrelationScatterPlot(obj, descriptionVector, smoothFactor, downsampleFactor)
            % Plots scatter plots for all the mice according to the given 
            % descriptionVector (empty plot for a mouse that has no
            % data in this category, eg. a mouse that didnt have a 
            % pre-awake-FS recording session).
            % It also plots the best fit line for the scatter plot.
            % The function first smooths the signal, then downsamples it
            % and at last plots it and finds the best fitting line.
            
            miceAmount = size(obj.LoadedMouseList, 2);
            
            fig = figure("Name", "Scatter plot for all mice", "NumberTitle", "off");
            
            index = 1;
            
            for mouse = obj.LoadedMouseList
                curPlot = subplot(2, ceil(miceAmount / 2), index);
                mouse.drawScatterPlot(curPlot, descriptionVector, smoothFactor, downsampleFactor)
                title(curPlot, {"Mouse " + mouse.Name}, 'Interpreter', 'none')
                if mouse.signalExists(descriptionVector)
                    [~, ~, ~, ~, signalTitle] = mouse.getRawSignals(descriptionVector);
                end
                
                index = index + 1;
            end
            
            sgtitle(fig, {"Scatter plot of " + signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
        end
        
        function plotCorrelationBar(obj, smoothFactor, downsampleFactor)
            [correlationMatrix, xLabels, mouseNames] = obj.calculateCorrelations(smoothFactor, downsampleFactor);
            
            obj.drawBarByMouse(correlationMatrix, xLabels, mouseNames, "Whole signal correlations by mouse", smoothFactor, downsampleFactor);
            obj.drawBarSummary(correlationMatrix, xLabels, "Whole signal correlations summary for all mice", smoothFactor, downsampleFactor);
        end
        
        function plotSlidingCorrelationBar(obj, timeWindow, timeShift)
            [medianSlidingCorrelationMatrix, meanSlidingCorrelationMatrix, xLabels, mouseNames] = obj.calculateSlidingWindow(timeWindow, timeShift);
            
            obj.helperPlotCorrelationBarByMouse(medianSlidingCorrelationMatrix, xLabels, mouseNames, {"Median - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            obj.helperPlotCorrelationBarSummary(medianSlidingCorrelationMatrix, xLabels, {"Median - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            
            obj.helperPlotCorrelationBarByMouse(meanSlidingCorrelationMatrix, xLabels, mouseNames, {"Mean - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            obj.helperPlotCorrelationBarSummary(meanSlidingCorrelationMatrix, xLabels, {"Mean - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)});
            
        end
        
        % ============= Helpers =============
        function [correlationMatrix, finalXLabels, mouseNames] = calculateCorrelations(obj, smoothFactor, downsampleFactor)
            correlationMatrix = [];
            finalXLabels = [];
            mouseNames = [];
            
            for mouse = obj.LoadedMouseList
                [correlationVec, currentXLabels] = mouse.dataForPlotCorrelationBar(smoothFactor, downsampleFactor);
                
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
        % ============================= Plot ==============================
        % ============= Helpers =============
        function drawBarByMouse(matrix, xLabels, mouseNames, figureTitle, smoothFactor, downsampleFactor)
            fig = figure("Name", "Mouse List By Mouse", "NumberTitle", "off");
            ax = axes;
            
            categories = categorical(xLabels);
            categories = reordercats(categories, xLabels(:,1));
            
            bar(ax, categories, matrix)
            set(ax,'TickLabelInterpreter','none')
            title(ax, {figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            ylabel("Correlation")
            legend(ax, mouseNames, 'Interpreter', 'none', 'Location', 'best')
            
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
        
        function drawBarSummary(matrix, xLabels, figureTitle, smoothFactor, downsampleFactor)
            fig = figure("Name", "Mouse List Summary", "NumberTitle", "off");
            ax = axes;
            
            correlationMean = sum(matrix,2) ./ sum(matrix~=0,2);           % Not mean(matrix, 2) cause this way doesn't count zeros!
            
            categories = categorical(xLabels(:,1));
            categories = reordercats(categories, xLabels(:,1));
            
            bar(ax, categories, correlationMean)
            set(ax,'TickLabelInterpreter','none')
            title(ax, {figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
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
        end 
    end
end

