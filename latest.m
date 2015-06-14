function [data] = latest(series)

  % Dispatch the call to different function depending upon whether one
  % or multiple series are specified
  if isstr(series)
    data = latest_single(series);

  elseif length(series) == 1
    data = latest_single(series{1});

  else
    data = multiple(@latest_single, series);
  end

end
