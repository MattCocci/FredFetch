function [vintdata] = vint(series, vint_date, varargin)

  if datenum(vint_date) < datenum(1991,1,1)
    warning('Early vintage date; data might not exist, error likely.')
  end

  % Dispatch the call to different function depending upon whether one
  % or multiple series are specified
  if ~iscell(series), series = {series}; end
  if length(series) == 1
    vintdata = vint_single(series{:}, vint_date, varargin{:});
  else
  end


end
