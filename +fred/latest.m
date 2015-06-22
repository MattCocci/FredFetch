%% latest.m
%
%
function [data] = latest(series, toDataset)

  if ~exist('toDataset', 'var')
    toDataset = 1;
  end

  % Dispatch the call to different function depending upon whether one
  % or multiple series are specified
  if isstr(series)
    data = fred.latest_single(series);

  elseif length(series) == 1
    data = fred.latest_single(series{1});

  else
    data = fred.multiple_(@fred.latest_single, toDataset, series);
  end

end
