% SET PARAMETERS
clear
close all
TIME_WINDOW = 20;                                                          % ASK - should it not be a const?
AMOUN_OF_SAMPELS = 20346;                                                  % ASK - should it not be a const
TIME_VECTOR = linspace(-TIME_WINDOW, TIME_WINDOW, AMOUN_OF_SAMPELS * 2 - 1);
TIME_WINDOW_GRAPH = [-3, 3];

% CREATE MICE LISTS
ofcAccMice = [OfcAccMouse("1_from406", false), OfcAccMouse("2_from406", false), OfcAccMouse("3_from406", true), OfcAccMouse("6_from406", false)];
audAccMice = [AudAccMouse("3_from410", false), AudAccMouse("4_from410", false), AudAccMouse("4_from410L", false)];
audOfcMice = [AudOfcMouse("2_from430", false), AudOfcMouse("3_from430", false), AudOfcMouse("4_from430", false)];
accInAccOutMice = [AccInAccOutMouse("1_from500", false), AccInAccOutMouse("2_from500", false), AccInAccOutMouse("3_from500", false)];
audInAccOutMice = [AudInAccOutMouse("1_from440", false), AudInAccOutMouse("2_from440", false), AudInAccOutMouse("3_from440", false)];
audInAudOutMice = [AudInAudOutMouse("4_from440", false)];

% Other
set(groot, 'DefaultLegendInterpreter', 'none')

%% MAIN
% Single Mouse
% mouse = AccInAccOutMouse("1_from500", false);
% plotCrossCorrelationSingleMouse(mouse, TIME_VECTOR, TIME_WINDOW_GRAPH);

% Mice Lists - Cross Correlation
% plotCrossCorrelationMiceList(ofcAccMice, TIME_VECTOR, TIME_WINDOW_GRAPH);
% plotCrossCorrelationMiceList(audAccMice, TIME_VECTOR, TIME_WINDOW_GRAPH);
% plotCrossCorrelationMiceList(audOfcMice, TIME_VECTOR, TIME_WINDOW_GRAPH);
% plotCrossCorrelationMiceList(accInAccOutMice, TIME_VECTOR, TIME_WINDOW_GRAPH); %Done
% plotCrossCorrelationMiceList(audInAccOutMice, TIME_VECTOR, TIME_WINDOW_GRAPH);
% plotCrossCorrelationMiceList(audInAudOutMice, TIME_VECTOR, TIME_WINDOW_GRAPH);

% Mice Lists - Auto Correlation
% plotAutoCorrelationMiceList(audInAudOutMice, "AUD In", "AUD Out", TIME_VECTOR);

function plotCrossCorrelationSingleMouse(mouse, timeVector, timeWindowGraph)
% Create figure and subplots
fig = figure("Name", "Cross Correlation Between " + mouse.GCAMP + " and " + mouse.JRGECO + " for mouse " + mouse.Name, "NumberTitle","off");
subPlots = createSubPlots();
 
% Plot
mouse.plotMouseCrossCorrelations(subPlots, timeVector)

% Add titles
setSubPlotsTitlesLabelsLegend(fig, subPlots, mouse, timeVector, timeWindowGraph)
end

function plotCrossCorrelationMiceList(miceList, timeVector, timeWindowGraph)
% Create figure and subplots
fig = figure("Name", "Cross Correlation Between " + miceList(1).GCAMP + " and " + miceList(1).JRGECO, "NumberTitle","off");
subPlots = createSubPlots();

holdSubPlots(subPlots, 'on')

% Plot
for mouse = miceList
    mouse.plotMouseCrossCorrelations(subPlots, timeVector)
end

% Add titles
setSubPlotsTitlesLabelsLegend(fig, subPlots, miceList, timeVector, timeWindowGraph)

% Finish
holdSubPlots(subPlots, 'off')
end

function plotAutoCorrelationMiceList(miceList, firstSignal, secondSignal, timeVector)
% Create figure and subplots
firstFig = figure("Name", "Auto Correlation of " + firstSignal, "NumberTitle","off");
[firstPlotByCloud, firstPlotByCue, firstPlotByLick, firstPlotByMove, firstPlotByOnset] = createSubPlots();

secFig = figure("Name", "Auto Correlation of " + secondSignal, "NumberTitle","off");
[secPlotByCloud, secPlotByCue, secPlotByLick, secPlotByMove, secPlotByOnset] = createSubPlots();

holdSubPlots(firstPlotByCloud, firstPlotByCue, firstPlotByLick, firstPlotByMove, firstPlotByOnset, 'on')
holdSubPlots(secPlotByCloud, secPlotByCue, secPlotByLick, secPlotByMove, secPlotByOnset, 'on')

