function [ releases ] = ...
  fetch_releases(api, series, frqcy, tform, vintrange, dpath, max_attempt)

  if length(vintrange) == 1
    vintrange = [vintrange; datenum('9999-12-31')];
  end
% Construct url
  make_datestr = @(dtnum) datestr(dtnum, 'yyyy-mm-dd');
  url = ...
    sprintf( [...
    'http://api.stlouisfed.org/fred/series/observations?'...
    'series_id=%s' ...
    '&api_key=%s' ...
    '&realtime_start=%s'...
    '&realtime_end=%s' ...
    '&frequency=%s' ...
    '&file_type=json'], ...
    series,...
    api,...
    make_datestr(vintrange(1)), ...
    make_datestr(vintrange(2)),...
    frqcy);

  try
    from_fred = loadjson(urlread(url));
  catch
    if max_attempt-1
      fetch_releases(api, series, frqcy, tform, vintrange, dpath, max_attempt);
    else
      fprintf('NOTE: Unable to retrieve %s\n', series);
    end
    return
  end

  from_fred = from_fred.observations;

  % Get information from fred about dates and values for quick indexing later
  Nfred          = length(from_fred);
  obs_dates_all  = nan(Nfred,1); % observation dates from fred; includes duplicates
  end_vint_all   = nan(Nfred,1);
  values_all     = nan(Nfred,1);
  for i_ = 1:Nfred
    obs_dates_all(i_)  = datenum(from_fred{i_}.date);
    start_vint_all(i_) = datenum(from_fred{i_}.realtime_start);
    end_vint_all(i_)   = datenum(from_fred{i_}.realtime_end);

    val = from_fred{i_}.value;
    if strcmp(val, '.')
      values_all(i_) = NaN;
    else
      values_all(i_) = str2num(val);
    end
  end
  % Adjust obs_dates so a quarter happens on the first day of the last
  % month (nowcast convenction), not the first of the first month (Fred
  % convenction)
  if strcmp(frqcy, 'q')
    obs_dates_all = arrayfun(@(dt) addtodate(dt, 2, 'month'), obs_dates_all);
  end
  obs_dates      = unique(obs_dates_all);
  vint_dates_unq = unique(start_vint_all);
  Nobs           = length(obs_dates);
  Nvint          = length(vint_dates_unq);

  % Set up a big matrix to hold all obs and vints, then loop
  values     = nan(Nobs, Nvint);
  vints4vals = nan(Nobs,Nvint);
  rlscount   = nan(Nobs,1);
  for t = 1:Nobs

    % Find the indices within the long "_all" vectors that match this
    % particular obs date
    t_match = find(obs_dates(t) == obs_dates_all);

    % Fill in the vintage dates for time t
    t_vints = start_vint_all(t_match);
    for v = 1:length(t_vints)
      tofill  = find(t_vints(v) <= vint_dates_unq);

      values(t,tofill)     = values_all(t_match(v));
      vints4vals(t,tofill) = start_vint_all(t_match(v));
    end
    rlscount(t) = length(t_vints);
  end

  %% Transform the data
  tfvalues = transform(values, tform, 1);

  %% Collapse the data into releases
  max_releases = max(rlscount);
  rlsvalues    = nan(Nobs, max_releases);
  rlsdates     = nan(Nobs, max_releases);

  % Loop over observations dates
  for t = 1:Nobs
    t_vdates     = vints4vals(t,:);  % Vint dates available for t
    t_vdates_unq = unique(t_vdates(~isnan(t_vdates))); % Unique Vintage dates available for t

    % Loop over unique vntage dates for t
    for d = 1:length(t_vdates_unq)
      touse = find(t_vdates_unq(d) == t_vdates,1); % Find first index matching a unique vintdate

      if ~isempty(touse)
        rlsvalues(t,d) = tfvalues(t,touse); % Fill in the value

        % Only store date it is close to the observation date (i.e. if
        % the release date is shortly after, < 60 days, after the
        % observation date.) This is relevant for cases where Fred
        % hasn't tracked vintages, hence the observation date might be
        % way before the first vintage date available.
        if t_vdates_unq(d) - obs_dates(t) < 160
          rlsdates(t,d)  = t_vdates_unq(d);
        end
      end

    end
  end

  % Fill in
  releases.series    = series;
  releases.obs_dates = obs_dates;
  releases.rlsvalues = rlsvalues;
  releases.rlsdates  = rlsdates;

  save([dpath, series, '.mat'], 'series', 'obs_dates', 'rlsvalues', 'rlsdates')

end
