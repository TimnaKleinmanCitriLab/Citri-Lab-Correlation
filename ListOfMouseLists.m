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
        
    end
end