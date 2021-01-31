lick_tms = mouse.Info.Task.onset.first_lick;     %taking licks times

lick_tms(lick_tms > 12) = nan;   % taking only licks that occur <7 seconds into the trial (arbitrary)
fs_times = round([((lick_tms + 4.75)*1000),((lick_tms+7)*1000)]);  % get the times for 4 and 6 seconds (1s before and after lick, since time starts at -5)

lick_dat1 = zeros(3840, fs_times(1,2) - fs_times(1,1) + 1);
lick_dat2 = zeros(3840, fs_times(1,2) - fs_times(1,1) + 1);

data = mouse.ProcessedRawData.Task.onset.gcamp;
data2 = mouse.ProcessedRawData.Task.onset.jrgeco;

for ii = 1:length(fs_times)
    if ~isnan(fs_times(ii, 1))  % if there was a lick
        lick_dat1(ii, :) = data(ii, fs_times(ii, 1):fs_times(ii, 2));   % take the data in this window
        lick_dat2(ii,:) = data2(ii, fs_times(ii, 1):fs_times(ii, 2));
        data(ii, fs_times(ii, 1):fs_times(ii, 2)) = nan;                % replace it with nans in the data
        data2(ii, fs_times(ii, 1):fs_times(ii, 2)) = nan;
     else
         lick_dat1(ii, :) = nan(1, fs_times(1,2) - fs_times(1,1) + 1);    % if there was no lick, just pad with nans
         lick_dat2(ii, :) = nan(1, fs_times(1,2) - fs_times(1,1) + 1);
    end
end

newGcampSignal = reshape(data', 1, []);
newJrgecoSignal = reshape(data2', 1, []);

newGcampSignal=(newGcampSignal(~isnan(newGcampSignal)));
newJrgecoSignal=(newJrgecoSignal(~isnan(newJrgecoSignal)));

% newGcampSignal = smooth(newGcampSignal', 300)';
% newJrgecoSignal = smooth(newJrgecoSignal', 300)';

corr(newGcampSignal', newJrgecoSignal')

%% regular corr

ori_data = mouse.ProcessedRawData.Task.onset.gcamp;
ori_data2 = mouse.ProcessedRawData.Task.onset.jrgeco;
ori_data = reshape(ori_data', 1, []);
ori_data2 = reshape(ori_data2', 1, []);

% ori_data = smooth(ori_data', 300)';
% ori_data2 = smooth(ori_data2', 300)';

corr(ori_data', ori_data2')



