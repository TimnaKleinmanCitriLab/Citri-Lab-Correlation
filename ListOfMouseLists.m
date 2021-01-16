classdef ListOfMouseLists < handle
    
    properties
        OfcAcc
        AudAcc
        AccInAccOut
        AudInAccOut
        AudInAudOut
        ListOfLists
    end
    
    
    methods
        function obj = ListOfMouseLists()
            % Constructs an instance of this class, and loades all the relavent
            % MouseLists
            
            obj.OfcAcc = load('W:\shared\Timna\Gal Projects\Mouse Lists\OfcAccMice.mat').obj;
            obj.AudInAccOut = load('W:\shared\Timna\Gal Projects\Mouse Lists\AudInAccOutMice.mat').obj;
            obj.AccInAccOut = load('W:\shared\Timna\Gal Projects\Mouse Lists\AccInAccOutMice.mat').obj;
            obj.AudInAudOut = load('W:\shared\Timna\Gal Projects\Mouse Lists\AudInAudOutMice.mat').obj;
            obj.AudAcc = load('W:\shared\Timna\Gal Projects\Mouse Lists\AudAccMice.mat').obj;
            
            obj.OfcAcc.loadMice()
            obj.AudInAccOut.loadMice()
            obj.AccInAccOut.loadMice()
            obj.AudInAudOut.loadMice()
            obj.AudAcc.loadMice()
            
            obj.ListOfLists = [obj.OfcAcc, obj.AudInAccOut, obj.AccInAccOut, obj.AudInAudOut, obj.AudAcc];
            
        end
        
        function plotSlidingCorrelationBuble(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            firstList = obj.ListOfLists(1);
            mouse = firstList.LoadedMouseList(1);
            [~, ~, ~, ~, signalTitle] = mouse.getRawSignals(descriptionVector);
            
            % data
            groupsSliding = [];
            
            groupSlidingMean = [];
            groupSlidingSEM = [];
            miceType = [];
            
            shuffledSlidingMean = [];
            shuffledSlidingSEM = [];
            
            for mouseList = obj.ListOfLists
                slidingMedianPerGroup = [];
                shuffled = [];
                for mouse = mouseList.LoadedMouseList
                    [mouseSlidingMedian, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                    slidingMedianPerGroup = [slidingMedianPerGroup, mouseSlidingMedian];
                    
                    [shuffledMedian, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, true);
                    shuffled = [shuffled, shuffledMedian];
                end
                groupsSliding = [groupsSliding; {slidingMedianPerGroup}];
                groupSlidingMean = [groupSlidingMean, mean(slidingMedianPerGroup)];
                groupSlidingSEM = [groupSlidingSEM, std(slidingMedianPerGroup)/sqrt(length(slidingMedianPerGroup))];
                miceType = [miceType, mouseList.Type];
                
                shuffledSlidingMean = [shuffledSlidingMean, mean(shuffled)];
                shuffledSlidingSEM = [shuffledSlidingSEM, std(shuffled)/sqrt(length(shuffled))];
            end
            
            % plot
            obj.drawBubleAllMice(groupSlidingMean, groupSlidingSEM, miceType, "Median of sliding window" , {signalTitle, "Median of sliding window - all", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, true, shuffledSlidingMean, shuffledSlidingSEM)
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Sliding of all mice groups - " + signalTitle)
            obj.drawBubleByMouse(groupsSliding, groupSlidingMean, miceType, "Median of sliding window", {signalTitle, "Median of sliding window -  by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor)
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Sliding by mouse - " + signalTitle)
        end
        
        function plotCorrelationBuble(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            firstList = obj.ListOfLists(1);
            mouse = firstList.LoadedMouseList(1);
            [~, ~, ~, ~, signalTitle] = mouse.getRawSignals(descriptionVector);
            
            % data
            groupsCorrelation = [];
            
            groupCorrelationMean = [];
            groupCorrelationSEM = [];
            miceType = [];
            
            shuffledCorrelationMean = [];
            shuffledCorrelationSEM = [];
            
            for mouseList = obj.ListOfLists
                correlationPerGroup = [];
                shuffled = [];
                for mouse = mouseList.LoadedMouseList
                    mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                    correlationPerGroup = [correlationPerGroup, mouseCorrelation];
                    
                    shuffledCorelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, true);
                    shuffled = [shuffled, shuffledCorelation];
                end
                groupsCorrelation = [groupsCorrelation; {correlationPerGroup}];
                groupCorrelationMean = [groupCorrelationMean, mean(correlationPerGroup)];
                groupCorrelationSEM = [groupCorrelationSEM, std(correlationPerGroup)/sqrt(length(correlationPerGroup))];
                miceType = [miceType, mouseList.Type];
                
                shuffledCorrelationMean = [shuffledCorrelationMean, mean(shuffled)];
                shuffledCorrelationSEM = [shuffledCorrelationSEM, std(shuffled)/sqrt(length(shuffled))];
            end
            
            % plot
            obj.drawBubleByMouse(groupsCorrelation, groupCorrelationMean, miceType, "Median of sliding window", {signalTitle, "Median of sliding window -  by mouse", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor)
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Sliding by mouse - " + signalTitle)
            obj.drawBubleAllMice(groupCorrelationMean, groupCorrelationSEM, miceType, "Median of sliding window" , {signalTitle, "Median of sliding window - all", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, true, shuffledCorrelationMean, shuffledCorrelationSEM)
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Sliding of all mice groups - " + signalTitle)

        end
        
        function plotCorrVsSliding(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceCorrelation = zeros(1, amoutOfMiceInGroup);
                shuffledCorrelation = zeros(1, amoutOfMiceInGroup);
                
                miceSliding = zeros(1, amoutOfMiceInGroup);
                shuffledSliding = zeros(1, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    % Correlation
                    mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                    miceCorrelation(1, mouseIndx) = mouseCorrelation;
                    
                    curShuffleCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, true);
                    shuffledCorrelation(1, mouseIndx) = curShuffleCorrelation;
                    
                    % Sliding
                    [mouseSliding, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                    miceSliding(1, mouseIndx) = mouseSliding;
                    
                    [curShuffledSliding, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, true);
                    shuffledSliding(1, mouseIndx) = curShuffledSliding;
                end
                xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["Correlation of " + group.Type, "Sliding Correlation (median) of " + group.Type];
                
                obj.drawTwoBubble(miceCorrelation, shuffledCorrelation, miceSliding, shuffledSliding, xAxe, ax, true)
            end
            
            % Titles
            legend(ax, 'Mice Mean', 'Shuffled', 'Individuals', 'Location', 'best')
            
            title(ax, {"Correlation Vs. Sliding Correlation", signalTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Correlation / Median of sliding correlation")
            
%             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        function plotSlidingCorrelationTaskByOutcomeBuble(obj, straightenedBy, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            
            % Create ax for each outcome     
            amountOfOutcomes = size(Mouse.CONST_TASK_OUTCOMES, 2);
            axByOutcome = [];
            
            fig = figure('Position', [108,113,1670,762]);
            for outcomeIndx = 1:amountOfOutcomes + 2
                ax = subplot(1, amountOfOutcomes + 2, outcomeIndx);
                axByOutcome = [axByOutcome, ax];
            end
            
            % Init
            AmountOfGroups = 2;
            labels = strings(AmountOfGroups);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceSliding = zeros(amountOfOutcomes + 2, amoutOfMiceInGroup);
                
                % Get Data
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    % data for outcomes
                    [~, ~, ~, ~, ~, ~, ~, outcomesMeanSliding, ~, overallSlidingMeanInTimePeriod, signalTitle]  = mouse.dataForPlotSlidingCorrelationTaskByOutcome(straightenedBy, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    miceSliding(1:amountOfOutcomes, mouseIndx) = median(outcomesMeanSliding, 2);
                    
                    % data for overall sliding correlation - first is
                    % overall forchosen time period, then for -5 to 15 sec
                    % of trial
                    miceSliding(amountOfOutcomes + 1, mouseIndx) = median(overallSlidingMeanInTimePeriod, 2);
                    
                    slidingMeanInTimePeriod = mouse.getSlidingCorrelationForTimeWindowInTask(["Task", straightenedBy], -5, 15, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    miceSliding(amountOfOutcomes + 2, mouseIndx) = median(slidingMeanInTimePeriod, 2);
                end
                
                labels(1, groupIndx) = group.Type;
                
                % Plot all mice in group in all different outcome figures
                for outcomeIndx = 1:amountOfOutcomes + 2
                    obj.drawBubbleByGroup(miceSliding(outcomeIndx,:), groupIndx, axByOutcome(outcomeIndx), true)
                end
            end
            
            % Add Titles
            legend(axByOutcome(amountOfOutcomes + 2), 'Mice Mean', 'Individuals', 'Location', 'best')
            yMaxes = zeros(1, amountOfOutcomes + 2);
            
            % Titles for outcomes
            for outcomeIndx = 1:amountOfOutcomes
                ax = axByOutcome(outcomeIndx);
                outcome = Mouse.CONST_TASK_OUTCOMES(outcomeIndx);
                
                title(ax, "Sliding Correlation for " + outcome)
                xlim(ax, [0.75, AmountOfGroups + 0.25])
                ax.XTick = [1: AmountOfGroups];
                ax.XTickLabel = labels';
                ylabel(ax, "Median of sliding")
                
                yl = ylim(ax);
                yMaxes(outcomeIndx) = yl(2);
            end
            
            % Titles for overall sliding first is overall for chosen time
            % period, then for -5 to 15 sec of trial
            ax = axByOutcome(amountOfOutcomes + 1);
            
            title(ax, "Overall Sliding Correlation for all the chosen time")
            xlim(ax, [0.75, AmountOfGroups + 0.25])
            ax.XTick = [1: AmountOfGroups];
            ax.XTickLabel = labels';
            ylabel(ax, "Median of sliding")
            
            yl = ylim(ax);
            yMaxes(amountOfOutcomes + 1) = yl(2);
            
            % Second overall
            ax = axByOutcome(amountOfOutcomes + 2);
            
            title(ax, "Overall Sliding Correlation for all trial")
            xlim(ax, [0.75, AmountOfGroups + 0.25])
            ax.XTick = [1: AmountOfGroups];
            ax.XTickLabel = labels';
            ylabel(ax, "Median of sliding")
            
            yl = ylim(ax);
            yMaxes(amountOfOutcomes + 2) = yl(2);
            
            sgtitle(fig, {"Sliding in task between " + startTime + " and " + endTime, signalTitle, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            
            % Set axe limit
            yMax = max(yMaxes);
            
            for outcomeIndx = 1:amountOfOutcomes + 2
                ax = axByOutcome(outcomeIndx);
                ylim(ax, [0, yMax])
            end
            
             savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Outcome\by " + straightenedBy + "\" + "All Groups - from " + string(startTime) + " to " + string(endTime) + " - " + string(timeWindow) + " sec")
            
        end
    end
    
    methods (Static)
        
        function drawBubleByMouse(data, groupMean, xLabels, yLabel, figureTitle, smoothFactor, downsampleFactor)
            figure("position", [551,339,806,558]);
            ax = axes;
            
            xAx = [1:size(data, 1)];
            for row = 1:size(data, 1)
                mice = data(row);
                mice = mice{:};
                
                currAx = zeros(size(mice, 2), 1);
                currAx(:) = row;
                
                plot(ax, currAx, mice, 'o', 'color', 'none', 'MarkerEdgeColor', '#C0C0C0', 'LineWidth', 1)
                hold on
            end
            
            plot(ax, xAx, groupMean, 'x', 'color', 'none', 'MarkerSize' , 8, 'MarkerEdgeColor', 'blue', 'MarkerFaceColor', 'black', 'LineWidth', 2)
            
            hold off
            
            xlim(ax, [0.5, size(data, 1) + 0.5])
            ax.XTick = xAx;
            ax.XTickLabel = xLabels;
            
            title(ax, [figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor, "Error bar is SEM"], 'FontSize', 12)
            ylabel(ax, yLabel + "\fontsize{8} (mean of all mice)")
        end
        
        function drawBubleAllMice(data, error, xLabels, yLabel, figureTitle, smoothFactor, downsampleFactor, shouldAddRandom, randomData, randomError)
            figure("position", [551,339,806,558]);
            ax = axes;
            
            xAx = [1:size(xLabels, 2)];
            errorbar(ax, xAx, data, error,'o', 'LineWidth', 1, 'color', 'blue', 'MarkerFaceColor', 'blue', 'MarkerSize',7)
            
            if shouldAddRandom
                hold on
                errorbar(ax, xAx, randomData, randomError,'o', 'LineWidth', 1, 'color', '#C0C0C0', 'MarkerFaceColor', '#C0C0C0', 'MarkerSize',7)
                hold off
                legend('Mice', 'Shuffled', 'Location', 'best')
            end
            
            xlim(ax, [0.5, size(xLabels, 2) + 0.5])
            ax.XTick = xAx;
            ax.XTickLabel = xLabels;
            
            title(ax, [figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor, "Error bar is SEM"], 'FontSize', 12)
            ylabel(ax, yLabel + "\fontsize{8} (mean of all mice)")
        end
        
        function drawTwoBubble(first, firstShuffled, second, secondShuffled, xAxe, ax, plotIndividuals)
            
            % Calcl Mean
            firstMean = mean(first);
            firstRandomMean = mean(firstShuffled);
            secondMean = mean(second);
            secondRandomMean = mean(secondShuffled);
            
            % Calc SEM
            firstRandomSEM = std(firstShuffled)/sqrt(length(firstShuffled));
            secondRandomSEM =  std(secondShuffled)/sqrt(length(secondShuffled));
            
            % Plot
             plot(ax, xAxe, [firstMean, secondMean], 'd', 'LineWidth', 1, 'color', '#800080', 'MarkerFaceColor', '#800080', 'MarkerSize', 8)
            hold on
            errorbar(ax, xAxe, [firstRandomMean, secondRandomMean], [firstRandomSEM, secondRandomSEM],'o', 'LineWidth', 1, 'color', '#C0C0C0', 'MarkerFaceColor', '#C0C0C0', 'MarkerSize', 6, 'CapSize', 12)
            if plotIndividuals
                for idx = 1:size(first, 2)
                    plot(ax, xAxe, [first(idx), second(idx)], 'o-', 'color', 'black', 'MarkerFaceColor', 'black', 'MarkerSize', 4)
                    hold on
                end
            end
        end
        
        function drawBubbleByGroup(valueList, xAxe, ax, plotIndividuals)
            
            % Calcl Mean
            valuesMean = mean(valueList);
            
            % Calc SEM
%             valuesSEM = std(valueList)/sqrt(length(valueList));
            
            % Plot
            plot(ax, xAxe, valuesMean, 'o', 'LineWidth', 2, 'LineStyle', 'none', 'color', '#800080', 'MarkerFaceColor', '#800080')
            hold(ax, 'on')
            if plotIndividuals
                for idx = 1:size(valueList, 2)
                    plot(ax, xAxe, valueList(idx), 'o', 'color', 'black', 'MarkerEdgeColor', '#C0C0C0')
                    hold(ax, 'on')
                end
            end
        end
    end
end