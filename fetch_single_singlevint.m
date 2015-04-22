% OVERVIEW - fetch_single_singlevint.m
%
% This file will fetch a single series for a single vintage from FRED/ALFRED
%
% Required Arguments:
% - api         api key from FRED website
% - series      Fred/Alfred series code to pull
% - vint_date   Which vintage date to pull the series for. Is a matlab detenum
% - frequency   Frequency of the data (typically, this will also be reflected
%               in the saving name so we can pull the same series at multiple
%               frequencies for a given vintage without overwriting: ex.
%               FF_m.txt or FF_d.txt for monthly and daily). Options are the
%               following:
%   - q           quarterly
%   - m           Monthly
%   - b           bi-weekly
%   - w           weekly
%   - d           daily
% - saving      What to save the file as (this could be constructed within this
%               file, but it is instead passed as an argument so we can
%               parallelize)
%
% Notes:
% - This program requires that you add the jsonlab location to your path prior
%   to calling this function.
% - FRED/ALFRED query will return the data in json format. The data is
%   reshaped to be a matrix of dates and values that is then written
%   to a file .
% - If you try to pull quarterly data at a monthly frequency, the Fred API
%   throws an error. So at this step, we will specify monthly
%   frequency if possible, or the otherwise lowest native frequency if not
%   possible, letting downstream programs deal with any spacing and frequency
%   mismatch issues (like align_vintdata.m)
%
function [ pseudo_vint, success ] = ...
  fetch_single_singlevint(api, series, saving, frequency, vint_date, varargin)

  if nargin > 5
    path_dep = varargin{1};
    addpath(path_dep{:})
  end


  %% Fetch the json stuff (it's one long string)

    make_datestr = @(dtnum) datestr(dtnum, 'yyyy-mm-dd');

    % Construct url
    make_url = @(vint_date) ...
      sprintf( [...
      'http://api.stlouisfed.org/fred/series/observations?'...
      'series_id=%s' ...
      '&api_key=%s' ...
      '&realtime_start=%s'...
      '&realtime_end=%s' ...
      '&observation_start=%s' ...
      '&frequency=%s' ...
      '&file_type=json'], ...
      series,...
      api,...
      make_datestr(vint_date), ...
      make_datestr(vint_date),...
      make_datestr(addtodate(vint_date, -20, 'year')),...
      frequency);

    % There are some series for which fred doesn't log vintages until very
    % recently. In these cases, FRED throws an error.
    %
    % Fix:
    %  1. Try to pull the series at a vintage date.
    %  2. If Fred throws an error, query all vintdates
    try
      from_fred   = loadjson(urlread(make_url(vint_date)));
      maxlag      = 0;   % Indicator; says we don't have to construct a pseudo-vintage in this case
      pseudo_vint = {}; % No pseudo-vintage need be constructed

      success = 1;
    catch

      % Query all available vintages for the series
      avlbl_vints = query_vintdates(api, series, frequency, {pwd}, 0, '1776-07-04', '9999-12-31');
      avlbl_vints = avlbl_vints(1:min(10, length(avlbl_vints)));
        %^We will download at most 10 vints (after and including the first
        %available to compute publication lags
      first_avlbl = avlbl_vints(1);

      % If the first available vint isn't until after the requested vint date,
      % construct a pseudo vintage.
      if first_avlbl > vint_date

        % Throw the vintdates in a cell
        avlbl_vints_str = arrayfun(make_datestr, avlbl_vints, 'un', 0);

        % Pull all those vintage dates from fred and load them into a json struct
        from_fred = cellfun(@(vdt) loadjson(urlread(make_url(datenum(vdt)))), avlbl_vints_str, 'un', 0);

        % Function that computes the publication lag; look at the last
        % observation available (the latest release) and see when that became
        % available
        pub_lag = @(fredstruct) ...
          datenum(fredstruct.observations{end}.realtime_end) ...
          - datenum(fredstruct.observations{end}.date);
        maxlag = max(cellfun(pub_lag, from_fred)); % Compute the maximum publication lag

        % Now take the very first vintage of data; we will trim it later to
        % mimic publication lag
        from_fred = from_fred{1};

        pseudo_vint = {make_datestr(first_avlbl), maxlag};
        success = 1;
      else

        % There was a connection error
        success = 0;
      end

    end

  %% Extract observation dates and observation values
  dates_cell  = cellfun(@(obs) obs.date,              from_fred.observations, 'un', 0)';
  values_cell = cellfun(@(obs) str2double(obs.value), from_fred.observations, 'un', 0)';

  dates  = datenum(vertcat(dates_cell{:}));
  values = vertcat(values_cell{:});

  % If we had the problem with the vintages, chop off
  if maxlag
    pseudovint_inds = (dates <= datenum(vint_date)-maxlag);
    dates  = dates(pseudovint_inds);
    values = values(pseudovint_inds);
  end

  %% overwrite the file with a csv
  dlmwrite(saving, [dates, values], 'precision', '%.5f');

end
