function [vintdata] = SeriesAllVintages(api, series, frequency, opt)

  % For making dates in Fred/Alfred format
  fred_date_fmt = 'yyyy-mm-dd';
  fred_datestr  = @(dtnum) datestr(dtnum, fred_date_fmt);


  %% Define defaults and set up options for pull
  defaults = struct(...
                    'observation_start', '1776-07-04',...
                    'observation_end',   '9999-12-31',...
                    'saving',            {{}},...
                    'max_attempt',       2,...
                    'verbose',           1, ...
                    'pseudo_vint',       0, ...
                    'units',             'lin');

  if exist('opt', 'var')
    opt = FillDefaultSettings(defaults, opt);
  else
    opt = defaults;
  end
  if opt.verbose
    fprintf('\nFetching %s at frequency ''%s'' with options...\n', series, frequency);
    opt
  end


  %% Construct url for pull
  url.info = sprintf([...
    'https://api.stlouisfed.org/fred/series?'...
    'series_id=%s' ...
    '&api_key=%s' ...
    '&realtime_start=1776-07-04' ...
    '&realtime_end=9999-12-31' ...
    '&units=%s' ...
    '&file_type=json'], ...
    series,...
    api,...
    opt.units);

  url.data = sprintf([...
    'https://api.stlouisfed.org/fred/series/observations?'...
    'series_id=%s' ...
    '&api_key=%s' ...
    '&frequency=%s' ...
    '&observation_start=%s' ...
    '&observation_end=%s' ...
    '&realtime_start=1776-07-04'...
    '&realtime_end=9999-12-31', ...
    '&units=%s' ...
    '&file_type=json'], ...
    series, ...
    api, ...
    frequency,...
    fred_datestr(opt.observation_start),...
    fred_datestr(opt.observation_end),...
    opt.units);

  %% Grab the data
  try
    info = loadjson(urlread(url.info));
    data = loadjson(urlread(url.data));
  catch
    opt.max_attempt = opt.max_attempt - 1;
    if opt.max_attempt
      vintdata = SeriesVintage(api, series, frequency, opt);
    else
      vintdata = [];
    end
    return
  end


  %% Parse data

    from_fred = vertcat(data.observations{:});

    % Convert dates from strings; this method is quickest relative to
    % other more terse and clear methods
    date_flds = {'realtime_start'; 'realtime_end'; 'date'};
    for f = 1:length(date_flds)
      ff = date_flds{f};
      all.(ff) = vertcat(from_fred.(ff));
      all.(ff) = datenum(str2num(all.(ff)(:,1:4)), ...
                         str2num(all.(ff)(:,6:7)), ...
                         str2num(all.(ff)(:,9:10)));
      unq.(ff) = unique(all.(ff));
    end

    % Convert strings to numbers, replacing '.' with NaN
    all.value = cellfun(@str2double, {from_fred.value}, 'un', 0)';
    notnum = cellfun(@isempty, all.value);
    all.value(notnum) = {NaN};
    all.value = vertcat(all.value);

    % Initialize based on unique number of observation and vint dates
    nvint = length(unq.realtime_start);
    nobs  = length(unq.date);
    vintdata.values   = nan(nobs, nvint);
    vintdata.obsdates = unq.date;

    % Loop over unique observations
    for t = 1:nobs

      % Find the entries and corresponding realtime starts that match
      % that observation date
      obsmatch   = find(all.date == unq.date(t));
      vintstarts = all.realtime_start(obsmatch);
    end


  %%% Parse the data
  %vintdata.info = info.seriess{:};
  %data = vertcat(data.observations{:});
  %nobs = length(data);
  %vintdata.obsdates = nan(nobs,1);
  %vintdata.values   = nan(nobs,1);
  %for t = 1:nobs
    %vintdata.obsdates(t) = datenum(data(t).date, 'yyyy-mm-dd');
    %val = str2num(data(t).value);
    %if ~isempty(val)
      %vintdata.values(t) = val;
    %end
  %end


  %%% Maybe save the data
  %if ~isempty(opt.saving)
    %save(opt.saving, 'vintdata');
  %end

end

