function [vintdata] = vint(series, vint_date, varargin)

  if datenum(vint_date) < datenum(1991,1,1)
    warning('Early vintage date; data might not exist, error likely.')
  end

  %% Grab the data
  flds = {'info'; 'obs'};
  for f = 1:length(flds)
    data.(flds{f}) = ReadFredURL(MakeFredURL(flds{f}, 'series_id', series, 'realtime_start', vint_date, 'realtime_end', vint_date, varargin{:}));
  end

  %% Check that it downloaded
  if isfield(data.obs, 'url')
    error(sprintf('Could not download data using link\n\n\t%s\n', data.obs.url))
  end
  if isfield(data.info, 'url')
    error(sprintf('Could not retrieve series info using link\n\n\t%s\n', data.info.url))
  end

  %% Parse the data
  vintdata.info  = data.info.seriess{:};
  data.obs       = vertcat(data.obs.observations{:});
  nobs           = length(data.obs);
  vintdata.date  = nan(nobs,1);
  vintdata.value = nan(nobs,1);
  for t = 1:nobs
    vintdata.date(t) = datenum(data.obs(t).date, 'yyyy-mm-dd');
    val = str2num(data.obs(t).value);
    if ~isempty(val)
      vintdata.value(t) = val;
    end
  end

end
