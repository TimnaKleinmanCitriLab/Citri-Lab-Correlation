% listOfLists = [AccInAccOut, AudAcc, AudInAccOut, AudInAudOut, OfcAcc];
%     mouseList.plotCrossAndAutoCorrealtionByMouse(["Free", "post"], 0, 20, 300, 10, true)
%     mouseList.plotCrossAndAutoCorrealtionByMouse(["Task", "onset"], 0, 20, 300, 10, true)
%     mouseList.plotCrossAndAutoCorrealtionByMouse(["Task", "onset"], 0, 20, 300, 10, false)
%         mouseList.plotCrossAndAutoCorrealtionByMouse(["Passive", "awake", "BBN", "post"], 0, 20, 300, 10, true)
%         mouseList.plotCrossAndAutoCorrealtionByMouse(["Passive", "awake", "FS", "post"], 0, 20, 300, 10, true)
%     mouseList.plotCorrelationBar(300, 10)
%     mouseList.plotSlidingCorrelationBar(3, 0.2, 300, 10)
%     mouseList.plotCrossCorrelationLagBar(["Free", "post"], 1.5, 300, 10, true)
%     mouseList.plotCrossCorrelationLagBar(["Passive", "awake","FS", "post"], 1.5, 300, 10, true)
%     mouseList.plotCrossCorrelationLagBar(["Passive", "awake","BBN", "post"], 1.5, 300, 10, true)
%     mouseList.plotCorrelationScatterPlot(["Free", "post"], 300, 100)
%     mouseList.plotSlidingCorrelationTaskByOutcome("lick", 3, 0.2, 300, 10)
%     mouseList.plotSlidingCorrelationTaskByOutcome("onset", 3, 0.2, 300, 10)
%     mouseList.plotSlidingCorrelationTaskByOutcome("cue", 3, 0.2, 300, 10)
%
%     mouseList.plotSlidingCorrelationTaskByOutcome("lick", 2, 0.2, 300, 10)
%     mouseList.plotSlidingCorrelationTaskByOutcome("onset", 2, 0.2, 300, 10)
%     mouseList.plotSlidingCorrelationTaskByOutcome("cue", 2, 0.2, 300, 10)
%     mouseList.plotCrossCorrelationOmissionLick("onset", 300, 10)
%     mouseList.plotCrossCorrelationOmissionLick("cue", 300, 10)

for mouseList = loml.ListOfLists
    
    % Sliding by outcome
    mouseList.plotSlidingCorrelationTaskByOutcome("onset", 0.5, 0.1, 300, 10)
    mouseList.plotSlidingCorrelationTaskByOutcome("cue", 0.5, 0.1, 300, 10)
    mouseList.plotSlidingCorrelationTaskByOutcome("lick", 0.5, 0.1, 300, 10)
    close all
    
    % Sliding by lick
    mouseList.plotSlidingCorrelationOmissionLick("onset", 0.5, 0.1, 300, 10)
    mouseList.plotSlidingCorrelationOmissionLick("cue", 0.5, 0.1, 300, 10)
    close all
    
%     % Cross by outcome
%     mouseList.plotCrossCorrelationTaskByOutcome("onset", 300, 10)
%     mouseList.plotCrossCorrelationTaskByOutcome("cue", 300, 10)
%     mouseList.plotCrossCorrelationTaskByOutcome("lick", 300, 10)
%     close all
%     
%     % Cross by lick
%     mouseList.plotCrossCorrelationOmissionLick("onset", 300, 10)
%     mouseList.plotCrossCorrelationOmissionLick("cue", 300, 10)
%     close all
%     
%     % Beg cross by outcome
%     mouseList.plotCrossCorrelationTaskByOutcomeBeginning("onset", 300, 10)
%     mouseList.plotCrossCorrelationTaskByOutcomeBeginning("cue", 300, 10)
%     mouseList.plotCrossCorrelationTaskByOutcomeBeginning("lick", 300, 10)
%     
%     % Beg cross by lick
%     mouseList.plotCrossCorrelationOmissionLickBeginning("onset", 300, 10)
%     mouseList.plotCrossCorrelationOmissionLickBeginning("cue", 300, 10)
%     close all
end






for mouse = AccInAccOut.LoadedMouseList
    mouse.plotSlidingCorrelationAll(["Task", "onset"], 3, 0.2, 300, 100)
end

