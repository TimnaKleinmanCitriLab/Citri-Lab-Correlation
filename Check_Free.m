% Was useful for uploading free, has no use either then that
checkMouse()

function checkMouse()
    MOUSE_NAME = "4_from440";
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

%         [gcampType, jrgecoType] = mouse1.findGcampJrgecoType();

%         legend(gcampType + " (gcamp)", jrgecoType + " (jrgeco)", 'Location', 'best', 'Interpreter', 'none')
        xlabel("Time (sec)", 'FontSize', 14)
        ylabel("zscored \DeltaF/F", 'FontSize', 14)
        xlim([0 100])
    end
end

%% Save Free
save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\####\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')

%% Load Free
% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\3_from410\free\Free_comb_original.mat')
% t_info.organized_date = [2002041635; 2002041716];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"; "post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['l'; 'r'];
% t_info.strength = ['700/300'; '???/???'];
% t_info.recording_notes = {''; 'a bit more signal in geco'};
% t_info.other = {''; ''};
% t_info.display = [0; 0];
% t_info.reason_not = [""; ""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\3_from410\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')
% 
% 
% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\4_from410L\free\Free_comb_original.mat')
% t_info.organized_date = [2001291254];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['l'];
% t_info.strength = ['600/250'];
% t_info.recording_notes = {'Geco flat + 40 min recording'};
% t_info.other = {''};
% t_info.display = [0];
% t_info.reason_not = [""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\4_from410L\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')
% 
% 
% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\3_from430\free\Free_comb_original.mat')
% t_info.organized_date = [2005241328; 2005241352];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"; "post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['l'; 'r'];
% t_info.strength = {'1000/400'; '600/300'};
% t_info.recording_notes = {'Kind of good + 20 min'; 'Stick with r hemi + 20 min'};
% t_info.other = {''; ''};
% t_info.display = [0; 0];
% t_info.reason_not = [""; ""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\3_from430\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')
% 
% 
% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\4_from430\free\Free_comb_original.mat')
% t_info.organized_date = [2005241328; 2005241352];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"; "post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['l'; 'r'];
% t_info.strength = {'600/300'; '600/250'};
% t_info.recording_notes = {''; 'Bad geco for some reason'};
% t_info.other = {''; ''};
% t_info.display = [0; 0];
% t_info.reason_not = [""; ""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\4_from430\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')


% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\1_from500\free\Free_comb_original.mat')
% t_info.organized_date = [2006161224; 2006161315];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"; "post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['r'; 'l'];
% t_info.strength = ['1000/200'; '1000/200'];
% t_info.recording_notes = {'good gcamp, geco - meh + 40 min'; 'Ok sig, but not as nice as right, stick to R'};
% t_info.other = {''; ''};
% t_info.display = [0; 0];
% t_info.reason_not = [""; ""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\1_from500\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')

% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\2_from500\free\Free_comb_original.mat')
% t_info.organized_date = [2006231613; 2006231659; 2006291746];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"; "post"; "post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['l'; 'r'; '?'];
% t_info.strength = {'600/200'; '600/200'; '?'};
% t_info.recording_notes = {''; 'very nice geco'; 'different folder - shouldnt use'};
% t_info.other = {''; ''; ''};
% t_info.display = [0; 0; 0];
% t_info.reason_not = [""; ""; ""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\2_from500\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')

% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\3_from500\free\Free_comb_original.mat')
% t_info.organized_date = [2006231748; 2006231839; 2006291757];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"; "post"; "post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['r'; 'l'; '?'];
% t_info.strength = {'300/50'; '500/300'; '?'};
% t_info.recording_notes = {'Both channels have signal + Go with this'; ''; 'different folder - shouldnt use'};
% t_info.other = {''; ''; ''};
% t_info.display = [0; 0; 0];
% t_info.reason_not = [""; ""; ""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\3_from500\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')


% load('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\4_from440\free\Free_comb_original.mat')
% t_info.organized_date = [2007191818; 2007191903];
% t_info = movevars(t_info, 'organized_date', 'Before', 'date');
% t_info.pre_or_post = ["post"; "post"];
% t_info = movevars(t_info, 'pre_or_post', 'Before', 'fs');
% t_info.hemisphere = ['l'; 'r'];
% t_info.strength = {'800/500'; '800/250'};
% t_info.recording_notes = {'Signal in both, but has artifacts + r hemi was better'; 'Less gcamp, but less artifacts + r hemi was better'};
% t_info.other = {''; ''};
% t_info.display = [0; 0];
% t_info.reason_not = [""; ""];
% save('\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig\4_from440\free\Free_comb.mat', 't_info', 'af_trials', 'all_trials')
