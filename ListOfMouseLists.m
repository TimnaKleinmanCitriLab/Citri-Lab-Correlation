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
            
            obj.OfcAcc = load(Mouse.SHARED_FILE_LOCATION + "\shared\Timna\Gal Projects\Mouse Lists\OfcAccMice.mat").obj;
            obj.AudInAccOut = load(Mouse.SHARED_FILE_LOCATION + "\shared\Timna\Gal Projects\Mouse Lists\AudInAccOutMice.mat").obj;
            obj.AccInAccOut = load(Mouse.SHARED_FILE_LOCATION + "\shared\Timna\Gal Projects\Mouse Lists\AccInAccOutMice.mat").obj;
            obj.AudInAudOut = load(Mouse.SHARED_FILE_LOCATION + "\shared\Timna\Gal Projects\Mouse Lists\AudInAudOutMice.mat").obj;
            obj.AudAcc = load(Mouse.SHARED_FILE_LOCATION + "\shared\Timna\Gal Projects\Mouse Lists\AudAccMice.mat").obj;
            
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
        
        % Comparison Correlations
        function plotCorrVsSliding(obj, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the correlation VS sliding correlation for each group - Shows the single mice as well
            % For the shuffel - it takes Mouse.TIMES_TO_SHUFFLE shuffles
            % for each mouse, then looks at how many are higher then the
            % given correlation and at last chooses for each mouse it's
            % maximum correlation and takes the mean over all max mice.
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(descriptionVector);
            obj.plotFirstVsSecondCorrelationHelper(descriptionVector, descriptionVector, "correlation", "sliding", ["Correlation of ", "Sliding Correlation (median) of "], {"Correlation Vs. Sliding Correlation", signalTitle}, timeWindow, timeShift, smoothFactor, downsampleFactor)
        end
        
        function plotFreeVsTask(obj, correlationType, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots the Free VS Task correlation of correlatoin type, for each group - Shows the single mice as well
            % For the shuffel - it takes Mouse.TIMES_TO_SHUFFLE shuffles
            % for each mouse, then looks at how many are higher then the
            % given correlation and at last chooses for each mouse it's
            % maximum correlation and takes the mean over all max mice.
            
            obj.plotFirstVsSecondCorrelationHelper(["Free", "concat", "post"], ["Task", "onset"], correlationType, correlationType, [correlationType + " of Free post ", correlationType + " of Task "], {"Free Vs. Task - " + correlationType}, timeWindow, timeShift, smoothFactor, downsampleFactor)
        end
        
        function plotFirstVsSecondCorrelationHelper(obj, descriptionVectorFirst, descriptionVectorSecond, correlationTypeFirst, correlationTypeSecond, labelsBeg, plotTitle, timeWindow, timeShift, smoothFactor, downsampleFactor)
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            maxShuffledOverMeanPerGroup = zeros(AmountOfGroups, 2);
            
            % [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceFirst = zeros(1, amoutOfMiceInGroup);
                shuffledFirst = zeros(Mouse.TIMES_TO_SHUFFLE, amoutOfMiceInGroup);
                
                miceSecond = zeros(1, amoutOfMiceInGroup);
                shuffledSecond = zeros(Mouse.TIMES_TO_SHUFFLE, amoutOfMiceInGroup);
                
                ratioShuffledOverMeanPerMouse = zeros(amoutOfMiceInGroup, 2); % First col is free second is Task
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    [mouseFirst, mouseShuffFirstVec] = obj.runMouseCorrelationByCorrelationType(mouse, correlationTypeFirst, descriptionVectorFirst, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    [mouseSecond, mouseShuffSecondVec] = obj.runMouseCorrelationByCorrelationType(mouse, correlationTypeSecond, descriptionVectorSecond, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    
                    ratioShuffledOverMeanPerMouse(mouseIndx, 1) = sum((mouseFirst > 0 & mouseShuffFirstVec > mouseFirst) | (mouseFirst < 0 & mouseShuffFirstVec < mouseFirst), 'all') / Mouse.TIMES_TO_SHUFFLE;
                    ratioShuffledOverMeanPerMouse(mouseIndx, 2) = sum((mouseSecond > 0 & mouseShuffSecondVec > mouseSecond) | (mouseSecond < 0 & mouseShuffSecondVec < mouseSecond), 'all') / Mouse.TIMES_TO_SHUFFLE;
                    
                    miceFirst(1, mouseIndx) = mouseFirst;
                    shuffledFirst(:, mouseIndx) = mouseShuffFirstVec;
                    miceSecond(1, mouseIndx) = mouseSecond;
                    shuffledSecond(:, mouseIndx) = mouseShuffSecondVec;
                    
                end
                xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = [labelsBeg(1) + group.Type, labelsBeg(2) + group.Type];
                
                [individualPlot, medianPlot, randomPlot] = obj.drawTwoBubble(miceFirst, shuffledFirst, miceSecond, shuffledSecond, xAxe, ax, true, true);
                
                maxShuffledOverMeanPerGroup(groupIndx, :) = max(ratioShuffledOverMeanPerMouse, [], 1);
                
            end
            
            % Titles
            legend(ax, [individualPlot, medianPlot, randomPlot], 'Individuals', 'Mice Mean', 'Shuffled', 'Location', 'best')
            
            title(ax, {plotTitle{:}, strcat("Max Ratio of shuffled over mean (respectively): " , strjoin(string(maxShuffledOverMeanPerGroup')), " within " + Mouse.TIMES_TO_SHUFFLE + " shuffles for each mouse"), "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Correlation / Median of sliding correlation")
        end
        
        function plotSlidingMovementFreeVsTask(obj, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                movementSlidingFree = zeros(1, amoutOfMiceInGroup);
                movementSlidingTask = zeros(1, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    % Sliding Correlation Free Movement
                    [~, movementFreeSliding] = mouse.getSlidingCorrelationWithAndWithout("Free", "movement", "", ["Free", "concat", "post"], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    medianFreeSliding = median(movementFreeSliding);
                    movementSlidingFree(1, mouseIndx) = medianFreeSliding;
                    
                    % Sliding Correlation Task Movement
                    [~, movementTaskSliding] = mouse.getSlidingCorrelationWithAndWithout("Task", "movement", "isnan(tInfo.first_lick)", [], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    medianTaskSliding = median(movementTaskSliding);
                    movementSlidingTask(1, mouseIndx) = medianTaskSliding;
                end
                xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["Free Movement Sliding of " + group.Type + "\fontsize{7} (median)", "Task Movement Sliding of " + group.Type + "\fontsize{7} (median)"];
                
                [individualPlot, medianPlot, ~] = obj.drawTwoBubble(movementSlidingFree, [], movementSlidingTask, [], xAxe, ax, true, false);
            end
            
            % Titles
            legend(ax, [individualPlot, medianPlot], 'Individuals', 'Mice Mean', 'Location', 'best')
            
            title(ax, {"Sliding Correlation Movement in Free Vs Task (no lick trials only)", signalTitle, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Median of sliding correlation")
            
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        function plotCorrMovementFreeVsTask(obj, timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor)
            % Plots the average correlation of each mouse and the meanof
            % all mice by group - once the movement inTas
            
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                movementCorrFree = zeros(1, amoutOfMiceInGroup);
                movementCorrTask = zeros(1, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    % Sliding Correlation Free Movement
                    [~, movementFreeCorrelation] = mouse.getCorrelationWithAndWithout("Free", "movement", "", ["Free", "concat", "post"], timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor);
                    meanFreeSliding = mean(movementFreeCorrelation);
                    movementCorrFree(1, mouseIndx) = meanFreeSliding;
                    
                    % Sliding Correlation Task Movement
                    [~, movementTaskSliding] = mouse.getCorrelationWithAndWithout("Task", "movement", "isnan(tInfo.first_lick)", [], timeToRemoveBefore, timeToRemoveAfter, smoothFactor, downsampleFactor);
                    meanTaskSliding = mean(movementTaskSliding);
                    movementCorrTask(1, mouseIndx) = meanTaskSliding;
                end
                xAxe = [groupIndx * 2 - 1, groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["Free Movement Corr of " + group.Type + "\fontsize{7} (mean)", "Task Movement Corr of " + group.Type + "\fontsize{7} (mean)"];
                
                [individualPlot, avrPlot, ~] = obj.drawTwoBubble(movementCorrFree, [], movementCorrTask, [], xAxe, ax, true, false);
            end
            
            % Titles
            legend(ax, [individualPlot, avrPlot], 'Individuals', 'Mice Mean', 'Location', 'best')
            
            title(ax, {"Correlation Movement in Free Vs Task (no lick trials only)", signalTitle, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Mean of correlation")
            
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        % Comaprison Events
        function plotSlidingBubbleWithAndWithoutLickTask(obj, condition, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceNoLickSliding = zeros(1, amoutOfMiceInGroup);
                miceLickSliding = zeros(1, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    [noLickCorrelationVector, lickCorrelationVector] = mouse.getSlidingCorrelationWithAndWithout("Task", "Lick", condition, [], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    
                    % Sliding Correlation Lick Removed
                    medianNoLickSliding = median(noLickCorrelationVector);
                    miceNoLickSliding(1, mouseIndx) = medianNoLickSliding;
                    
                    % Sliding Correlation Only Lick
                    medianLickSliding = median(lickCorrelationVector);
                    miceLickSliding(1, mouseIndx) = medianLickSliding;
                end
                xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["No Lick Sliding of " + group.Type + "\fontsize{7}(median)", "Lick Sliding of " + group.Type + "\fontsize{7}(median)"];

                [individualPlot, medianPlot, ~] = obj.drawTwoBubble(miceNoLickSliding, [], miceLickSliding, [], xAxe, ax, true, false);
                
            end
            
            % Titles
            f = get(gca,'Children');
            legend(ax, [individualPlot, medianPlot], 'Mice Mean', 'Individuals', 'Location', 'best')
            
            title(ax, {"Sliding Correlation With and Without Lick", signalTitle, "Filtered by - " + condition, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Median of sliding correlation")
            
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        function plotSlidingBubbleWithAndWithoutMovementTask(obj, condition, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceNoMovementSliding = zeros(1, amoutOfMiceInGroup);
                miceMovementSliding = zeros(1, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    [noMovementCorrelationVector, movementCorrelationVector] = mouse.getSlidingCorrelationWithAndWithout("Task", "movement", condition, [], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    
                    % Sliding Correlation Lick Removed
                    medianNoMovementSliding = median(noMovementCorrelationVector);
                    miceNoMovementSliding(1, mouseIndx) = medianNoMovementSliding;
                    
                    % Sliding Correlation Only Lick
                    medianMovementSliding = median(movementCorrelationVector);
                    miceMovementSliding(1, mouseIndx) = medianMovementSliding;
                end
                xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["No Movement Sliding of " + group.Type + "\fontsize{7}(median)", "Movement Sliding of " + group.Type + "\fontsize{7}(median)"];
                
                [individualPlot, medianPlot, ~] = obj.drawTwoBubble(miceNoMovementSliding, [], miceMovementSliding, [], xAxe, ax, true, false);
            end
            
            % Titles
            legend(ax, [individualPlot, medianPlot],'Individuals', 'Mice Mean', 'Location', 'best', 'Location', 'best')
            
            title(ax, {"Sliding Correlation With and Without Movement", signalTitle, "Filtered by - " + condition, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Median of sliding correlation")
            
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        function plotSlidingBubbleWithAndWithoutMovementFree(obj, descriptionVector, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceNoMovementSliding = zeros(1, amoutOfMiceInGroup);
                miceMovementSliding = zeros(1, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    [noMovementCorrelationVector, movementCorrelationVector] = mouse.getSlidingCorrelationWithAndWithout("Free", "movement", "", descriptionVector, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    
                    medianNoMovementSliding = median(noMovementCorrelationVector);
                    miceNoMovementSliding(1, mouseIndx) = medianNoMovementSliding;
                    
                    medianMovementSliding = median(movementCorrelationVector);
                    miceMovementSliding(1, mouseIndx) = medianMovementSliding;
                end
                xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["No Movement Sliding of " + group.Type + "\fontsize{7}(median)", "Movement Sliding of " + group.Type + "\fontsize{7}(median)"];
                
                [individualPlot, medianPlot, ~] = obj.drawTwoBubble(miceNoMovementSliding, [], miceMovementSliding, [], xAxe, ax, true, false);
            end
            
            % Titles
            legend(ax, [individualPlot, medianPlot], 'Individuals', 'Mice Mean', 'Location', 'best')
            
            title(ax, {"Sliding Correlation With and Without Movement", signalTitle, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Median of sliding correlation")
            
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        function plotSlidingBubbleWithAndWithoutPassiveOnset(obj, descriptionVector, condition, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Description Vector has to be Passive
            
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(2 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(descriptionVector);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceNoOnsetSliding = [];
                miceOnsetSliding = [];
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    if mouse.signalExists(descriptionVector)
                        [noOnsetCorrelationVector, onsetCorrelationVector] = mouse.getSlidingCorrelationWithAndWithout("Passive", "onset", condition, descriptionVector, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                        
                        % Sliding Correlation Onset Removed
                        medianNoOnsetSliding = median(noOnsetCorrelationVector);
                        miceNoOnsetSliding = [miceNoOnsetSliding, medianNoOnsetSliding];
                        
                        % Sliding Correlation Only Onset
                        medianOnsetSliding = median(onsetCorrelationVector);
                        miceOnsetSliding = [miceOnsetSliding, medianOnsetSliding];
                    end
                end
                xAxe = [groupIndx * 2 - 1 , groupIndx * 2];
                labels(1, groupIndx * 2 - 1:groupIndx * 2) = ["Not Onset, Sliding of " + group.Type + "\fontsize{7}(median)", "Onset, Sliding of " + group.Type + "\fontsize{7}(median)"];
                
                [individualPlot, medianPlot, ~] = obj.drawTwoBubble(miceNoOnsetSliding, [], miceOnsetSliding, [], xAxe, ax, true, false);
            end
            
            % Titles
            legend(ax, [individualPlot, medianPlot], 'Individuals', 'Mice Mean', 'Location', 'best')
            
            title(ax, {"Sliding Correlation With and Without Onset", signalTitle, "Filtered by - " + condition, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 2 + 0.25])
            ax.XTick = [1: AmountOfGroups * 2];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Median of sliding correlation")
            
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        % Other
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
                    [~, ~, ~, ~, ~, overallSlidingMeanInTimePeriod, signalTitle]  = mouse.dataForPlotSlidingCorrelation(["Task", straightenedBy], '', startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    [~, ~, ~, ~, ~, ~, ~, outcomesMeanSliding, ~, ~]  = mouse.dataForPlotSlidingCorrelationTaskByOutcome(straightenedBy, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    
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
            
             % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Outcome\by " + straightenedBy + "\" + "All Groups - from " + string(startTime) + " to " + string(endTime) + " - " + string(timeWindow) + " sec")
            
        end
        
        function plotSlidingCorrelationCutSignal(obj, descriptionVector, condition, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots sliding correaltion in cut task for all mice by group +
            % Max of the mice 1 sec before and after time 0 (of 
            % "straightenedBy")
            
            % Create figures
            amountOfGroups = 3;                                            % Depending what groups one wants to include
            byMouse = figure('Position', [450,109,961,860]);
            allMice = figure('Position', [450,109,961,860]);
            maxCorr = figure('Position', [450,109,961,860]);
            
            switch descriptionVector(1)
                case "Task"
                    [startTime, endTime] = Mouse.CONST_TASK_TRIAL_LIMS{:};
                case "Passive"
                    [startTime, endTime] = Mouse.CONST_PASSIVE_TRIAL_LIMS{:};
                case "Free"
                    [startTime, endTime] = Mouse.CONST_FREE_TRIAL_LIMS{:};
            end
            
            % Data + Plot
            for groupIndx = 1:amountOfGroups
                group = obj.ListOfLists(groupIndx);
                
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                % miceNames = strings(1,amoutOfMiceInGroup);
                miceNames = [];
                % miceMax = zeros(1, amoutOfMiceInGroup);
                miceMax = [];
                
                % By mouse
                set(0,'CurrentFigure',byMouse)
                slidingByMouseAx = subplot(amountOfGroups, 1, groupIndx);
                
                set(0,'CurrentFigure',maxCorr)
                maxByMouseAx = subplot(1, amountOfGroups, groupIndx);
                
                groupMiceSliding = [];
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    if mouse.signalExists(descriptionVector)
                        miceNames = [miceNames; mouse.Name];
                        
                        [~, ~, ~, slidingTimeVector, ~, slidingMeanInTimePeriod, signalTitle]  = mouse.dataForPlotSlidingCorrelation(descriptionVector, condition, startTime, endTime, timeWindow, timeShift, smoothFactor, downsampleFactor);
                        
                        groupMiceSliding = [groupMiceSliding; slidingMeanInTimePeriod];
                        
                        plot(slidingByMouseAx, slidingTimeVector, slidingMeanInTimePeriod)
                        hold(slidingByMouseAx, 'on')
                        
                        maxSlidingNearZeroStartIndex = find(slidingTimeVector >= 0 & slidingTimeVector <= 0.1); % find(slidingTimeVector > -1.1 & slidingTimeVector < -0.99); If want to start at 1 sec
                        maxSlidingNearZeroEndIndex = find(slidingTimeVector > 0.99 & slidingTimeVector < 1.1);
                        maxCloseToZero = max(slidingMeanInTimePeriod(maxSlidingNearZeroStartIndex:maxSlidingNearZeroEndIndex));
                        miceMax = [miceMax; maxCloseToZero];
                        plot(maxByMouseAx, [0], [maxCloseToZero], 'o')
                        hold(maxByMouseAx, 'on')
                    end
                end
                
                line(slidingByMouseAx, [startTime, endTime], [0 0], 'Color', '#C0C0C0')
                line(slidingByMouseAx, [0, 0], ylim(slidingByMouseAx), 'Color', '#C0C0C0')
                legend(slidingByMouseAx, miceNames, 'Location', 'best')
                title(slidingByMouseAx, "Sliding Correlation for " + group.Type)
                hold(slidingByMouseAx, 'off')
                
                plot(maxByMouseAx, [0], [mean(miceMax)], '*')
                legend(maxByMouseAx, [miceNames; "mice mean"], 'Location', 'best')
                title(maxByMouseAx, "Max sliding for " + group.Type)
                hold(maxByMouseAx, 'off')
                
                % All mice
                set(0,'CurrentFigure',allMice)
                allMouseAx = subplot(amountOfGroups, 1, groupIndx);
                meanSlidingAllMice = mean(groupMiceSliding, 1);
                SEMSlidingAllMice = std(groupMiceSliding, 1)/sqrt(size(groupMiceSliding, 1));
                if size(groupMiceSliding, 1) == 1
                    SEMSlidingAllMice = zeros(1, size(groupMiceSliding, 2));
                end
                
                shadedErrorBar(slidingTimeVector, meanSlidingAllMice, SEMSlidingAllMice, 'lineProps', 'b');
                
                line(allMouseAx, [startTime, endTime], [0 0], 'Color', '#C0C0C0')
                line(allMouseAx, [0, 0], ylim(slidingByMouseAx), 'Color', '#C0C0C0')
                title(allMouseAx, "Mean Sliding Correlation for " + group.Type)
                
            end
            
            sgtitle(byMouse, {"Sliding in cut signal - by mouse", signalTitle, "Filtered by - " + condition, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            set(0,'CurrentFigure',byMouse)
            savedName = strrep(strrep(strrep("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Cut Signal - " + strjoin(descriptionVector, ' - ') + "\By mouse - filtered by - " + condition + " - time window of " + timeWindow, '<' ,' lt '), '>', ' ht '), '.', ',');
            % savefig(byMouse, savedName)
            
            sgtitle(allMice, {"Sliding in cut signal - all mice", signalTitle, "Filtered by - " + condition, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            set(0,'CurrentFigure',allMice)
            savedName = strrep(strrep(strrep("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Cut Signal - " + strjoin(descriptionVector, ' - ') + "\All mice - filtered by - " + condition + " - time window of " + string(timeWindow), '<' ,' lt '), '>', ' ht '), '.', ',');
            % savefig(allMice, savedName)
            
            sgtitle(maxCorr, {"Sliding max in cut signal - all mice - between 0 and 1 sec", signalTitle, "Filtered by - " + condition, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            set(0,'CurrentFigure',maxCorr)
            savedName = strrep(strrep(strrep("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Cut Signal - " + strjoin(descriptionVector, ' - ') + "\Max - filtered by - " + condition + " - time window of " + string(timeWindow), '<' ,' lt '), '>', ' ht '), '.', ',');
            % savefig(maxCorr, savedName)
        end
        
        function plotSlidingCorrelationPassiveByAttenuation(obj, straightenedBy, timeWindow, timeShift, smoothFactor, downsampleFactor)
            % Plots sliding correaltion of passive by attenuations +
            % general - for all mice by group + Max of the mice 1 sec before and
            % after time 0 (of "straightenedBy")
            
            % Create figures
            amountOfGroups = 3;                                            % Depending what groups one wants to include
            byMouse = figure('Position', [450,109,961,860]);
            allMice = figure('Position', [450,109,961,860]);
            maxCorr = figure('Position', [450,109,961,860]); 
            
            % Data + Plot
            for groupIndx = 1:amountOfGroups
                group = obj.ListOfLists(groupIndx);
                
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                miceNames = strings(1,amoutOfMiceInGroup);
                
                miceMax = zeros(1, amoutOfMiceInGroup);
                
                % By mouse
                set(0,'CurrentFigure',byMouse)
                byMouseAx = subplot(amountOfGroups, 1, groupIndx);
                
                set(0,'CurrentFigure',maxCorr)
                maxByMouseAx = subplot(1, amountOfGroups, groupIndx);
                
                groupMiceSliding = [];
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    miceNames(mouseIndx) = mouse.Name;
                    
                    [~, ~, ~, slidingTimeVector, slidingMeanInTimePeriod, signalTitle]  = mouse.dataForPlotSlidingCorrelationTaskNoLick(straightenedBy, -5, 15, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    
                    groupMiceSliding = [groupMiceSliding; slidingMeanInTimePeriod];
                    
                    plot(byMouseAx, slidingTimeVector, slidingMeanInTimePeriod)
                    hold(byMouseAx, 'on')
                    
                    maxSlidingNearZeroStartIndex = find(slidingTimeVector >= 0 & slidingTimeVector <= 0.1); % find(slidingTimeVector > -1.1 & slidingTimeVector < -0.99); If want to start at 1 sec
                    maxSlidingNearZeroEndIndex = find(slidingTimeVector > 0.99 & slidingTimeVector < 1.1);
                    miceMax(mouseIndx) = max(slidingMeanInTimePeriod(maxSlidingNearZeroStartIndex:maxSlidingNearZeroEndIndex));
                    plot(maxByMouseAx, [0], [miceMax(mouseIndx)], 'o')
                    hold(maxByMouseAx, 'on')
                end
                
                line(byMouseAx, [-5, 15], [0 0], 'Color', '#C0C0C0')
                line(byMouseAx, [0, 0], ylim(byMouseAx), 'Color', '#C0C0C0')
                legend(byMouseAx, miceNames)
                title(byMouseAx, "Sliding Correlation for " + group.Type)
                hold(byMouseAx, 'off')
                
                plot(maxByMouseAx, [0], [mean(miceMax)], '*')
                legend(maxByMouseAx, [miceNames, "mice mean"], 'Location', 'best')
                title(maxByMouseAx, "Max sliding for " + group.Type)
                hold(maxByMouseAx, 'off')
                
                % All mice
                set(0,'CurrentFigure',allMice)
                allMouseAx = subplot(amountOfGroups, 1, groupIndx);
                meanSlidingAllMice = mean(groupMiceSliding, 1);
                SEMSlidingAllMice = std(groupMiceSliding, 1)/sqrt(size(groupMiceSliding, 1));
                
                shadedErrorBar(slidingTimeVector, meanSlidingAllMice, SEMSlidingAllMice, 'b');
                
                line(allMouseAx, [-5, 15], [0 0], 'Color', '#C0C0C0')
                line(allMouseAx, [0, 0], ylim(byMouseAx), 'Color', '#C0C0C0')
                title(allMouseAx, "Mean Sliding Correlation for " + group.Type)
            end
            
            sgtitle(byMouse, {"Sliding in cut task with no lick by mouse", signalTitle, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            set(0,'CurrentFigure',byMouse)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Lick vs. No Lick\by " + straightenedBy + "\All Groups - no lick - by mouse")
            
            sgtitle(allMice, {"Sliding in cut task with no lick by mouse", signalTitle, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            set(0,'CurrentFigure',allMice)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Lick vs. No Lick\by " + straightenedBy + "\All Groups - no lick - all mice")
            
            sgtitle(maxCorr, {"Sliding max in cut task all mice", "between 0 and 1 sec", signalTitle, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            set(0,'CurrentFigure',maxCorr)
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding By Task - Lick vs. No Lick\by " + straightenedBy + "\All Groups - no lick - max")
            
        end
        
        function plotSlidingCorrelationHeatmapCutSignal(obj, descriptionVector, condition, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            % Init
            amountOfGroups = 3;                                            % Depending what groups one wants to include
            switch descriptionVector(1)
                case "Task"
                    [startTime, endTime] = Mouse.CONST_TASK_TRIAL_LIMS{:};
                case "Passive"
                    [startTime, endTime] = Mouse.CONST_PASSIVE_TRIAL_LIMS{:};
                case "Free"
                    [startTime, endTime] = Mouse.CONST_FREE_TRIAL_LIMS{:};
            end
            corrLimits = [startTime, endTime];
            
            
            % Create figures
            allMiceAllGroups = figure('Position', [256,109,1349,860]);
            
            % Collect data and plot
            for groupIndx = 1:amountOfGroups
                group = obj.ListOfLists(groupIndx);
                
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                % miceNames = strings(1,amoutOfMiceInGroup);
                miceNames = [];
                amountOfTrialsPerMouse = [];
                
                % By mouse
                groupByMouse = figure('Position', [247,579,1367,388]);
                groupMiceSliding = [];
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    set(0,'CurrentFigure',groupByMouse)
                    currentMouseSubplot = subplot(1, amoutOfMiceInGroup, mouseIndx);
                    
                    mouse = group.LoadedMouseList(mouseIndx);
                    if mouse.signalExists(descriptionVector)
                        miceNames = [miceNames; mouse.Name];
                        
                        [~, ~, ~, ~, slidingCorrMatrix, ~, signalTitle]  = mouse.dataForPlotSlidingCorrelation(descriptionVector, condition, corrLimits(1), corrLimits(2), timeWindow, timeShift, smoothFactor, downsampleFactor);
                        
                        % Save for all mice in group
                        groupMiceSliding = [groupMiceSliding; slidingCorrMatrix];
                        amountOfTrialsPerMouse = [amountOfTrialsPerMouse, size(slidingCorrMatrix, 1)];
                        
                        % Plot
                        im = imagesc(currentMouseSubplot, slidingCorrMatrix);
                        
                        title(currentMouseSubplot, "Heatmap of mouse " + mouse.Name, 'Interpreter', 'none')
                        im.XData = linspace(corrLimits(1), corrLimits(2), size(slidingCorrMatrix, 2));
                        xlim(currentMouseSubplot, corrLimits);
                        ylim(currentMouseSubplot, [0, size(slidingCorrMatrix, 1)]);
                        hold on
                        line(currentMouseSubplot, [0 0], [0 size(slidingCorrMatrix, 1)], 'Color', 'black')
                        hold off
                    end
                end
                
                % All mice
                set(0,'CurrentFigure', allMiceAllGroups)
                allMiceInGroupSubplot = subplot(1, amountOfGroups, groupIndx);
                
                % Plot
                im = imagesc(allMiceInGroupSubplot, groupMiceSliding);

                title(allMiceInGroupSubplot , group.Type, 'Interpreter', 'none')
                im.XData = linspace(corrLimits(1), corrLimits(2), size(groupMiceSliding, 2));
                xlim(allMiceInGroupSubplot, corrLimits);
                ylim(allMiceInGroupSubplot, [0, size(groupMiceSliding, 1)]);
                hold on
                line(allMiceInGroupSubplot, [0 0], [0 size(groupMiceSliding, 1)], 'Color', 'black')
                hold off
                
                % Add lines between mice
                currentTrialAmount = 0;
                
                for trialAmount = amountOfTrialsPerMouse
                    currentTrialAmount = currentTrialAmount + trialAmount;
                    line(allMiceInGroupSubplot, corrLimits, [currentTrialAmount, currentTrialAmount], 'Color', 'white')         
                end
                
                % Titles
                sgtitle(groupByMouse, {"Sliding heatmap for mice of group " + group.Type, signalTitle, "Filtered by - " + condition, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
                set(0,'CurrentFigure',groupByMouse)
                savedName = strrep(strrep(strrep("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Heatmap - " + strjoin(descriptionVector, ' - ') + "\" + group.Type + " - filtered by - " + condition + " - time window of " + string(timeWindow), '<' ,' lt '), '>', ' ht '), 'tInfo.', '');
                % savefig(groupByMouse, savedName)
                
            end
            
            sgtitle(allMiceAllGroups, {"Sliding heatmap for all groups", signalTitle, "Filtered by - " + condition, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            set(0,'CurrentFigure', allMiceAllGroups)
            savedName = strrep(strrep(strrep("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Sliding Heatmap - " + strjoin(descriptionVector, ' - ') + "\All Groups - filtered by - " + condition + " - time window of " + string(timeWindow), '<' ,' lt '), '>', ' ht '), 'tInfo.', '');
            % savefig(allMiceAllGroups, savedName)
        end
        
        function plotSignalAndSlidingCorrelationHeatpmapCutSignal(obj, descriptionVector, condition, timeWindow, timeShift, smoothFactor, downsampleFactor)           
            % Create figures
            amountOfGroups = 3;                                            % Depending what groups one wants to include
            
            switch descriptionVector(1)
                case "Task"
                    [startTime, endTime] = Mouse.CONST_TASK_TRIAL_LIMS{:};
                case "Passive"
                    [startTime, endTime] = Mouse.CONST_PASSIVE_TRIAL_LIMS{:};
                case "Free"
                    [startTime, endTime] = Mouse.CONST_FREE_TRIAL_LIMS{:};
            end
            corrLimits = [startTime, endTime];
            
            % Data + Plot
            for groupIndx = 1:amountOfGroups
                group = obj.ListOfLists(groupIndx);
                
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                groupMiceSliding = [];
                groupMiceGcamp = [];
                groupMiceGeco = [];
                amountOfTrialsPerMouse = [];                                       % Used to draw lines between mice
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    if mouse.signalExists(descriptionVector)
                        
                        [gcampSignal, jrgecoSignal, ~, ~] = mouse.dataOfCutSignal(descriptionVector, condition, smoothFactor, downsampleFactor);
                        
                        groupMiceGcamp = [groupMiceGcamp; gcampSignal];
                        groupMiceGeco = [groupMiceGeco; jrgecoSignal];
                        
                        
                        [~, ~, ~, ~, slidingCorrMatrix, ~, signalTitle]  = mouse.dataForPlotSlidingCorrelation(descriptionVector, condition, corrLimits(1), corrLimits(2), timeWindow, timeShift, smoothFactor, downsampleFactor);
                        groupMiceSliding = [groupMiceSliding; slidingCorrMatrix];
                        
                        amountOfTrialsPerMouse = [amountOfTrialsPerMouse, size(gcampSignal, 1)];
                    end
                end
                
                % Normalize signal to be between 0 and 1
                normalizedGroupMiceGcamp = groupMiceGcamp - min(groupMiceGcamp, [], 2);  % Bring all trials to 0
                normalizedGroupMiceGcamp = normalizedGroupMiceGcamp ./ max(normalizedGroupMiceGcamp, [], 2); % All trials between 0 and 1
                
                normalizedGroupMiceGeco = groupMiceGeco - min(groupMiceGeco, [], 2);  % Bring all trials to 0
                normalizedGroupMiceGeco = normalizedGroupMiceGeco ./ max(normalizedGroupMiceGeco, [], 2); % All trials between 0 and 1
                
                % Draw
                fig = figure('Position', [450,109,961,860]);
                    % Gcamp
                gcampSubplot = subplot(1, 3, 1);
                im = imagesc(gcampSubplot, normalizedGroupMiceGcamp);

                title(gcampSubplot , "Gcamp", 'Interpreter', 'none')
                im.XData = linspace(corrLimits(1), corrLimits(2), size(normalizedGroupMiceGcamp, 2));
                xlim(gcampSubplot, corrLimits);
                ylim(gcampSubplot, [0, size(normalizedGroupMiceGcamp, 1)]);
                line(gcampSubplot, [0 0], [0 size(normalizedGroupMiceGcamp, 1)], 'Color', 'black')
                
                    % Geco
                jrgecoSubplot = subplot(1, 3, 2);
                im = imagesc(jrgecoSubplot, normalizedGroupMiceGeco);

                title(jrgecoSubplot , "JrGeco", 'Interpreter', 'none')
                im.XData = linspace(corrLimits(1), corrLimits(2), size(normalizedGroupMiceGeco, 2));
                xlim(jrgecoSubplot, corrLimits);
                ylim(jrgecoSubplot, [0, size(normalizedGroupMiceGeco, 1)]);
                line(jrgecoSubplot, [0 0], [0 size(normalizedGroupMiceGeco, 1)], 'Color', 'black')
                
                    % Sliding
                slidingSubplot = subplot(1, 3, 3);
                im = imagesc(slidingSubplot, groupMiceSliding);

                title(slidingSubplot , "Sliding", 'Interpreter', 'none')
                im.XData = linspace(corrLimits(1), corrLimits(2), size(groupMiceSliding, 2));
                xlim(slidingSubplot, corrLimits);
                ylim(slidingSubplot, [0, size(groupMiceSliding, 1)]);
                line(slidingSubplot, [0 0], [0 size(groupMiceSliding, 1)], 'Color', 'black')
                
                currentTrialAmount = 0;
                for trialAmount = amountOfTrialsPerMouse
                    currentTrialAmount = currentTrialAmount + trialAmount;
                    
                    line(gcampSubplot, corrLimits, [currentTrialAmount, currentTrialAmount], 'Color', 'white')
                    line(jrgecoSubplot, corrLimits, [currentTrialAmount, currentTrialAmount], 'Color', 'white')
                    line(slidingSubplot, corrLimits, [currentTrialAmount, currentTrialAmount], 'Color', 'white')         
                end
                sgtitle(fig, {"Heatmap for mice of group " + group.Type, signalTitle, "Filtered by - " + condition, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            end
        end
        
        function plotSlidingCorrelationHistogramWithAndWithout(obj, recordingType, cutBy, condition, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            % Create figures
            amountOfGroups = 3;                                            % Depending what groups one wants to include
            byGroup = figure('Position', [110,226,1633,601]);
            xAxe = -0.99: 0.02: 0.99;
            allPlots = [];
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            % Data + Plot
            for groupIndx = 1:amountOfGroups
                group = obj.ListOfLists(groupIndx);
                
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                % miceNames = strings(1,amoutOfMiceInGroup);
                miceNames = [];
                
                curGroupSubplot = subplot(1, amountOfGroups, groupIndx);
                allPlots = [allPlots, curGroupSubplot];
                
                withoutCutBinByMouse = zeros(100, amoutOfMiceInGroup);
                withCutBinByMouse = zeros(100, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    if ((~(strcmp(recordingType, "Passive pre")) && ~(strcmp(recordingType, "Passive post")) && ~(strcmp(recordingType, "Free post"))) || (recordingType == "Passive pre"  && mouse.signalExists(["Passive", "awake", "BBN", "pre"])) || (recordingType == "Passive post"  && mouse.signalExists(["Passive", "awake", "BBN", "post"])) || (recordingType == "Free post"  && mouse.signalExists(["Free", "concat", "post"])))
                        miceNames = [miceNames; mouse.Name];
                        
                        [histogramMatrix, labels] = mouse.dataForPlotSlidingCorrelationHistogramWithAndWithout(recordingType, cutBy, condition, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                        
                        withoutCutBinByMouse(:, mouseIndx) = histogramMatrix(:, 1);
                        withCutBinByMouse(:, mouseIndx) = histogramMatrix(:, 2);
                    end
                end
                % Find mean of bins
                meanwithoutCutkBin = mean(withoutCutBinByMouse, 2);
                meanwithCutBin = mean(withCutBinByMouse, 2);
                
                plot(curGroupSubplot, xAxe, meanwithoutCutkBin, 'LineWidth', 1.5)
                hold on
                plot(curGroupSubplot, xAxe, meanwithCutBin, 'LineWidth', 1.5)
                hold off
                
                curGroupSubplot.XLabel.String = 'Correlation';
                curGroupSubplot.YLabel.String = 'Amount';
                legend(labels, 'Location', 'best')
                
                title(curGroupSubplot, group.Type)
            end
            
            yMax = 0;
            
            for subplotIndex = amountOfGroups
                curPlot = allPlots(subplotIndex);
                yl = ylim(curPlot);
                yMax = max(yMax, yl(2));
            end
            
            for subplotIndex = amountOfGroups
                curPlot = allPlots(subplotIndex);
                ylim(curPlot, [0, yMax])
            end
            
            sgtitle(byGroup, {"Sliding Window Histogram With VS Without " + cutBy, recordingType + " cut by " + cutBy, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            savedName = "";
            % savefig(byMouse, savedName)
        end
        
        function plotSlidingCorrelationDuringEventsVSBaseline(obj, timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor)
            AmountOfGroups = 3;
            
            fig = figure('Position', [450,109,961,860]);
            ax = axes;
            labels = strings(4 * AmountOfGroups);
            
            [~, ~, ~, ~, signalTitle] = obj.ListOfLists(1).LoadedMouseList(1).getRawSignals(["Task", "onset"]);
            
            for groupIndx = 1:AmountOfGroups
                group = obj.ListOfLists(groupIndx);
                amoutOfMiceInGroup = size(group.LoadedMouseList, 2);
                
                miceLickSliding = zeros(1, amoutOfMiceInGroup);
                miceMovementSliding = zeros(1, amoutOfMiceInGroup);
                miceCueSliding = zeros(1, amoutOfMiceInGroup);
                miceBaselineSliding = zeros(1, amoutOfMiceInGroup);
                
                for mouseIndx = 1:amoutOfMiceInGroup
                    mouse = group.LoadedMouseList(mouseIndx);
                    
                    % Sliding Correlation Only Lick
                    [~, lickSlidingVec] = mouse.getSlidingCorrelationWithAndWithout("Task", "lick", "~(tInfo.has_movement)", [], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    medianLickSliding = median(lickSlidingVec);
                    miceLickSliding(1, mouseIndx) = medianLickSliding;
                    
                    % Sliding Correlation Only Movement
                    [~, movemenSlidingVec] = mouse.getSlidingCorrelationWithAndWithout("Task", "movement", "isnan(tInfo.first_lick)", [], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    medianMovementSliding = median(movemenSlidingVec);
                    miceMovementSliding(1, mouseIndx) = medianMovementSliding;
                    
                    % Sliding Correlation Only Cue
                    [~, cueSlidingVec] = mouse.getSlidingCorrelationWithAndWithout("Task", "cue", "~(tInfo.has_movement) & isnan(tInfo.first_lick)", [], timeToRemoveBefore, timeToRemoveAfter, timeWindow, timeShift, smoothFactor, downsampleFactor);
                    medianCueSliding = median(cueSlidingVec);
                    miceCueSliding(1, mouseIndx) = medianCueSliding;
                    
                    % Sliding Correlation Baseline (trials with no lick, no movement, low cue)
                    [baselineSlidingVec] = mouse.getTaskSlidingBaseline("isnan(tInfo.first_lick) & ~(tInfo.has_movement) & tInfo.cue_int == 0.02", timeWindow, timeShift, smoothFactor, downsampleFactor);
                    medianBaselineSliding = median(baselineSlidingVec);
                    miceBaselineSliding(1, mouseIndx) = medianBaselineSliding;
                end
                xAxe = [groupIndx * 4 - 3:groupIndx * 4];
                labels(1, groupIndx * 4 - 3:groupIndx * 4) = ["Lick (trials with no move) sliding of " + group.Type + "\fontsize{7}(median)", "Move (trials no lick) Sliding of " + group.Type + "\fontsize{7}(median)", "Cue (trials no lick & no move) Sliding of " + group.Type + "\fontsize{7}(median)", "Baseline (trials no lick & no move & cue = 0.02) Sliding of " + group.Type + "\fontsize{7}(median)"];
                
                [individualPlot, medianPlot] = obj.drawFourBubble(miceLickSliding, miceMovementSliding, miceCueSliding, miceBaselineSliding, xAxe, ax, true);
                
            end
            
            % Titles
            legend(ax, [individualPlot, medianPlot], 'Individuals', 'Mice Mean', 'Location', 'best')
            
            title(ax, {"Sliding Correlation lick VS movement VS cue VS ''baseline'' during task", signalTitle, "Time removed before: " + timeToRemoveBefore + ", after: " + timeToRemoveAfter, "Time Window: " + string(timeWindow) + ", Time Shift: " + string(timeShift), "\fontsize{7}Smoothed by: " + smoothFactor + ", then downsampled by: " + downsampleFactor})
            xlim(ax, [0.75, AmountOfGroups * 4 + 0.25])
            ax.XTick = [1: AmountOfGroups * 4];
            ax.XTickLabel = labels';
            xtickangle(45)
            ylabel(ax, "Median of sliding correlation")
            
            % savefig("C:\Users\owner\Google Drive\University\ElscLab\Presentations\Graphs\Correlation Vs Sliding Bubbles\Groups Together\" + signalTitle + " - By Groups")
        end
        
        
    end
   
    methods (Static)
        
        function [firstMean, firstRandomMean, secondMean, secondRandomMean, firstRandomSEM, secondRandomSEM] = getStatisticsOfMiceCorrAndSliding(first, firstShuffled, second, secondShuffled)
            
            % Take max of each mouse
            firstShuffledMax = max(firstShuffled, [], 1);
            secondShuffledMax = max(secondShuffled, [], 1);
            
            % Calcl Mean
            firstMean = mean(nonzeros(first));
            firstRandomMean = mean(nonzeros(firstShuffledMax));
            secondMean = mean(nonzeros(second));
            secondRandomMean = mean(nonzeros(secondShuffledMax));
            
            % Calc SEM
            firstRandomSEM = std(firstShuffledMax)/sqrt(length(firstShuffledMax));
            secondRandomSEM =  std(secondShuffledMax)/sqrt(length(secondShuffledMax));
        end
        
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
        
        function [individualPlot, medianPlot, shuffledPlot] = drawTwoBubble(first, firstShuffled, second, secondShuffled, xAxe, ax, shouldPlotIndividuals, shouldPlotShuffled)
            
            [firstMean, ~, secondMean, ~, ~, ~] = ListOfMouseLists.getStatisticsOfMiceCorrAndSliding(first, firstShuffled, second, secondShuffled);
            
            firstShuffledMax = max(firstShuffled, [], 'all');
            secondShuffledMax = max(secondShuffled, [], 'all');
            
            % Plot
            if shouldPlotIndividuals
                for idx = 1:size(first, 2)
                    individualPlot = plot(ax, xAxe, [first(idx), second(idx)], 'o-', 'color', 'black', 'MarkerFaceColor', 'black', 'MarkerSize', 4);
                    hold on
                end
            else
                shouldPlotIndividuals = NaN;
            end
            
            medianPlot = line([xAxe(1) - 0.1, xAxe(1) + 0.1], [firstMean, firstMean], 'Color', '#800080', 'LineWidth', 2);
            line([xAxe(2) - 0.1, xAxe(2) + 0.1], [secondMean, secondMean], 'Color', '#800080', 'LineWidth', 2)
            % plot(ax, xAxe, [firstMean, secondMean], 'd', 'LineWidth', 1, 'color', '#800080', 'MarkerFaceColor', '#800080', 'MarkerSize', 8)
            hold on
            
            if shouldPlotShuffled
                % errorbar(ax, xAxe, [firstRandomMean, secondRandomMean], [firstRandomSEM, secondRandomSEM],'o', 'LineWidth', 1, 'color', '#C0C0C0', 'MarkerFaceColor', '#C0C0C0', 'MarkerSize', 6, 'CapSize', 12)
                shuffledPlot = plot(ax, xAxe, [firstShuffledMax, secondShuffledMax],'o', 'LineWidth', 1, 'color', '#C0C0C0', 'MarkerFaceColor', '#C0C0C0', 'MarkerSize', 6);
                hold on
            else
                shuffledPlot = NaN;
            end
        end
        
        function [individualPlot, medianPlot] = drawFourBubble(first, second, third, fourth, xAxe, ax, shouldPlotIndividuals)
            
            firstMean = mean(nonzeros(first));
            secondMean = mean(nonzeros(second));
            thirdMean = mean(nonzeros(third));
            fourthMean = mean(nonzeros(fourth));
            
            % Plot
            if shouldPlotIndividuals
                for idx = 1:size(first, 2)
                    individualPlot = plot(ax, xAxe, [first(idx), second(idx), third(idx), fourth(idx)], 'o-', 'color', 'black', 'MarkerFaceColor', 'black', 'MarkerSize', 4);
                    hold on
                end
            end
            
            medianPlot = line([xAxe(1) - 0.1, xAxe(1) + 0.1], [firstMean, firstMean], 'Color', '#800080', 'LineWidth', 2);
            line([xAxe(2) - 0.1, xAxe(2) + 0.1], [secondMean, secondMean], 'Color', '#800080', 'LineWidth', 2)
            line([xAxe(3) - 0.1, xAxe(3) + 0.1], [thirdMean, thirdMean], 'Color', '#800080', 'LineWidth', 2)
            line([xAxe(4) - 0.1, xAxe(4) + 0.1], [fourthMean, fourthMean], 'Color', '#800080', 'LineWidth', 2)
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
        
        function [mouseCorrelation, shuffledCorrelation] = runMouseCorrelationByCorrelationType(mouse, correlationType, descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor)
            
            switch lower(correlationType)
                case "correlation"
                    mouseCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, false);
                    shuffledCorrelation = mouse.getWholeSignalCorrelation(descriptionVector, smoothFactor, downsampleFactor, true);
                    
                case "sliding"
                    [mouseCorrelation, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, false);
                    [shuffledCorrelation, ~] = mouse.getWholeSignalSlidingMedian(descriptionVector, timeWindow, timeShift, smoothFactor, downsampleFactor, true);
            end
        end
    end
end