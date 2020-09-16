% SET PARAMETERS
clear
mouse = "2_from406";
dataFile = "CueInCloud_comb_cloud.mat"; % Other options: "CueInCloud_comb_lick.mat" "CueInCloud_comb_cloud.mat" "CueInCloud_comb_cue.mat"

% CONSTS
FOLDER_DELIMITER = "\";

% LOAD
dataFile = matfile("\\132.64.59.21\Citri_Lab\gala\Phys data\New Rig" + FOLDER_DELIMITER + mouse + FOLDER_DELIMITER + dataFile);
gcampZScored = zscore(dataFile.all_trials')';                              % Needs to be z scored so upwards won't give too much weight
jrgecoZScored = zscore(dataFile.af_trials')';                              % Needs to be z scored so upwards won't give too much weight

%% MAIN
rows = size(gcampZScored,1);
cols = size(gcampZScored, 2);

gcampXJrgeco = zeros(rows, cols * 2 - 1);
gcampXgcamp = gcampXJrgeco;
jrgecoXJrgeco = gcampXJrgeco;
for index = 1:rows
    [gcampXJrgeco(index,:), lags] = xcorr(jrgecoZScored(index,:), gcampZScored(index,:), 'normalized');
    gcampXgcamp(index,:) = xcorr(gcampZScored(index,:), 'normalized');
    jrgecoXJrgeco(index,:) = xcorr(jrgecoZScored(index,:), 'normalized');
end
gcampXJrgeco = sum(gcampXJrgeco) / rows;
gcampXgcamp = sum(gcampXgcamp) / rows;
jrgecoXJrgeco = sum(jrgecoXJrgeco) / rows;
c = corr(gcampZScored', jrgecoZScored');
timeVector = linspace(-20, 20, 20346 * 2 -1);
plot(timeVector, gcampXJrgeco)

% %% TEST
% gcampZScored = dateFile.all_trials;
% gcampZScored = sum(gcampZScored) ./ size(gcampZScored, 1);
% jrgecoZScored = dateFile.af_trials;
% jrgecoZScored = sum(jrgecoTrials) ./ size(jrgecoTrials, 1);
% gcampXJrgeco = zeros(size(gcampZScored,1), size(gcampZScored, 2)* 2 - 1);
% for index = 1:size(gcampZScored, 1)
%     [gcampXJrgeco(index,:), lags] = xcorr(gcampZScored(index,:), jrgecoTrials(index,:), 'normalized');
% end

%% Tests
a = [1,1,0,0,1,1];
b = [0,0,1,1,0,0];

cor = xcorr(a,b);
plot(cor)

c = [1,2,3];
d = [-1,-2,-3];

cor = xcorr(c,d, 'normalized');
plot(cor)