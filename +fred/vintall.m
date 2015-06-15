function [vintdata] = vintall(series, varargin)

  if ~isstr(series)
    error('Argument ''series'' must be a string')
  end

  %% Try to grab the data
  fprintf('Downloading Fred Data...');
  [query, success] = ReadFredData(1, 'series_id', series, 'realtime_start', '1776-07-04', 'realtime_end', '9999-12-31', varargin{:});

  %% Return on errors
  if ~success
    vintdata.info   = query;
    vintdata.series = series;
    vintdata.date   = [];
    vintdata.value  = [];
    return
  end
  fprintf('done\n');

  %% Parse the data
  vintdata.info   = vertcat(query.info.seriess{:});
  vintdata.series = series;
  obs             = vertcat(query.obs.observations{:});
  Nall            = length(obs);

  %% Put the dates and values into arrays
  flds = {'realtime_start', 'realtime_end', 'date', 'value'};
  isdt = [1 1 1 0];
  for n = 1:length(flds)
    if isdt(n)
      all.(flds{n}) = datenum(vertcat(obs(:).(flds{n})), 'yyyy-mm-dd');
      unq.(flds{n}) = unique(all.(flds{n}));
    else
      all.(flds{n}) = arrayfun(@(t) str2double(obs(t).(flds{n})), 1:Nall)';
    end
  end

  %% Loop over unique observation dates and fill in the data matrix
  vintdata.date           = unq.date;
  vintdata.realtime_start = unq.realtime_start;
  Nobs  = length(vintdata.date);
  Nvint = length(vintdata.realtime_start);
  vintdata.value = nan(Nobs, Nvint);
  for n = 1:Nobs
    match = find(unq.date(n) == all.date);
    for t = 1:length(match)
      fillcols = find(all.realtime_start(match(t)) <= unq.realtime_start);
      vintdata.value(n,fillcols) = all.value(match(t));
    end
  end


end
