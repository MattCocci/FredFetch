% OVERVIEW - fetch_single_multiplevint.m
%
% This file will fetch a single series for multiple vintages from FRED/ALFRED
%
function [ pseudo_vint, fetchstats ] = ...
  fetch_single_multiplevint(api, dpath, path_dep, series, frequency, vint_dates, max_attempt)

  tic;

  %% To track whether it is a legit vint or pseudo vint. Will be filled with
  %  the first available vint and the publication lag if pseudo vintage
  pseudo_vint = cell(length(vint_dates), 1);

  %% Fetch the json stuff (it's one long string)

    % Construct url
    make_datestr = @(dtnum) datestr(dtnum, 'yyyy-mm-dd');
    make_url = @(vint_start, vint_end) ...
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
      make_datestr(vint_start), ...
      make_datestr(vint_end),...
      make_datestr(addtodate(vint_start, -20, 'year')),...
      frequency);

    %% Query all observations over our vintage range; log any error messages
    try

      % Query the available vintage dates that fred has logged from the vintstart to the end of time
      avlbl_vints = query_vintdates(api, series, frequency, path_dep, 0, '1776-07-04', '9999-12-31');
      first_avlbl = avlbl_vints(1);

      % If there's at least 1 vintage available before the first requested vintdate
      if sum(vint_dates(1) >= avlbl_vints)
        first  = vint_dates(1);
        pseudo = 0; % No need to use pseudo vintages
        last   = vint_dates(end);
      else
        first = first_avlbl;
        pseudo = 1; % We'll be using pseudo vintages
        last   = avlbl_vints(min(20, length(avlbl_vints))); % Pull a few extra vints so we can get a better idea of publication lags later on
      end

      % Pull from fred
      from_fred = loadjson(urlread( make_url(first, last) ));
      freddata = from_fred.observations;

      success = 1;
      err     = {};
      dltime  = NaN; % Filled in later
      write   = 1;

    catch

      % If you haven't exhausted all attempts, try again
      if max_attempt-1
        pause(5)
        [pseudo_vint, fetchstats] = fetch_single_multiplevint(api, dpath, path_dep, series, frequency, vint_dates, max_attempt-1);
        success = fetchstats.success;
        err     = fetchstats.err;
        dltime  = fetchstats.dltime;
      else
        success = 0;
        err     = lasterror; % If exhausted all atempts, return the error message
        dltime  = toc; % If exhausted all atempts, return the error message
      end

      write = 0;
    end


  %% If you got the data, write it
  if success && write

    %% If pseudo vintages, compute max Publication lags
      if pseudo
        obsdates = unique(cellfun(@(x) datenum(x.date), freddata)'); % All observation dates

        publag_obsdates = obsdates(obsdates > first_avlbl);
          %^Those observations recorded after FRED starting tracking vints, so we
          % can compute a publication lag

        % Loop over observation dates where a publication lag is observed; record it
        publag = nan(length(publag_obsdates),1);
        for dt = 1:length(publag_obsdates)
          obs_match = cellfun(@(x) datenum(x.date)==publag_obsdates(dt), freddata); % Entries where the observation date is one we want
          publag(dt) = min(cellfun(@(x) datenum(x.realtime_start)-publag_obsdates(dt), freddata(obs_match)));
        end
        publag = max(publag);
      end


    %% Loop over vintdates and write
      for vd = 1:length(vint_dates)

        % If vintage date is before the first one available
        if vint_dates(vd) < first_avlbl

          pseudo_vint{vd} = {make_datestr(first_avlbl), publag};

          % Use first available vintage
          first_vint_entries = find(cellfun(@(x) ~strcmp(x.value, '.') && datenum(x.realtime_start) == first_avlbl, freddata)); % Indices of entries where realtime_start = first_avlbl and the obsrvation is non-missing
          obsdates = cellfun(@(x) datenum(x.date), freddata(first_vint_entries))'; % Observation dates for that vintage

          % Chop off those observations that wouldn't have been available by the
          % vint date given the subsequent observed pub lag
          if ~isempty(obsdates)
            vint_match = first_vint_entries(vint_dates(vd) >= (obsdates+publag));
          else
            vint_match = [];
          end

        else

          % Entries where the vintage data realtime start is before the vintage date
          atafter_realstart = cellfun(@(x) vint_dates(vd) >= datenum(x.realtime_start), ...
                                      freddata)';

          % Indices for all entries where the the vintage date is before the
          % realtime end or equal to it (only allowed for last vintage date) before_realend    = cellfun(@(x) vint_dates(vd) < datenum(x.realtime_end) || floor(vd/length(vint_dates))*(vint_dates(vd)==datenum(x.realtime_end)), ...
          before_realend    = cellfun(@(x) vint_dates(vd) < datenum(x.realtime_end) || floor(vd/length(vint_dates))*(vint_dates(vd)==datenum(x.realtime_end)), ...
                                      freddata)';

          % Value does not equal '.' or missing
          isnum = cellfun(@(x) ~strcmp(x.value, '.') , freddata)';


          vint_match = find(atafter_realstart .* before_realend .* isnum);
        end


        if ~isempty(vint_match)
          values = cellfun(@(entry) str2num(entry.value), freddata(vint_match))';
          dates  = datenum(cellfun(@(entry) entry.date, freddata(vint_match), 'un', 0)');

          saving = sprintf('%s/%s/IndividualSeries/%s_%s', dpath, make_datestr(vint_dates(vd)), series, frequency);
          dlmwrite(saving, [dates, values], 'precision', '%.5f');
        end
      end

      dltime = toc;

  end % end if success

  %% Pack in all of the info
  fetchstats.success = success;
  fetchstats.err     = err;
  fetchstats.dltime  = dltime;


end
