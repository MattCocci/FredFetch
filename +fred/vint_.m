function [vintdata] = vint_(series, vint_date, pseudo, varargin)


  %% Try to grab the data
  [query, success] = fred.ReadFredData_('series_id', series, 'realtime_start', vint_date, 'realtime_end', vint_date, varargin{:});


  %% Return on errors
  if ~success

    % Maybe construct a pseudo vintage
    if pseudo
      vintdata = fred.vintsFromAll_(series, vint_date, 1, varargin{:});
    else
      vintdata.info      = query;
      vintdata.series    = upper(series);
      vintdata.frequency = '';
      vintdata.units     = '';
      vintdata.pseudo    = [];
      vintdata.realtime  = [];
      vintdata.date      = [];
      vintdata.value     = [];
    end

    return
  end

  %% Parse the data
  vintdata.info      = query.info.seriess{:};
  vintdata.series    = upper(series);
  vintdata.frequency = query.info.seriess{end}.frequency_short;
  vintdata.units     = query.obs.units;
  vintdata.pseudo    = NaN;

  obs               = vertcat(query.obs.observations{:});
  Nobs              = length(obs);
  vintdata.realtime = fred.dtnum(vint_date);
  vintdata.date     = nan(Nobs,1);
  vintdata.value    = nan(Nobs,1);
  for t = 1:Nobs
    vintdata.date(t) = datenum(obs(t).date, 'yyyy-mm-dd');
    val = str2num(obs(t).value);
    if ~isempty(val)
      vintdata.value(t) = val;
    end
  end

end
