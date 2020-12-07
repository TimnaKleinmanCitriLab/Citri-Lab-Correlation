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
        
        function plotSlidingCorrelationBar(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            firstList = obj.ListOfLists(1);
            mouse = firstList.LoadedMouseList(1);
            [~, ~, ~, ~, signalTitle] = mouse.getRawSignals(descriptionVector);
            
            % data
            miceSlidingMean = [];
            miceSlidingSEM = [];
            miceType = [];
            
            shuffledSlidingMean = [];
            shuffledSlidingSEM = [];
            
            for mouseList = obj.ListOfLists
                mice = [];
                shuffled = [];
                for mouse = mouseList.LoadedMouseList
                    [mouseMedian, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                    mice = [mice, mouseMedian];
                    
                    [shuffledMedian, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, true);
                    shuffled = [shuffled, shuffledMedian];
                end
                miceSlidingMean = [miceSlidingMean, mean(mice)];
                miceSlidingSEM = [miceSlidingSEM, std(mice)/sqrt(length(mice))];
                miceType = [miceType, mouseList.Type];
                
                shuffledSlidingMean = [shuffledSlidingMean, mean(shuffled)];
                shuffledSlidingSEM = [shuffledSlidingSEM, std(shuffled)/sqrt(length(shuffled))];
            end
            
            % plot
            obj.plotBuble(miceSlidingMean, miceSlidingSEM, miceType, "Median of sliding window" , {signalTitle, "Median of sliding window", "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift)}, smoothFactor, downsampleFactor, true, shuffledSlidingMean, shuffledSlidingSEM)
            savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Window Bars\Sliding of all Mice groups - " + signalTitle)
        end
    end
    
    methods (Static)
        
        function plotBuble(data, error, xLabels, yLabel, figureTitle, smoothFactor, downsampleFactor, shouldAddRandom, randomData, randomError)
            figure("position", [551,339,806,558]);
            ax = axes;
            
            xAx = [1:size(xLabels, 2)];
            errorbar(ax, xAx, data, error,'o', 'LineWidth', 1, 'color', 'blue', 'MarkerFaceColor', 'blue', 'MarkerSize',7)
            
            if shouldAddRandom
                hold on
                errorbar(ax, xAx, randomData, randomError,'o', 'LineWidth', 1, 'color', '#C0C0C0', 'MarkerFaceColor', '#C0C0C0', 'MarkerSize',7)
                hold off
                legend('Mice', 'Random')
            end
            
            xlim(ax, [0.5, size(xLabels, 2) + 0.5])
            ax.XTick = xAx;
            ax.XTickLabel = xLabels;
            
            title(ax, [figureTitle, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor, "Error bar is SEM"], 'FontSize', 12)
            ylabel(ax, yLabel + "\fontsize{8} (mean of all mice)")
        end
        
        function drawBubleBar(obj, miceData, miceNames, yLabel, figureTitle, smoothFactor, downsampleFactor, oneToMinusOne)
            fig = figure();
            ax = axes;
            
            xAxe = [1];
            
            
        end
    end
end