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
            % name exists, it puts the given mouse instead.
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
            obj.LoadedMouseList = [];
            for mouseStruct = obj.MousePathList
                curMouse = load(mouseStruct.Path).obj;
                obj.LoadedMouseList = [obj.LoadedMouseList, curMouse];
            end
        end
        
        % ============================= Plot ==============================
        % ============= Plot =============
        function plotCorrelationScatterPlot(obj, descriptionVector, smoothFactor, downsampleFactor)
            % Plots scatter plots for all the mice according to the given
            % descriptionVector (empty plot for a mouse that has no
            % data in this category, eg. a mouse that didnt have a
            % pre-awake-FS recording session).
            % It also plots the best fit line for the scatter plot.
            % The function first smooths the signal, then down samples it
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
            % Plots two graphs - one is of bars where one can see each of
            % the mice separately, and the other is a summary one with the
            % mean of all the mice. The bars are the correlations
            % and the categories are all the possible categories (no bar
            % for a category that has no data, eg. a mouse that didnt have
            % a pre-awake-FS recording session).
            % The function first smooths the signals, then down samples them
            % and at last calculates their correlation and plots it.
            
            [correlationMatrix, xLabels, mouseNames] = obj.dataForPlotCorrelationBar(smoothFactor, downsampleFactor);
            
            obj.drawBarByMouse(correlationMatrix, xLabels, mouseNames, {"Whole signal correlations by mouse"}, smoothFactor, downsampleFactor);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Auto\" + obj.Type + " Correlation Bar - by mouse")
            obj.drawBarSummary(correlationMatrix, xLabels, {"Whole signal correlations summary for all mice"}, smoothFactor, downsampleFactor);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Auto\" + obj.Type + " Correlation Bar - all")
        end
        
        function plotSlidingCorrelationBar(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots two graphs - one is of bars where one can see each of
            % the mice separately, and the other is a summary one with the
            % mean of all the mice. The bars are the mean / median of
            % the sliding window values and the categories are all the
            % possible categories (no bar for a category that has no data,
            % eg. a mouse that didnt have a pre-awake-FS recording session).
            % The function first smooths the signals, then down samples them
            % then calculates the sliding window, and at last calculates
            % the mean / median of it's values.
            
            [medianSlidingCorrelationMatrix, varSlidingCorrelationMatrix, xLabels, mouseNames] = obj.dataForPlotSlidingCorrelationBar(timeWindow, timeShift, smoothFactor, downsampleFactor);
            
            obj.drawBarByMouse(medianSlidingCorrelationMatrix, xLabels, mouseNames, {"Median - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, true);
            savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Auto Saved\" + obj.Type + " Median Sliding Correlation Bar - by mouse")
            obj.drawBarSummary(medianSlidingCorrelationMatrix, xLabels, {"Median - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, true);
            savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Auto Saved\" + obj.Type + " Median Sliding Correlation Bar - all")
            
            
            obj.drawBarByMouse(varSlidingCorrelationMatrix, xLabels, mouseNames, {"Variance - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, false);
            savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Auto Saved\" + obj.Type + " Variance Sliding Correlation Bar - by mouse")
            obj.drawBarSummary(varSlidingCorrelationMatrix, xLabels, {"Variance - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, false);
            savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Auto Saved\" + obj.Type + " Variance Sliding Correlation Bar - all")
        end
        
%         function plotCrossCorrelation(obj, gcampXjrgeco, timeVector, signalTitle, smoothFactor, downsampleFactor)
%             % Draws the plot for the plotCrossCorrelation function.
%             fig = figure();
%             
%             ax = gca;
%             
%             plot(ax, timeVector, gcampXjrgeco, 'LineWidth', 1.5);
%             
%             [peak, index] = max(gcampXjrgeco);
%             % hold on
%             % plot(timeVector(index), peak, 'o')
%             % hold off
%             
%             title(ax, {"Signal From: " +  signalTitle, "Mouse: " + obj.Name, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor}, 'FontSize', 12)
%             
%             xlabel("Time Shift (sec)", 'FontSize', 14)
%             ylabel("Cross Correlation (normalized)", 'FontSize', 14)
%             
%             yline(ax, 0, 'Color', [192, 192, 192]/255)
%             xline(ax, 0, 'Color', [192, 192, 192]/255)
%             
%             annotation('textbox', [.15 .5 .3 .3], 'String', {"Max point at:", "x = " + timeVector(index) + ", y = " + peak}, 'FitBoxToText','on');
%         end
        
        % ============= Helpers =============
        function [correlationMatrix, finalXLabels, mouseNames] = dataForPlotCorrelationBar(obj, smoothFactor, downsampleFactor)
            % Returns the correlation for all the categories, for all the
            % mice in the list.
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
        
        function [medianSlidingCorrelationMatrix, varSlidingCorrelationMatrix, finalXLabels, mouseNames] = dataForPlotSlidingCorrelationBar(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Returns the mean / median of the sliding window values
            % for all the categories, for all the mice in the list.
            
            medianSlidingCorrelationMatrix = [];
            varSlidingCorrelationMatrix = [];
            finalXLabels = [];
            mouseNames = [];
            
            for mouse = obj.LoadedMouseList
                [medianSlidingCorrelationVec, varSlidingCorrelationVec, currentXLabels] = mouse.dataForPlotSlidingCorrelationBar(timeWindow, timeShift, smoothFactor, downsampleFactor);
                
                % Add to all
                medianSlidingCorrelationMatrix = [medianSlidingCorrelationMatrix, medianSlidingCorrelationVec'];
                varSlidingCorrelationMatrix = [varSlidingCorrelationMatrix, varSlidingCorrelationVec'];
                
                finalXLabels = [finalXLabels, currentXLabels'];
                mouseNames = [mouseNames, mouse.Name];
                
            end
        end
        
%         function dataForCrossCorrelation(obj, )
        
        function drawBarByMouse(obj, matrix, xLabels, mouseNames, figureTitle, smoothFactor, downsampleFactor, oneToMinusOne)
            % Draws a bar graph of the given labels - where each mouse
            % appears. In the given matrix, each column is a mouse, and
            % each row is a category fitting to the xLabels.
            
            fig = figure("Name", "Mouse List By Mouse", "NumberTitle", "off");
            ax = axes;
            
            categories = categorical(xLabels);
            categories = reordercats(categories, xLabels(:,1));
            
            bar(ax, categories, matrix)
            set(ax,'TickLabelInterpreter','none')
            FigureFinalTitle = [figureTitle, obj.Type, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor];
            title(ax, FigureFinalTitle)
            ylabel("Correlation")
            legend(ax, mouseNames, 'Interpreter', 'none', 'Location', 'best')
            
            minY = min(min(matrix));
            maxY = max(max(matrix));
            
            if oneToMinusOne
                if (minY < 0) && (0 < maxY)
                    ylim(ax, [-1, 1])
                elseif (0 < maxY)                                          % for sure 0 <= minY
                    ylim(ax, [0, 1])
                else
                    ylim(ax, [-1, 0])
                end
            end
        end
        
        function drawBarSummary(obj, matrix, xLabels, figureTitle, smoothFactor, downsampleFactor, oneToMinusOne)
            % Draws a bar graph of the given labels - that summarizes the
            % data of all the given mice by category (mean). In the given
            % matrix, each column is a mouse, and each row is a category
            % fitting to the xLabels.
            
            fig = figure("Name", "Mouse List Summary", "NumberTitle", "off");
            ax = axes;
            
            semVector = [];
            meanVector = [];
            for rowIndex = 1:size(matrix, 1)
                curRow = matrix(rowIndex, :);
                curRow = nonzeros(curRow);
                semVector = [semVector; std(curRow)/sqrt(length(curRow))];
                meanVector = [meanVector; mean(curRow)];
            end
            
            % Mean (without error) can also be calculated like this:
            % meanVector = sum(matrix,2) ./ sum(matrix~=0,2);           % Not mean(matrix, 2) cause this way doesn't count zeros!
            
            categories = categorical(xLabels(:,1));
            categories = reordercats(categories, xLabels(:,1));
            
            % Bar plot
            bar(ax, categories, meanVector)
            hold on
            set(ax,'TickLabelInterpreter','none')
            FigureFinalTitle = [figureTitle, obj.Type, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor, "Error bar is SEM"];
            title(ax, FigureFinalTitle)
            ylabel(["Correlation", "(mean of all mice)"])
            
            % Error bar
            er = errorbar(meanVector, semVector, 'k');
            er.LineStyle = 'none';
            
            minY = min(min(meanVector));
            maxY = max(max(meanVector));
            
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
        
        % Delete after use
        function drawCrossCorrelation(obj, descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
            for mouse = obj.LoadedMouseList
                mouse.plotCrossCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
                savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross Correlation\Concatenated Task\" + obj.Type + "\" + mouse.Name + " - Concatenated Task")
            end
        end

        % Delete after use
        function drawCrossCorrelationFree(obj, maxLag, smoothFactor, downsampleFactor, shouldReshape)
            for mouse = obj.LoadedMouseList
                fields = fieldnames(mouse.ProcessedRawData.Free);
                
                for index = 1:numel(fields)
                    tDateHour = fields{index};
                    descriptionVector = ["Free", (tDateHour)];
                    
                    mouse.plotAutoCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
                end
            end
        end
        
    end
end

