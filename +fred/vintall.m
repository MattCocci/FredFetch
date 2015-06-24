function [vintdata] = vintall(series, varargin)

  % Dispatch the call to different function depending upon whether one
  % or multiple series are specified
  very_first = '1776-07-04';
  very_last  = '9999-12-31';

  if isstr(series)
    vintdata = fred.vintrange_single(series, very_first, very_last, varargin{:});

  elseif length(series) == 1
    vintdata = fred.vintrange_single(series, very_first, very_last, varargin{:});

  else
    vintdata = fred.multiple_series(@fred.vintrange_single, 0, series, very_first, very_last, varargin{:});
  end

  % Add publication delays
  vintdata.publag = fred.compute_publag(vintdata.date, vintdata.realtime, vintdata.value);
end
