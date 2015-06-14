function [vintdata] = vint_single(series, vint_date, verbose_errors, varargin)

  %% Try to grab the data
  [query, success] = ReadFredData(verbose_errors, 'series_id', series, 'realtime_start', vint_date, 'realtime_end', vint_date, varargin{:});

  %% Return on errors
  if ~success
    vintdata.info  = query;
    vintdata.date  = [];
    vintdata.value = [];
    return
  end

  %% Parse the data
  vintdata.info  = query.info.seriess{:};
  obs            = vertcat(query.obs.observations{:});
  Nobs           = length(obs);
  vintdata.date  = nan(Nobs,1);
  vintdata.value = nan(Nobs,1);
  for t = 1:Nobs
    vintdata.date(t) = datenum(obs(t).date, 'yyyy-mm-dd');
    val = str2num(obs(t).value);
    if ~isempty(val)
      vintdata.value(t) = val;
    end
  end

end
