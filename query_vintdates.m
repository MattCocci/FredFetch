function [ merged_vint_dates, varargout ] = ...
  query_vintdates(api, series, frequency, path_dep, parworkers, start_date, end_date, varargin)

  if ~iscell(series), series = {series}; end
  if ~isempty(path_dep), addpath(path_dep{:}); end


  %% Construct a query string and to pull the release dates
  url_start = 'http://api.stlouisfed.org/fred/series/vintagedates?';
  url = @(srs) ...
         sprintf('%sseries_id=%s&api_key=%s&realtime_start=%s&realtime_end=%s&file_type=json', ...
                 url_start, srs, api, start_date, end_date);


  %% Loop over series and pull
  vint_dates = cell(length(series),1);

  if parworkers
    poolobj = parpool(parworkers); % Open up a pool
    addAttachedFiles(poolobj, path_dep); 

    parfor s = 1:length(series)
      from_fred = loadjson(urlread(url(series{s})));
      vint_dates{s} = from_fred.vintage_dates';
    end
    delete(poolobj)
  else % non-parallel version 
    for s = 1:length(series)
      from_fred = loadjson(urlread(url(series{s})));
      vint_dates{s} = datenum(vertcat(from_fred.vintage_dates{:}));
    end
  end

  %% Merge the dates and (maybe) save
  merged_vint_dates = vint_dates{1};
  for i_ = 2:length(series)
    merged_vint_dates = union(merged_vint_dates, vint_dates{i_});
  end
  if nargin > 7
    saveas = varargin{1};
    dlmwrite(saveas, datestr(merged_vint_dates, 'yyyy-mm-dd'), 'delimiter', '');
    fprintf('Vintage dates saved in: %s\n', saveas);
  end

  if nargout > 1
    varargout{1} = cellfun(@(vds) vds(1), vint_dates);
  end

end
