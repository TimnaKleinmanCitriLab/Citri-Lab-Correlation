classdef MouseList < handle
    %MouseList class - a class that holds lists of mice according to their
    % recording area
    
    properties (Constant)
        CONST_FOLDER_DELIMITER = "\";
        
        CONST_LIST_SAVE_PATH = Mouse.SHARED_FILE_LOCATION +  "\shared\Timna\Gal Projects\Mouse Lists";
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
                mouseStruct.Path = strrep(mouseStruct.Path, "W:", Mouse.SHARED_FILE_LOCATION);
                curMouse = load(mouseStruct.Path).obj;
                obj.LoadedMouseList = [obj.LoadedMouseList, curMouse];
            end
        end
        
        % ============================= Plot ==============================
        % ============= Plot =============
        
        % ==== Separately ====
        function plotCrossAndAutoCorrealtionByMouse(obj, descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotCrossAndAutoCorrelation(descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
                    %                     savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross And Auto Correlation\" + signalTitle + "\Concat - " + shouldReshape + "\" +  obj.Type + "\" + mouse.Name + " - " + signalTitle)
                end
            end
        end
        
        % ==== Correlation ====
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
        
        function plotScatterPlotWithAndWithoutLick(obj, timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor)
            figure();
            amountOfMice = size(obj.LoadedMouseList, 2);
            
            for mouseIndex = 1:amountOfMice
                mouse = obj.LoadedMouseList(mouseIndex);
                
                [gcampNoLickSignal, jrgecoNoLickSignal, gcampLickCutSignal, jrgecoLickCutSignal, ~] = mouse.getConcatTaskNoLick(timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor);
                
                gcampLickCutSignal = (gcampLickCutSignal(~isnan(gcampLickCutSignal(:, 1)), :));
                jrgecoLickCutSignal = (jrgecoLickCutSignal(~isnan(jrgecoLickCutSignal(:, 1)), :));
                
                gcampLickCutSignal = downsample(gcampLickCutSignal', downsampleFactor)';
                jrgecoLickCutSignal = downsample(jrgecoLickCutSignal', downsampleFactor)';
                
                amountOfLicks = size(gcampLickCutSignal, 1);
                lenOfLick = size(gcampLickCutSignal, 2);
                
                gcampLickSignal = reshape(gcampLickCutSignal', 1, []);
                jrgecoLickSignal = reshape(jrgecoLickCutSignal', 1, []);
                
                colorsForLick = linspace(1, 10, amountOfLicks);
                colorsForLick = repelem(colorsForLick, lenOfLick);
                
                % Plot No Lick
                noLickPlot = subplot(3, amountOfMice, mouseIndex);
                colorForNoLick = linspace(1, 10, length(gcampNoLickSignal));
                
                scatter(noLickPlot, gcampNoLickSignal, jrgecoNoLickSignal, 2, colorForNoLick, 'filled')
                
                    % Best fit line
                coefficients = polyfit(gcampNoLickSignal,  jrgecoNoLickSignal, 1);
                fitted = polyval(coefficients, gcampNoLickSignal);
                line(noLickPlot, gcampNoLickSignal, fitted, 'Color', 'black', 'LineStyle', '--')
                
                title(noLickPlot, "Mouse: " + mouse.Name + ", No lick Signal")
                
                % Plot Lick
                lickPlot = subplot(3, amountOfMice, mouseIndex + amountOfMice);
                scatter(lickPlot, gcampLickSignal, jrgecoLickSignal, 2, colorsForLick, 'filled')
                title(lickPlot, "Lick Signal")
                
                % Plot together
                generalPlot = subplot(3, amountOfMice, mouseIndex + 2 * amountOfMice);
                
                [gcampSignal, jrgecoSignal, ~, ~, ~] = mouse.getInformationDownsampleAndSmooth(["Task", "onset"], smoothFactor, downsampleFactor, true);
                scatter(generalPlot, gcampSignal, jrgecoSignal, 2, 'filled')
                title(generalPlot, "General Signal")
            end
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
        
        function plotCorrWithOrWithoutLick(obj, straightenedBy, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            amoutOfMice = size(obj.LoadedMouseList, 2);
            
            miceCorrelation = zeros(1, amoutOfMice);
            miceCorrelationLick = zeros(1, amoutOfMice);
            miceCorrelationNoLick = zeros(1, amoutOfMice);
            
            miceNames = strings(1, amoutOfMice);
            
            for mouseIndx = 1:amoutOfMice
                mouse = obj.LoadedMouseList(mouseIndx);
                
                % General Correlation
                mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                miceCorrelation(1, mouseIndx) = mouseCorrelation;
                
                if mouse.signalExists(descriptionVector)
                    
                    [gcampSignal, jrgecoSignal, ~, ~, signalTitle] = mouse.getRawSignals(descriptionVector);
                    
                    tInfo = mouse.getTInfo(descriptionVector);
                    
                    % Correlation When Lick
                    lickGcampSignal = gcampSignal(~(isnan(tInfo.first_lick)), :);
                    lickJrgecoSignal = jrgecoSignal(~(isnan(tInfo.first_lick)), :);
                    
                    lickGcampSignal = reshape(lickGcampSignal', 1, []);
                    lickJrgecoSignal = reshape(lickJrgecoSignal', 1, []);
                    
                    lickGcampSignal = smooth(lickGcampSignal', smoothFactor)';
                    lickJrgecoSignal = smooth(lickJrgecoSignal', smoothFactor)';
                    
                    lickGcampSignal = downsample(lickGcampSignal, downsampleFactor);
                    lickJrgecoSignal = downsample(lickJrgecoSignal, downsampleFactor);
                    
                    lickCorrelation = corr(lickGcampSignal', lickJrgecoSignal');
                    miceCorrelationLick(mouseIndx) = lickCorrelation;
                    
                    % Correlation When No Lick
                    noLickGcampSignal = gcampSignal(isnan(tInfo.first_lick), :);
                    noLickJrgecoSignal = jrgecoSignal(isnan(tInfo.first_lick), :);
                    
                    noLickGcampSignal = reshape(noLickGcampSignal', 1, []);
                    noLickJrgecoSignal = reshape(noLickJrgecoSignal', 1, []);
                    
                    noLickGcampSignal = smooth(noLickGcampSignal', smoothFactor)';
                    noLickJrgecoSignal = smooth(noLickJrgecoSignal', smoothFactor)';
                    
                    noLickGcampSignal = downsample(noLickGcampSignal, downsampleFactor);
                    noLickJrgecoSignal = downsample(noLickJrgecoSignal, downsampleFactor);
                    
                    noLickCorrelation = corr(noLickGcampSignal', noLickJrgecoSignal');
                    miceCorrelationNoLick(mouseIndx) = noLickCorrelation;
                    
                else
                    miceCorrelationLick(mouseIndx) = 0;
                    miceCorrelationNoLick(mouseIndx) = 0;
                end
                
                % General
                miceNames(1, mouseIndx) = mouse.Name;
            end
            
            obj.drawRelativeBubbleByMouse(miceCorrelation, miceCorrelationLick, miceCorrelationNoLick, miceNames, "Correlation with and without lick", signalTitle, ["General Correlation", "Correlation Trials With Lick", "Correlation Trials Without Lick"], -5, 15, 0, 0, smoothFactor, downsampleFactor)
            % obj.drawTwoBubble(miceCorrelation, miceCorrelationLick, miceCorrelationLick, miceCorrelationNoLick, miceCorrelationNoLick, signalTitle, 0, 0, 0, smoothFactor, downsampleFactor, true)
        end
        
        function plotCorrWithOrWithoutMovement(obj, straightenedBy, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            amoutOfMice = size(obj.LoadedMouseList, 2);
            
            miceCorrelation = zeros(1, amoutOfMice);
            miceCorrelationMovement = zeros(1, amoutOfMice);
            miceCorrelationNoMovement = zeros(1, amoutOfMice);
            
            miceNames = strings(1, amoutOfMice);
            
            for mouseIndx = 1:amoutOfMice
                mouse = obj.LoadedMouseList(mouseIndx);
                
                % General Correlation
                mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                miceCorrelation(1, mouseIndx) = mouseCorrelation;
                
                if mouse.signalExists(descriptionVector)
                    
                    [gcampSignal, jrgecoSignal, ~, ~, signalTitle] = mouse.getRawSignals(descriptionVector);
                    
                    tInfo = mouse.getTInfo(descriptionVector);
                    
                    % Correlation With Movement
                    movementGcampSignal = gcampSignal(tInfo.has_movement == 1, :);
                    movementJrgecoSignal = jrgecoSignal(tInfo.has_movement == 1, :);
                    
                    movementGcampSignal = reshape(movementGcampSignal', 1, []);
                    movementJrgecoSignal = reshape(movementJrgecoSignal', 1, []);
                    
                    movementGcampSignal = smooth(movementGcampSignal', smoothFactor)';
                    movementJrgecoSignal = smooth(movementJrgecoSignal', smoothFactor)';
                    
                    movementGcampSignal = downsample(movementGcampSignal, downsampleFactor);
                    movementJrgecoSignal = downsample(movementJrgecoSignal, downsampleFactor);
                    
                    movementCorrelation = corr(movementGcampSignal', movementJrgecoSignal');
                    miceCorrelationMovement(mouseIndx) = movementCorrelation;
                    
                    % Correlation When No Lick
                    noMovementGcampSignal = gcampSignal(tInfo.has_movement == 0, :);
                    noMovementJrgecoSignal = jrgecoSignal(tInfo.has_movement == 0, :);
                    
                    noMovementGcampSignal = reshape(noMovementGcampSignal', 1, []);
                    noMovementJrgecoSignal = reshape(noMovementJrgecoSignal', 1, []);
                    
                    noMovementGcampSignal = smooth(noMovementGcampSignal', smoothFactor)';
                    noMovementJrgecoSignal = smooth(noMovementJrgecoSignal', smoothFactor)';
                    
                    noMovementGcampSignal = downsample(noMovementGcampSignal, downsampleFactor);
                    noMovementJrgecoSignal = downsample(noMovementJrgecoSignal, downsampleFactor);
                    
                    noMovementCorrelation = corr(noMovementGcampSignal', noMovementJrgecoSignal');
                    miceCorrelationNoMovement(mouseIndx) = noMovementCorrelation;
                    
                else
                    miceCorrelationMovement(mouseIndx) = 0;
                    miceCorrelationNoMovement(mouseIndx) = 0;
                end
                
                % General
                miceNames(1, mouseIndx) = mouse.Name;
            end
            
            obj.drawRelativeBubbleByMouse(miceCorrelation, miceCorrelationMovement, miceCorrelationNoMovement, miceNames, "Correlation with and without movement", signalTitle, ["General Correlation", "Correlation Trials With Movement", "Correlation Trials Without Movement"], -5, 15, 0, 0, smoothFactor, downsampleFactor)
            % obj.drawTwoBubble(miceCorrelation, miceCorrelationLick, miceCorrelationLick, miceCorrelationNoLick, miceCorrelationNoLick, signalTitle, 0, 0, 0, smoothFactor, downsampleFactor, true)
        end
        
        % === Sliding Correlation ===
        function plotSlidingCorrelationBar(obj, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots two graphs - one is of bars where one can see each of
            % the mice separately, and the other is a summary one with the
            % mean of all the mice. The bars are the mean / median of
            % the sliding window values and the categories are all the
            % possible categories (no bar for a category that has no data,
            % eg. a mouse that didnt have a pre-awake-FS recording session).
            % The function first smooths the signals, then downsamples them
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
        
        function plotSlidingCorrelationTaskByOutcomeByTimePeriods(obj, straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the sliding correlation by outcome (one over the other)
            % and each is broken into points of the median of the sliding
            % in the time period (1 sec)
            
            checkedStrartTimes = -5:1:14;
            checkedEndTimes = -4:1:15;
            
            % Create ax for each outcome     
            amountOfOutcomes = size(Mouse.CONST_TASK_OUTCOMES, 2);
            axByOutcome = [];
            
            fig = figure('Position', [450,109,961,860]);
            for outcomeIndx = 1:amountOfOutcomes
                ax = subplot(amountOfOutcomes, 1, outcomeIndx);
                axByOutcome = [axByOutcome, ax];
            end
            
            % Init
            amountOfTimeChecked = size(checkedStrartTimes, 2);
            amoutOfMice = size(obj.LoadedMouseList, 2);
            miceNames = strings(1, amoutOfMice);
            mousesSliding = zeros(amountOfOutcomes, amountOfTimeChecked);
            xAxe = 1:amountOfTimeChecked;
            
            % Get Data
            for mouseIndx = 1:amoutOfMice
                mouse = obj.LoadedMouseList(mouseIndx);
                miceNames(mouseIndx) = mouse.Name;
                
                for timeIndx = 1:amountOfTimeChecked
                    startTime = checkedStrartTimes(timeIndx);
                    endTime = checkedEndTimes(timeIndx);
                    
                    [~, ~, ~, ~, ~, ~, ~, outcomesMeanSliding, ~, signalTitle]  = mouse.dataForPlotSlidingCorrelationTaskByOutcome(straightenedBy, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    mousesSliding(:, timeIndx) = median(outcomesMeanSliding, 2);
                end
                
                % Plot all mice in group in all different outcome figures
                for outcomeIndx = 1:amountOfOutcomes
                    plot(axByOutcome(outcomeIndx), xAxe, mousesSliding(outcomeIndx,:), 'o-')
                    hold(axByOutcome(outcomeIndx), 'on')
                end
            end
            
            xLabels = strings(1, amountOfTimeChecked);
            
            for timeIndx = 1:amountOfTimeChecked
                xLabels(timeIndx) = "from " + checkedStrartTimes(timeIndx) + " to " + checkedEndTimes(timeIndx);
            end
            
            % Add Titles
            legend(axByOutcome(1), miceNames, 'Location', 'best')
            
            for outcomeIndx = 1:amountOfOutcomes
                ax = axByOutcome(outcomeIndx);
                outcome = Mouse.CONST_TASK_OUTCOMES(outcomeIndx);
                
                title(ax, "Sliding Correlation for " + outcome)
                xlim(ax, [0.75, amountOfTimeChecked + 0.25])
                ax.XTick = [1: amountOfTimeChecked];
                ax.XTickLabel = xLabels';
                ylabel(ax, "Sliding")
            end
            
            sgtitle(fig, {"Sliding in Task by times for " + obj.Type, signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Outcome by time\by " + straightenedBy + " - " + obj.Type + " - " + timeWindow + " sec")
            
        end
        
        function plotSlidingCorrelationTaskByOutcome(obj, straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the sliding correlation by outcome (one over the other)
            % and each is broken into points of the median of the sliding
            % in the time period (1 sec)
            
            % Create ax for each outcome     
            amountOfOutcomes = size(Mouse.CONST_TASK_OUTCOMES, 2);
            axByOutcome = [];
            
            fig = figure('Position', [450,109,961,860]);
            for outcomeIndx = 1:amountOfOutcomes
                ax = subplot(amountOfOutcomes, 1, outcomeIndx);
                axByOutcome = [axByOutcome, ax];
            end
            
            % Init
            amountOfTimeChecked = size(checkedStrartTimes, 2);
            amoutOfMice = size(obj.LoadedMouseList, 2);
            miceNames = strings(1, amoutOfMice);
            mousesSliding = zeros(amountOfOutcomes, amountOfTimeChecked);
            xAxe = 1:amountOfTimeChecked;
            
            % Get Data
            for mouseIndx = 1:amoutOfMice
                mouse = obj.LoadedMouseList(mouseIndx);
                miceNames(mouseIndx) = mouse.Name;
                
                for timeIndx = 1:amountOfTimeChecked
                    startTime = checkedStrartTimes(timeIndx);
                    endTime = checkedEndTimes(timeIndx);
                    
                    [~, ~, ~, ~, ~, ~, ~, outcomesMeanSliding, ~, signalTitle]  = mouse.dataForPlotSlidingCorrelationTaskByOutcome(straightenedBy, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    mousesSliding(:, timeIndx) = median(outcomesMeanSliding, 2);
                end
                
                % Plot all mice in group in all different outcome figures
                for outcomeIndx = 1:amountOfOutcomes
                    plot(axByOutcome(outcomeIndx), xAxe, mousesSliding(outcomeIndx,:), 'o-')
                    hold(axByOutcome(outcomeIndx), 'on')
                end
            end
            
            xLabels = strings(1, amountOfTimeChecked);
            
            for timeIndx = 1:amountOfTimeChecked
                xLabels(timeIndx) = "from " + checkedStrartTimes(timeIndx) + " to " + checkedEndTimes(timeIndx);
            end
            
            % Add Titles
            legend(axByOutcome(1), miceNames, 'Location', 'best')
            
            for outcomeIndx = 1:amountOfOutcomes
                ax = axByOutcome(outcomeIndx);
                outcome = Mouse.CONST_TASK_OUTCOMES(outcomeIndx);
                
                title(ax, "Sliding Correlation for " + outcome)
                xlim(ax, [0.75, amountOfTimeChecked + 0.25])
                ax.XTick = [1: amountOfTimeChecked];
                ax.XTickLabel = xLabels';
                ylabel(ax, "Sliding")
            end
            
            sgtitle(fig, {"Sliding in Task by times for " + obj.Type, signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Outcome by time\by " + straightenedBy + " - " + obj.Type + " - " + timeWindow + " sec")
            
        end
        
        function plotSlidingWithAndWithoutLick(obj, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            amoutOfMice = size(obj.LoadedMouseList, 2);
            
            % miceGeneralSliding = zeros(amoutOfMice, 1);
            miceNoLickSliding = zeros(amoutOfMice, 1);
            miceLickSliding = zeros(amoutOfMice, 1);
            
            miceNames = strings(amoutOfMice, 1);
            
            for mouseIndx = 1:amoutOfMice
                mouse = obj.LoadedMouseList(mouseIndx);
                
                % Sliding Full Signal
                % [medianFullSignalSliding, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                % miceGeneralSliding(mouseIndx, 1) = medianFullSignalSliding;
                
                [noLickCorrelationVector, lickCorrelationVector] = mouse.getSlidingCorrelationWithAndWithoutLick(timeWindow, timeShift, timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor);
                
                % Sliding Correlation Lick Removed
                medianNoLickSliding = median(noLickCorrelationVector);
                miceNoLickSliding(mouseIndx, 1) = medianNoLickSliding;
                
                % Sliding Correlation Only Lick
                medianLickSliding = median(lickCorrelationVector);
                miceLickSliding(mouseIndx, 1) = medianLickSliding;
                
                % General
                miceNames(mouseIndx, 1) = mouse.Name;
            end
            
            obj.drawRelativeBubbleByMouse([miceNoLickSliding, miceLickSliding], miceNames, "Sliding Correlation With and Without Lick", signalTitle, ["No Lick Sliding \fontsize{7}(median)", "Lick Sliding \fontsize{7}(median)"], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor) % "Overall Sliding \fontsize{7}(median)",
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\By Group\" + obj.Type + " - " + signalTitle + " - By Mouse, Cut by " + timeToRemove)
            
            obj.drawTwoBubble(miceNoLickSliding, [], miceLickSliding, [], "Sliding Correlation With and Without Lick", signalTitle, ["No Lick Sliding \fontsize{7}(median)", "Lick Sliding \fontsize{7}(median)"], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor, true, false)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\By Group\" + obj.Type + " - " + signalTitle + " - All Mice, Cut by " + timeToRemove)
            
        end
        
        % TODO (?)
        function plotSlidingWindowHistogramWithAndWithoutLick(obj, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            % Bin Init
            numOfBins = 100;
            histogramEdges = linspace(-1, 1, numOfBins + 1);
            
            % General Init
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            amoutOfMice = size(obj.LoadedMouseList, 2);
            miceNames = strings(1, amoutOfMice);
            
            % Figure Init
            figure();
            
            for mouseIndx = 1:amoutOfMice
                mouse = obj.LoadedMouseList(mouseIndx);
                
                % Full Signal
                [fullGcampSignal, fullJrgecoSignal, ~, ~, fs] = obj.getInformationDownsampleAndSmooth(descriptionVector, smoothFactor, downsampleFactor, true);
                [fullSignalCorrelationVector, ~] = obj.getSlidingCorrelation(timeWindow, timeShift, fullGcampSignal, fullJrgecoSignal, fs);
                [fullSignalBinCount,~] = histcounts(fullSignalCorrelationVector, histogramEdges, 'Normalization', 'probability');
                
                [noLickCorrelationVector, lickCorrelationVector] = getSlidingCorrelationWithAndWithoutLick(obj, timeWindow, timeShift, timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor)
                
                % Sliding Correlation Lick Removed
                [noLickBinCount,~] = histcounts(noLickCorrelationVector, histogramEdges, 'Normalization', 'probability');
                
                % Sliding Correlation Only Lick
                [lickCorrelationVector, ~] = mouse.getSlidingCorrelation(timeWindow, timeShift, gcampLickSignal, jrgecoLickSignal, fs);
                [lickBinCount,~] = histcounts(lickCorrelationVector, histogramEdges, 'Normalization', 'probability');
            end
        end
        
        function passiveWithVSWithoutPassiveOnset(obj, descriptionVector, condition, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots all the mice with or without the onset in passive -
            % useful to compare pre VS post
            
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            amoutOfMiceInGroup = size(obj.LoadedMouseList, 2);
            
            miceNoOnsetSliding = [];
            miceOnsetSliding = [];
            miceNames = [];
            
            for mouseIndx = 1:amoutOfMiceInGroup
                mouse = obj.LoadedMouseList(mouseIndx);
                
                if mouse.signalExists(descriptionVector)
                    miceNames = [miceNames; mouse.Name];
                    
                    [noOnsetCorrelationVector, onsetCorrelationVector] = mouse.getSlidingCorrelationWithAndWithoutOnsetPassive(descriptionVector, condition, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    
                    % Sliding Correlation Onset Removed
                    medianNoOnsetSliding = median(noOnsetCorrelationVector);
                    miceNoOnsetSliding = [miceNoOnsetSliding; medianNoOnsetSliding];
                    
                    % Sliding Correlation Only Onset
                    medianOnsetSliding = median(onsetCorrelationVector);
                    miceOnsetSliding = [miceOnsetSliding; medianOnsetSliding];
                end
            end
            % xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
            % labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["Not Onset, Sliding of " + obj.Type + "\fontsize{7}(median)", "Onset, Sliding of " + obj.Type + "\fontsize{7}(median)"];
            
            obj.drawRelativeBubbleByMouse([miceNoOnsetSliding, miceOnsetSliding], miceNames, "Sliding Correlation With VS Without Passive Onset", signalTitle, ["Sliding No Onset \fontsize{7}(median)", "Sliding Onset \fontsize{7}(median)"], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor) % "Correlation No Lick",
        end
        
        % == Separately ==
        function plotSlidingCorrelationTaskByOutcomeEachMouse(obj, straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the sliding correlation of each mouse in a separate
            % graph
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotSlidingCorrelationTaskByOutcome(straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
                    %                      savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Outcome\by " + straightenedBy + "\" + obj.Type + "\" + mouse.Name + " -" + timeWindow + " sec")
                end
            end
        end
        
        function plotSlidingCorrelationOmissionLick(obj, straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotSlidingCorrelationOmissionLick(straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
                    savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Lick vs. No Lick\by " + straightenedBy + "\" + obj.Type + "\" + mouse.Name + " - " + timeWindow + " sec")
                end
            end
        end
        
        % === Cross Correlation ===
        function plotCrossAndAutoCorrealtionAverage(obj, descriptionVector, maxLag, lim, smoothFactor, downsampleFactor, shouldReshape)
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            allMiceCross = [];
            allMiceAutoFirst = [];
            allMiceAutoSecond = [];
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    [firstXSecond, timeVector, signalTitle] = mouse.dataForPlotCrossCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
                    [firstXfirst, secondXsecond, ~, ~] = mouse.dataForPlotAutoCorrelation(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
                    
                    allMiceCross = [allMiceCross; firstXSecond];
                    allMiceAutoFirst = [allMiceAutoFirst; firstXfirst];
                    allMiceAutoSecond = [allMiceAutoSecond; secondXsecond];
                end
            end
            meanMiceCross = mean(allMiceCross, 1);
            SEMMiceCross = std(allMiceCross, 1)/sqrt(size(allMiceCross, 1));
            meanMiceAutoFirst = mean(allMiceAutoFirst, 1);
            SEMMiceAutoFirst = std(allMiceAutoFirst, 1)/sqrt(size(allMiceAutoFirst, 1));
            meanMiceAutoSecond = mean(allMiceAutoSecond, 1);
            SEMMiceAutoSecond = std(allMiceAutoSecond, 1)/sqrt(size(allMiceAutoSecond, 1));
            
            first = mouse.GCAMP;
            second = mouse.JRGECO;
            
            [~, lagIndex] = max(meanMiceCross);
            
            obj.drawCrossCorrelation([meanMiceCross; meanMiceAutoFirst; meanMiceAutoSecond], [SEMMiceCross; SEMMiceAutoFirst; SEMMiceAutoSecond], timeVector, lim, ["Cross", "Auto - " + first, "Auto - " + second], signalTitle, {"Cross and Auto Correlation Between " + first + " and " + second + ", lag of "+ timeVector(lagIndex), "All Mice Type " + obj.Type}, smoothFactor, downsampleFactor, shouldReshape)
            savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross And Auto Correlation\" + signalTitle + "\Concat - " + shouldReshape + "\" +  obj.Type + "\" + obj.Type + " - average all - " + signalTitle)
        end
        
        function plotCrossCorrelationLagBar(obj, descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape)
            [signalTitle, firstSignal, secondSignal, timeLagVec, maxHeightVec, mouseNames] = obj.dataForPlotCrossCorrelationLagBar(descriptionVector, maxLag, smoothFactor, downsampleFactor, shouldReshape);
            
            % By mouse
            obj.drawBarByMouse(timeLagVec, mouseNames, firstSignal + " VS. " + secondSignal, "Lag \fontsize{9}(sec)", {"Cross correlation lag - by mouse", signalTitle, "Max lag - " + maxLag}, smoothFactor, downsampleFactor, true);
            %             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross Correlation\" + signalTitle + "\Concat - " + shouldReshape + "\" +  obj.Type + "\" + " Cross correlation lag - by mouse")
            
            obj.drawBarByMouse(maxHeightVec, mouseNames, firstSignal + " VS. " + secondSignal, "Cross correlation \fontsize{9}(normalized)", {"Cross correlation maximum by mouse", signalTitle, "Max lag - " + maxLag}, smoothFactor, downsampleFactor, true);
            %             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross Correlation\" + signalTitle + "\Concat - " + shouldReshape + "\" +  obj.Type + "\" + " Cross correlation maximum - by mouse")
            
        end
        
        % == Separately ==
        function plotCrossCorrelationTaskByOutcome(obj, straightenedBy, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotCrossCorrelationTaskByOutcome(straightenedBy, smoothFactor, downsampleFactor)
                    savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross By Task - Outcome\by " + straightenedBy + "\" + obj.Type + "\" + mouse.Name)
                end
            end
        end
        
        function plotCrossCorrelationOmissionLick(obj, straightenedBy, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotCrossCorrelationOmissionLick(straightenedBy, smoothFactor, downsampleFactor)
                    savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross By Task - Lick vs. No Lick\by " + straightenedBy + "\" + obj.Type + "\" + mouse.Name)
                end
            end
        end
        
        function plotCrossCorrelationTaskByOutcomeBeginning(obj, straightenedBy, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotCrossCorrelationTaskByOutcomeBeginning(straightenedBy, smoothFactor, downsampleFactor)
                    savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross By Task Beginning - Outcome\by " + straightenedBy + "\" + obj.Type + "\" + mouse.Name)
                end
            end
        end
        
        function plotCrossCorrelationOmissionLickBeginning(obj, straightenedBy, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for mouse = obj.LoadedMouseList
                if mouse.signalExists(descriptionVector)
                    mouse.plotCrossCorrelationOmissionLickBeginning(straightenedBy, smoothFactor, downsampleFactor)
                    savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Cross By Task Beginning - Lick vs. No Lick\by " + straightenedBy + "\" + obj.Type + "\" + mouse.Name)
                end
            end
        end
        
        % === Comparison Correlation ===
        function plotCorrVsSliding(obj, straightenedBy, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            descriptionVector = ["Task", straightenedBy];
            [~, ~, ~, ~, signalTitle] = obj.LoadedMouseList(1).getRawSignals(descriptionVector);
            
            amoutOfMice = size(obj.LoadedMouseList, 2);
            
            % miceCorrelationNoLick = zeros(amoutOfMice, 1);
            miceCorrelation = zeros(amoutOfMice, 1);
            shuffledCorrelation = zeros(amoutOfMice, 1);
            
            miceSliding = zeros(amoutOfMice, 1);
            shuffledSliding = zeros(amoutOfMice, 1);
            
            miceNames = strings(amoutOfMice, 1);
            
            for mouseIndx = 1:amoutOfMice
                mouse = obj.LoadedMouseList(mouseIndx);
                
                % Correlation Lick Removed
                % mouseCorrelationNoLick = mouse.getWholeSignalCorrelationNoLick(timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor, false);
                % miceCorrelationNoLick(mouseIndx, 1) = mouseCorrelationNoLick;
                
                % Correlation
                mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                miceCorrelation(mouseIndx, 1) = mouseCorrelation;
                
                curShuffleCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, true);
                shuffledCorrelation(mouseIndx, 1) = curShuffleCorrelation;
                
                % Sliding concat
                [mouseSliding, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                miceSliding(mouseIndx, 1) = mouseSliding;
                
                [curShuffledSliding, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, true);
                shuffledSliding(mouseIndx, 1) = curShuffledSliding;
                
                % General
                miceNames(mouseIndx, 1) = mouse.Name;
            end
            
            obj.drawRelativeBubbleByMouse([miceCorrelation, miceSliding], miceNames, "Correlation Vs. Sliding Correlation", signalTitle, ["Correlation", "Sliding Concat \fontsize{7}(median)"], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor) % "Correlation No Lick", 
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\By Group\" + obj.Type + " - " + signalTitle + " - By Mouse, Cut by " + timeToRemove)
            
            obj.drawTwoBubble(miceCorrelation, shuffledCorrelation, miceSliding, shuffledSliding, "Correlation Vs. Sliding Correlation - all mice", signalTitle, ["Correlation", "Sliding Correlation \fontsize{7}(median)"], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor, true, true)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\By Group\" + obj.Type + " - " + signalTitle + " - All Mice, Cut by " + timeToRemove)
            
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
        
        function drawRelativeBubbleByMouse(obj, dataMatrix, miceNames, generalTitle, signalTitle, xLabels, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            fig = figure('Position', [555,407,799,511]);
            ax = axes;
            
            endPoint = size(dataMatrix, 2)/2 + 0.5;
            xAxe = 1:0.5:endPoint;
            
            for idx = 1:size(miceNames, 1)
                plot(ax, xAxe, dataMatrix(idx, :), 'o-')
                hold on
            end
            hold off
            
            legend(ax, miceNames, 'Location', 'best')           
            
            title(ax, {generalTitle, obj.Type, signalTitle, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter + ", Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, endPoint + 0.25])
            ax.XTick = xAxe;
            ax.XTickLabel = xLabels;
            ylabel(ax, "Correlation")
            
        end
        
        function drawTwoBubble(obj, first, firstShuffled, second, secondShuffled, generalTitle, signalTitle, xLabels, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor, shouldPlotIndividuals, shouldPlotShuffeled)
            
            % Calcl Mean
            firstMean = mean(nonzeros(first));
            firstRandomMean = mean(firstShuffled);
            secondMean = mean(nonzeros(second));
            secondRandomMean = mean(secondShuffled);
            
            
            % Calc SEM
            firstSEM = std(first)/sqrt(length(first));
            firstRandomSEM = std(firstShuffled)/sqrt(length(firstShuffled));
            secondSEM =  std(second)/sqrt(length(second));
            secondRandomSEM =  std(secondShuffled)/sqrt(length(secondShuffled));
            
            % Figure
            fig = figure('Position', [711,425,401,511]);
            ax = axes;
            xAxe = [1, 1.5];
            randXAxe = xAxe; % [1, 1.5];
            
            % Plot
            % errorbar(ax, xAxe, [firstMean, secondMean], [firstSEM, secondSEM],'o', 'LineWidth', 1, 'color', '#800080', 'MarkerFaceColor', '#800080', 'MarkerSize', 6, 'CapSize', 12)
            plot(ax, xAxe, [firstMean, secondMean], 'd', 'LineWidth', 1, 'color', '#800080', 'MarkerFaceColor', '#800080', 'MarkerSize', 8)
            
            hold on
            
            if shouldPlotShuffeled
                % errorbar(ax, randXAxe, [firstRandomMean, secondRandomMean], [firstRandomSEM, secondRandomSEM],'o', 'LineWidth', 1, 'color', '#C0C0C0', 'MarkerFaceColor', '#C0C0C0', 'MarkerSize', 6, 'CapSize', 12)
                plot(ax, randXAxe, [firstRandomMean, secondRandomMean],'o', 'LineWidth', 1, 'color', '#C0C0C0', 'MarkerFaceColor', '#C0C0C0', 'MarkerSize', 6)
            end
            
            if shouldPlotIndividuals
                for idx = 1:size(first, 1)
                    plot(ax, xAxe, [first(idx), second(idx)], 'o-', 'color', 'black', 'MarkerFaceColor', 'black', 'MarkerSize', 4)
                    hold on
                end
            end
            hold off
            
            % Titles
            legend(ax, 'Mice Mean', 'Shuffled', 'Individuals', 'Location', 'best')
            
            title(ax, {generalTitle, obj.Type, signalTitle, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter + ", Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, xAxe(end) + 0.25])
            ax.XTick = xAxe;
            ax.XTickLabel = xLabels;
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
    
    methods (Static)
        function drawCrossCorrelation(crossCorrList, SEMList, timeVector, lim, legendList, signalTitle, CrossType, smoothFactor, downsampleFactor, shouldReshape)
            % Draws the plot for the plotCrossCorrelation function.
            fig = figure();
            ax = gca;
            
            colors = ['r', 'b', 'g'];
            plots = [];
            
            for idx = 1:size(crossCorrList, 1)
                plots = [plots, shadedErrorBar(timeVector, crossCorrList(idx,:), SEMList(idx, :), colors(idx)).mainLine];
                % plot(ax, timeVector, crossCorrList(idx,:), 'LineWidth', 1.5);
                hold on
            end
            hold off
            
            legend(plots, legendList, 'Location', 'best', 'AutoUpdate','off')
            set(0,'DefaultLegendAutoUpdate','off')
            
            title(ax, [CrossType,  signalTitle, "\fontsize{9}Concatenated: " + shouldReshape, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor], 'FontSize', 12)
            
            xlabel("Time Shift (sec)", 'FontSize', 14)
            ylabel("Cross Correlation (normalized)", 'FontSize', 14)
            
            yline(ax, 0, 'Color', [192, 192, 192]/255)
            xline(ax, 0, 'Color', [192, 192, 192]/255)
            xlim(ax, [-lim, lim])
        end
        
    end
end