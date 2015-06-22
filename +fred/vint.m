%% vint.m
%
% Get a dataset for some vintage date. Allows users to query single and
% multiple series.
%
% Input Arguments
% - series      A single series name like 'GDPC1' or a cell of series
%               names like {'GDPC1'; 'NAPM';}
% - vint_date   A vintage date; can be a datenum or datestr (that can be
%               converted by function datenum() to a datenum
% - varargin    Any FRED API options you want to add to the URL,
%               specified in order (option_name, option_value).
%
%               Example:
%                 vint('GDPC1', '2015-01-01', 'observation_start', '1991-01-01', 'units', 'chg')
%
%               This will append '&observation_start=1991-01-01&units=chg'
%               onto the URL.
%
%               NOTE: This library is designed so that you don't
%               have to worry about specifying these extra options, but
%               if you've read the FRED API documentation and you want
%               to make heaver use of it, you have that option.
%
function [vintdata] = vint(series, vint_date, varargin)

  if datenum(vint_date) < datenum(1991,1,1)
    warning('Early vintage date; data might not exist, error likely.')
  end

  % Dispatch the call to different function depending upon whether one
  % or multiple series are specified
  if isstr(series)
    vintdata = fred.vint_single(series, vint_date, 1, varargin{:});

  elseif length(series) == 1
    vintdata = fred.vint_single(series{1}, vint_date, 1, varargin{:});

  else
    vintdata = fred.multiple_(@fred.vint_single, series, vint_date, 0, varargin{:});
  end


end
