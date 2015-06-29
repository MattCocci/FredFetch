function [returned] = getvints_(series)

  %% Construct a query string and to pull the release dates
  opt = fred.GlobalOptions();
  url = sprintf([...
    'http://api.stlouisfed.org/fred/series/vintagedates?'...
    'series_id=%s' ...
    '&api_key=%s' ...
    '&file_type=json'],...
    series,...
    opt.api);

  try
    vintdates = jsonlab.loadjson(urlread(url));
    returned.series    = series;
    returned.vintdates = fred.dtnum(vintdates.vintage_dates)';
  catch
    returned.series    = series;
    returned.vintdates = [];
  end


end
