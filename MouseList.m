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
            
            fig = figure("Name", "Scatter plot for all mice", "NumberTitle", "off", "position", [437,248,993,588]);
            
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
            
            sgtitle(fig, {"Scatter plot of " + signalTitle + " for " + obj.Type, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Scatter Plots\" + obj.Type + "\Scatter Plot - " + signalTitle)
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
            
            obj.drawBarByMouse(correlationMatrix, xLabels, mouseNames, "Correlation", {"Whole signal correlations by mouse"}, smoothFactor, downsampleFactor, true);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Bars\" + obj.Type + " Correlation Bar - by mouse")
            obj.drawBarSummary(correlationMatrix, xLabels, "Correlation", {"Whole signal correlations summary for all mice"}, smoothFactor, downsampleFactor, true);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Bars\" + obj.Type + " Correlation Bar - all")
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
            
            obj.drawBarByMouse(medianSlidingCorrelationMatrix, xLabels, mouseNames, "Correlation", {"Median - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, true);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Median\" + obj.Type + " Median Sliding Correlation Bar - by mouse")
            obj.drawBarSummary(medianSlidingCorrelationMatrix, xLabels, "Correlation", {"Median - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, true);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Median\" + obj.Type + " Median Sliding Correlation Bar - all")
            
            
            obj.drawBarByMouse(varSlidingCorrelationMatrix, xLabels, mouseNames, "Correlation", {"Variance - Sliding window correlation by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, false);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Variance\" + obj.Type + " Variance Sliding Correlation Bar - by mouse")
            obj.drawBarSummary(varSlidingCorrelationMatrix, xLabels, "Correlation", {"Variance - Sliding window correlation summary for all mice", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, false);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Variance\" + obj.Type + " Variance Sliding Correlation Bar - all")
        end
        
        function plotCrossAndAutoCorrealtionByMouse(obj, descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotCrossAndAutoCorrelation(descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
%                     savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross And Auto Correlation\" + signalTitle + "\Concat - " + shouldReshape + "\" +  obj.Type + "\" + mouse.Name + " - " + signalTitle)
                end
            end
        end
        
        function plotCrossAndAutoCorrealtionAverage(obj, descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            allMiceCross = [];
            allMiceAutoFirst = [];
            allMiceAutoSecond = [];
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    [firstXSecond, timeVector, signalTitle] = mouse.dataForPlotCrossCorrelation(descriptionVector, lim, smoothFactor, downsampleFactor, shouldReshape);
                    [firstXfirst, secondXsecond, ~, ~] = mouse.dataForPlotAutoCorrelation(descriptionVector, lim, smoothFactor, downsampleFactor, shouldReshape);
                    
                    allMiceCross = [allMiceCross; firstXSecond];
                    allMiceAutoFirst = [allMiceAutoFirst; firstXfirst];
                    allMiceAutoSecond = [allMiceAutoSecond; secondXsecond];
                    
                end
            end
            meanMiceCross = mean(allMiceCross, 1);
            meanMiceAutoFirst = mean(allMiceAutoFirst);
            meanMiceAutoSecond = mean(allMiceAutoSecond);
            
            first = mouse.GCAMP;
            second = mouse.JRGECO;
            
            mouse.drawCrossCorrelation([meanMiceCross; meanMiceAutoFirst], timeVector, lim, ["Cross", "Auto - " + first], signalTitle, "Cross and Auto Correlation Between " + first + " and " + second + " - ALL MICE", smoothFactor, downsampleFactor, shouldReshape)
        end
        
        function plotCrossCorrelationLagBar(obj, descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
            [signalTitle, firstSignal, secondSignal, timeLagVec, maxHeightVec, mouseNames] = obj.dataForPlotCrossCorrelationLagBar(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
            
            % By mouse
            obj.drawBarByMouse(timeLagVec, mouseNames, firstSignal + " VS. " + secondSignal, "Lag \fontsize{9}(sec)", {"Cross correlation lag - by mouse", signalTitle, "Max lag - " + maxLag}, smoothFactor, downsampleFactor, true);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross Correlation\" + signalTitle + "\Concat - " + shouldReshape + "\" +  obj.Type + "\" + " Cross correlation lag - by mouse")

            obj.drawBarByMouse(maxHeightVec, mouseNames, firstSignal + " VS. " + secondSignal, "Cross correlation \fontsize{9}(normalized)", {"Cross correlation maximum by mouse", signalTitle, "Max lag - " + maxLag}, smoothFactor, downsampleFactor, true);
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross Correlation\" + signalTitle + "\Concat - " + shouldReshape + "\" +  obj.Type + "\" + " Cross correlation maximum - by mouse")
            
        end
        
        function plotCorrVsSliding(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            miceCorrelation = [];
            shuffledCorrelation = [];
            
            miceSliding = [];
            shuffledSliding = [];
            
            miceNames = [];
            
            for mouse = obj.LoadedMouseList
                % Correlation
                mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                miceCorrelation = [miceCorrelation, mouseCorrelation];
                
                curShuffleCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, true);
                shuffledCorrelation = [shuffledCorrelation, curShuffleCorrelation];
                
                % Sliding
                [mouseSliding, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                miceSliding = [miceSliding, mouseSliding];
                
                [curShuffledSliding, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, true);
                shuffledSliding = [shuffledSliding, curShuffledSliding];
                
                % General
                miceNames = [miceNames, mouse.Name];
            end
            
            obj.drawRelativeBubbleByMouse(miceCorrelation, miceSliding, miceNames, signalTitle, smoothFactor, downsampleFactor)
            %             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding\" + obj.Type + " - " + signalTitle + " - By Mouse")
            obj.drawTwoBubble(miceCorrelation, shuffledCorrelation, miceSliding, shuffledSliding, signalTitle, smoothFactor, downsampleFactor, true)
            %             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding\" + obj.Type + " - " + signalTitle + " - All Mice")
            
        end
        
        function plotCorrOnly(obj, descriptionVector, smoothFactor, downsampleFactor)
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            miceCorrelation = [];
            shuffledCorrelation = [];
            
            miceNames = [];
            
            for mouse = obj.LoadedMouseList
                % Correlation
                mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                miceCorrelation = [miceCorrelation, mouseCorrelation];
                
                curShuffleCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, true);
                shuffledCorrelation = [shuffledCorrelation, curShuffleCorrelation];
                
                % General
                miceNames = [miceNames, mouse.Name];
            end
            
            obj.drawSingleBubbleByMouse(miceCorrelation, miceNames, signalTitle, smoothFactor, downsampleFactor)
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Bubble\" + obj.Type + " - " + signalTitle + " - By Mouse")
            obj.drawSingleBubble(miceCorrelation, shuffledCorrelation, signalTitle, smoothFactor, downsampleFactor, true)
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Bubble\" + obj.Type + " - " + signalTitle + " - All Mice")
            
        end
        
        function plotHistogram(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            % Data
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            histogramMatrix = [];
            miceNames = [];
            
            for mouse = obj.LoadedMouseList
                binCount = mouse.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                histogramMatrix = [histogramMatrix, binCount'];
                miceNames = [miceNames, mouse.Name];
            end
            
            binCount = mouse.getWholeSignalSlidingBincount (descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, true);
            histogramMatrix = [histogramMatrix, binCount'];
            miceNames = [miceNames, 'Shuffled'];
            
            % Plot
            fig = figure();
            ax = axes;
            x = [-0.99: 0.02: 0.99];
            xLabels = [];
            
            for index = 1:size(histogramMatrix, 2)
                smoothed = histogramMatrix(:,index)';
                smoothed = smooth(smoothed', 5)';
                plot(x, smoothed, 'LineWidth', 1.5)
                hold on
            end
            hold off
            
            ax.XLabel.String = 'Correlation';
            ax.YLabel.String = 'Amount';
            legend(miceNames, 'Location', 'best')
            
            title(ax, {"Sliding Window Histogram for all mice type " + obj.Type, signalTitle, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            
        end
        
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
        
        function [signalTitle, firstSignal, secondSignal, timeLagVec, maxHeightVec, mouseNames] = dataForPlotCrossCorrelationLagBar(obj, descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
            timeLagVec = [];
            maxHeightVec = [];
            mouseNames = [];
            
            for mouse = obj.LoadedMouseList
                [firstXSecond, timeVector, signalTitle] = mouse.dataForPlotCrossCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
                
                [peak, index] = max(firstXSecond);
                
                % Add to all
                timeLagVec = [timeLagVec;  timeVector(index)];
                maxHeightVec = [maxHeightVec, peak];
                
                mouseNames = [mouseNames; mouse.Name];
            end
            
            firstSignal = mouse.GCAMP;
            secondSignal = mouse.JRGECO;
            
        end
        
        function drawBarByMouse(obj, matrix, xLabels, mouseNames, yLabel, figureTitle, smoothFactor, downsampleFactor, oneToMinusOne)
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
            ylabel(yLabel)
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
        
        function drawBarSummary(obj, matrix, xLabels, yLabel, figureTitle, smoothFactor, downsampleFactor, oneToMinusOne)
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
            ylabel([yLabel, "(mean of all mice)"])
            
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
        
        function drawRelativeBubbleByMouse(obj, first, second, miceNames, signalTitle, smoothFactor, downsampleFactor)
            fig = figure('Position', [711,425,401,511]);
            ax = axes;
            
            xAxe = [1, 1.5];
            
            for idx = 1:size(miceNames, 2)
                plot(ax, xAxe, [first(idx), second(idx)], 'o-')
                hold on
            end
            hold off
            
            legend(ax, miceNames, 'Location', 'best')           
            
            title(ax, {"Correlation Vs. Sliding Correlation", obj.Type, signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, 1.75])
            ax.XTick = xAxe;
            ax.XTickLabel = ["Correlation", "Sliding Correlation \fontsize{7}(median)"];
            ylabel(ax, "Correlation / Median of sliding correlation")
            
        end
        
        function drawTwoBubble(obj, first, firstRandom, second, secondRandom, signalTitle, smoothFactor, downsampleFactor, plotIndividuals)
            
            % Calcl Mean
            firstMean = mean(first);
            firstRandomMean = mean(firstRandom);
            secondMean = mean(second);
            secondRandomMean = mean(secondRandom);
            
            % Calc SEM
            firstSEM = std(first)/sqrt(length(first));
            firstRandomSEM = std(firstRandom)/sqrt(length(firstRandom));
            secondSEM =  std(second)/sqrt(length(second));
            secondRandomSEM =  std(secondRandom)/sqrt(length(secondRandom));
            
            % Figure
            fig = figure('Position', [711,425,401,511]);
            ax = axes;
            xAxe = [1, 1.5];
            
            % Plot
            errorbar(ax, xAxe, [firstMean, secondMean], [firstSEM, secondSEM],'o', 'LineWidth', 1, 'color', 'blue', 'MarkerFaceColor', 'blue', 'MarkerSize', 6, 'CapSize', 12)
            hold on
            errorbar(ax, xAxe, [firstRandomMean, secondRandomMean], [firstRandomSEM, secondRandomSEM],'o', 'LineWidth', 1, 'color', 'black', 'MarkerFaceColor', 'black', 'MarkerSize', 6, 'CapSize', 12)
            if plotIndividuals
                for idx = 1:size(first, 2)
                    plot(ax, xAxe, [first(idx), second(idx)], 'o-', 'color', '#C0C0C0')
                    hold on
                end
            end
            hold off
            
            % Titles
            legend(ax, 'Mice', 'Shuffled', 'Individuals', 'Location', 'best')
            
            title(ax, {"Correlation Vs. Sliding Correlation - all mice", obj.Type, signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, 1.75])
            ax.XTick = xAxe;
            ax.XTickLabel = ["Correlation", "Sliding Correlation \fontsize{7}(median)"];
            ylabel(ax, "Correlation / Median of sliding correlation")
        end
        
        function drawSingleBubbleByMouse(obj, first, miceNames, signalTitle, smoothFactor, downsampleFactor)
            fig = figure('Position', [711,425,401,511]);
            ax = axes;
            
            xAxe = [1];
            
            for idx = 1:size(miceNames, 2)
                plot(ax, xAxe, [first(idx)], 'o-')
                hold on
            end
            hold off
            
            legend(ax, miceNames, 'Location', 'best')
            
            title(ax, {"Correlation", obj.Type, signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.85, 1.15])
            ax.XTick = xAxe;
            ax.XTickLabel = ["Correlation"];
            ylabel(ax, "Correlation")
            
        end
        
        function drawSingleBubble(obj, first, firstRandom, signalTitle, smoothFactor, downsampleFactor, plotIndividuals)
            
            % Calcl Mean
            firstMean = mean(first);
            firstRandomMean = mean(firstRandom);
            
            % Calc SEM
            firstSEM = std(first)/sqrt(length(first));
            firstRandomSEM = std(firstRandom)/sqrt(length(firstRandom));
            
            % Figure
            fig = figure('Position', [711,425,401,511]);
            ax = axes;
            xAxe = [1];
            
            % Plot
            errorbar(ax, xAxe, [firstMean], [firstSEM,],'o', 'LineWidth', 1, 'color', 'blue', 'MarkerFaceColor', 'blue', 'MarkerSize', 6, 'CapSize', 12)
            hold on
            errorbar(ax, xAxe, [firstRandomMean], [firstRandomSEM],'o', 'LineWidth', 1, 'color', 'black', 'MarkerFaceColor', 'black', 'MarkerSize', 6, 'CapSize', 12)
            if plotIndividuals
                for idx = 1:size(first, 2)
                    plot(ax, xAxe, [first(idx)], 'o-', 'color', '#C0C0C0')
                    hold on
                end
            end
            hold off
            
            % Titles
            legend(ax, 'Mice', 'Shuffled', 'Individuals', 'Location', 'best')
            
            title(ax, {"Correlation - all mice", obj.Type, signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.85, 1.15])
            ax.XTick = xAxe;
            ax.XTickLabel = ["Correlation"];
            ylabel(ax, "Correlation")
        end
        
    end
end