miceNames = strings(size(miceList));

% Plot
for idx = 1:size(miceList, 2)
    mouse = miceList(idx);
    mouse.plotAutoCorrelationByCloud(firstPlotByCloud, secPlotByCloud, timeVector)
    mouse.plotAutoCorrelationByCue(firstPlotByCue, secPlotByCue, timeVector)
    mouse.plotAutoCorrelationByLick(firstPlotByLick, secPlotByLick, timeVector)
    mouse.plotAutoCorrelationByMovement(firstPlotByMove, secPlotByMove, timeVector)
    mouse.plotAutoCorrelationByOnset(firstPlotByOnset, secPlotByOnset, timeVector)
    miceNames(idx) = mouse.Name;
end

% Add titles
setSubPlotsTitlesLabelsLegend(firstFig, firstPlotByCloud, firstPlotByCue, firstPlotByLick, firstPlotByMove, firstPlotByOnset, miceNames)
setSubPlotsTitlesLabelsLegend(secFig, secPlotByCloud, secPlotByCue, secPlotByLick, secPlotByMove, secPlotByOnset, miceNames)

% Finish
holdSubPlots(firstPlotByCloud, firstPlotByCue, firstPlotByLick, firstPlotByMove, firstPlotByOnset, 'off')
holdSubPlots(secPlotByCloud, secPlotByCue, secPlotByLick, secPlotByMove, secPlotByOnset, 'off')
end

%%%%%%%%%%%%%% Helpers %%%%%%%%%%%%%%
function  subPlots = createSubPlots()
plotByCloud = subplot(2,3,1);
plotByCue = subplot(2,3,2);
plotByLick = subplot(2,3,3);
plotByMove = subplot(2,3,4);
plotByOnset = subplot(2,3,5);
subPlots = {plotByCloud, plotByCue, plotByLick, plotByMove, plotByOnset};
end

function setSubPlotsTitlesLabelsLegend(fig, subPlots, miceList, timeVector, timeWindowGraph)
[plotByCloud, plotByCue, plotByLick, plotByMove, plotByOnset] = subPlots{:};

% Titles
title(plotByCloud, "By Cloud")
title(plotByCue, "By Cue")
title(plotByLick, "By Lick")
title(plotByMove, "By Move")
title(plotByOnset, "By Onset")

%Labels
xAxes = findobj(fig, "Type", "Axes");
xLabels = get(xAxes, "XLabel");
xLabels = [xLabels{:}];
set(xLabels, "String", "Time Shift (s)")


%Legends
miceNames = strings(size(miceList));
for idx = 1:size(miceList, 2)
    miceNames(idx) = miceList(idx).Name;
end
legend(plotByLick, miceNames, 'Location', 'best', 'Interpreter', 'none', 'AutoUpdate','off');


% Set limits
set([subPlots{:}], 'XLim', timeWindowGraph)

    yMin = 0;
    yMax = 0;

for curPlot = subPlots                                                     % Find min max y
    yTemp = ylim(curPlot{1});
    yMinTemp = yTemp(1);
    yMaxTemp = yTemp(2);
    yMin = min(yMin, yMinTemp);
    yMax = max(yMax, yMaxTemp);
end
set([subPlots{:}], 'YLim', [yMin, yMax])

%Add Lines
for curPlot = subPlots                                                     % Set all axes to the same y and
    ylim(curPlot{1}, 'manual')
    hold on
    line(curPlot{1}, [0, 0], [yMin, yMax], 'Color', [192, 192, 192]/255)   % Color gray
    hold off
    xlim(curPlot{1}, 'manual')
    hold on
    line(curPlot{1}, [timeVector(1), timeVector(length(timeVector))], [0,0], 'Color', [192, 192, 192]/255)   % Color gray
    hold off
end
end

function holdSubPlots(subPlots, howToHold)
for subPlot = subPlots
    hold (subPlot{1}, howToHold)
end
end


%% Raw Data
% Create figure and subplots
function createDrawRaw(miceList, timeVector, timeWindowGraph)
fig = figure("Name", "Cross Correlation Between " + miceList(1).GCAMP + " and " + miceList(1).JRGECO, "NumberTitle","off");
subPlots = createSubPlots();

holdSubPlots(subPlots, 'on')

% Plot
for mouse = miceList
    mouse.plotMouseCrossCorrelations(subPlots, timeVector)
end

% Add titles
setSubPlotsTitlesLabelsLegend(fig, subPlots, miceList, timeVector, timeWindowGraph)

% Finish
holdSubPlots(subPlots, 'off')
end
