% Was useful for uploading free, has no use either then that

MOUSE_NAME = "2_from430";
SMOOTH_FACTOR = 300;


FOLDER = "\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\";
IN_FOLDER = "\free\Free_comb_old.mat";


freeMouse = load(FOLDER + MOUSE_NAME + IN_FOLDER);

for rowIndex = 1:size(freeMouse.t_info, 1)
    gcampSignal = freeMouse.all_trials(rowIndex);
    gcampSignal = gcampSignal{:};
    jrgecoSignal = freeMouse.af_trials(rowIndex);
    jrgecoSignal = jrgecoSignal{:};
    
    signalLen = size(gcampSignal, 2);
    fs = freeMouse.t_info.fs(rowIndex);
    trialTime = signalLen / fs;
    % timeVec1 = 0:1/fs:trialTime;
    timeVector = linspace(0, trialTime, signalLen);
    
    gcampSignal = smooth(gcampSignal', SMOOTH_FACTOR)';
    jrgecoSignal = smooth(jrgecoSignal', SMOOTH_FACTOR)';
    
    signalCorrelation = corr(gcampSignal', jrgecoSignal');
    
    figure("Name", "Signal from all sessions of mouse", "NumberTitle", "off");
    ax = gca;
    
    plot(ax, timeVector, gcampSignal, 'LineWidth', 1.5, 'Color', '#009999');
    hold on;
    plot(ax, timeVector, jrgecoSignal, 'LineWidth', 1.5, 'Color', '#990099');
    hold off;
    title({"Mouse: " + MOUSE_NAME, " Row:" + rowIndex, "Smooth factor: " + SMOOTH_FACTOR, "Correlation: " + signalCorrelation}, 'interpreter', 'none')
    
    legend("gcamp", "jrgeco")
    
    [gcampType, jrgecoType] = mouse1.findGcampJrgecoType();
    
    legend(gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best', 'Interpreter', 'none')
    xlabel("Time (sec)", 'FontSize', 14)
    ylabel("zscored \DeltaF/F", 'FontSize', 14)
    xlim([0 100])
end