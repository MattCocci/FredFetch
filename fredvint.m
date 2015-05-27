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
function [vintdata] = fredvint(opt, series, vintdate, obs_start, obs_end)


  if ~isfield(opt, 'verbose') || opt.verbose
    fprintf('\nFetching %s...\n', series);
    opt
  end


  %% Grab the data
  try
    info = loadjson(urlread(url.info));
    data = loadjson(urlread(url.data));
  catch
    opt.max_attempt = opt.max_attempt - 1;
    if opt.max_attempt
      vintdata = SeriesVintage(api, series, frequency, opt);
    end
    return
  end

  %% Parse the data
  vintdata.info = info.seriess{:};
  data = vertcat(data.observations{:});
  nobs = length(data);
  vintdata.obsdates = nan(nobs,1);
  vintdata.values   = nan(nobs,1);
  for t = 1:nobs
    vintdata.obsdates(t) = datenum(data(t).date, 'yyyy-mm-dd');
    val = str2num(data(t).value);
    if ~isempty(val)
      vintdata.values(t) = val;
    end
  end


  %% Maybe save the data
  if ~isempty(opt.saving)
    save(opt.saving, 'vintdata');
  end

end