AccInAccOut.plotCrossCorrelationLagBar(["Task", "onset"], 5, 300, 10, false)
AudAcc.plotCrossCorrelationLagBar(["Task", "onset"], 5, 300, 10, false)
AudInAudOut.plotCrossCorrelationLagBar(["Task", "onset"], 5, 300, 10, false)
AudInAccOut.plotCrossCorrelationLagBar(["Task", "onset"], 5, 300, 10, false)
OfcAcc.plotCrossCorrelationLagBar(["Task", "onset"], 5, 300, 10, false)


listOfLists = [AccInAccOut, AudAcc, AudInAccOut, AudInAudOut, OfcAcc];

times = [];
names = [];
for mouseList = listOfLists
    for mouse = mouseList.LoadedMouseList
            [~, ~, ~, totalTime, ~] = mouse.getInformationReshapeDownsampleAndSmooth(["Passive", "awake", "FS", "post"], 300, 10);
            times = [times, totalTime];
            names = [names, mouse.Name];
    end
end


% Task
for mouse = AccInAccOut.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Task", "onset"], 3, 0.2, 300, 100)
end
for mouse = AudAcc.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Task", "onset"], 3, 0.2, 300, 100)
end
for mouse = AudInAccOut.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Task", "onset"], 3, 0.2, 300, 100)
end
for mouse = AudInAudOut.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Task", "onset"], 3, 0.2, 300, 100)
end
for mouse = OfcAcc.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Task", "onset"], 3, 0.2, 300, 100)
end

% Free - pre
for mouse = OfcAcc.LoadedMouseList
if ~(mouse.Name == "2 from 430")
mouse.plotSlidingCorrelationAll(["Free", "pre"], 3, 0.2, 300, 100)
end
end

% Free - post
for mouse = AccInAccOut.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Free", "post"], 3, 0.2, 300, 100)
end
for mouse = AudAcc.LoadedMouseList
if ~(mouse.Name == "4 from 410")
mouse.plotSlidingCorrelationAll(["Free", "post"], 3, 0.2, 300, 100)
end
end
for mouse = AudInAccOut.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Free", "post"], 3, 0.2, 300, 100)
end
for mouse = AudInAudOut.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Free", "post"], 3, 0.2, 300, 100)
end
for mouse = OfcAcc.LoadedMouseList
mouse.plotSlidingCorrelationAll(["Free", "post"], 3, 0.2, 300, 100)
end



% Load Signals
gcamp = handles.synapse.TRACE.streams.x65F.data;
jrgeco = handles.synapse.TRACE.streams.x60J.data;
load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\2_from500\free\Free_comb.mat')                                       % CHANGE!
gcamp = {gcamp};
jrgeco = {jrgeco};
all_trials(4) = gcamp;                                                                                                     % CHANGE!
af_trials(4) = jrgeco;                                                                                                     % CHANGE!
added_data = {2011301927, "30/11/20", "19:27:17", "post", handles.synapse.TRACE.streams.x60J.fs, "r", '?', '', '', 1, ""}; % CHANGE!
t_info =  [t_info; added_data];

save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\2_from500\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')  % CHANGE!


% Plot signals
gcamp = handles.synapse.TRACE.streams.x65F.data;
jrgeco = handles.synapse.TRACE.streams.x60J.data;

fs = handles.synapse.TRACE.streams.x60J.fs;
totalTime = round(size(gcamp, 2) / fs);
timeVector = linspace(0, totalTime, size(gcamp, 2));

figure("Name", "Signal from all sessions of mouse ", "NumberTitle", "off");
ax = gca;

plot(ax, timeVector, gcamp, 'LineWidth', 1.5, 'Color', '#009999');
hold on;
plot(ax, timeVector, jrgeco, 'LineWidth', 1.5, 'Color', '#990099');
hold off;

title(ax, "Signal From: 2-430 0710 1027", 'FontSize', 12)

legend( "gcamp", "jrgeco", 'Location', 'best', 'Interpreter', 'none')
xlabel("Time (sec)", 'FontSize', 14)
ylabel("zscored \DeltaF/F", 'FontSize', 14)
xlim([0 100])


% Sliding by outcome
loml.OfcAcc.plotSlidingCorrelationTaskByOutcome("onset", 0.5, 0.1, 300, 10)
loml.OfcAcc.plotSlidingCorrelationTaskByOutcome("cue", 0.5, 0.1, 300, 10)
loml.OfcAcc.plotSlidingCorrelationTaskByOutcome("lick", 0.5, 0.1, 300, 10)
close all

% Sliding by lick
loml.OfcAcc.plotSlidingCorrelationOmissionLick("onset", 0.5, 0.1, 300, 10)
loml.OfcAcc.plotSlidingCorrelationOmissionLick("cue", 0.5, 0.1, 300, 10)
close all