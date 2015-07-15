function [rlsdata] = firstRelease_(series, varargin)

  %% Grab the series

    % If 'units' is in the varargin, take that out and handle later bc
    % there are issues pulling that from FRED
    units_idx = find(strcmp(varargin, 'units'));
    if ~isempty(units_idx)
      toPass = varargin([1:units_idx-1 units_idx+2:end]);
      units  = varargin{units_idx+1};
      if iscell(units)
        units = units{:};
      end
    else
      toPass = varargin;
      units  = 'lin';
    end

    % Download
    vintdata = fred.vintall(series, toPass{:});
    if isempty(vintdata.value)
      rlsdata.info      = vintdata.info;
      rlsdata.series    = vintdata.series;
      rlsdata.frequency = '';
      rlsdata.units     = '';
      rlsdata.date      = [];
      rlsdata.released  = [];
      rlsdata.value     = [];
      return
    end

    % Transform
    Nvint = length(vintdata.realtime);
    [vintdata.value, tfValid] = fred.transform_(vintdata.value, units, vintdata.info(end).frequency_short);


  %% Replace all the values with only the first releases

    rlsdata.info      = vintdata.info;
    rlsdata.series    = vintdata.series;
    rlsdata.frequency = vintdata.info(end).frequency_short;
    if tfValid
      rlsdata.units = units;
    else
      rlsdata.units = 'lin';
    end
    rlsdata.date      = vintdata.date;

    [Nobs,Nvint] = size(vintdata.value);
    rlsdata.released = nan(Nobs,1);
    rlsdata.value    = nan(Nobs,1);
    keepRow = zeros(Nobs,1);
    for t = 1:Nobs
      col = find(~isnan(vintdata.value(t,:)),1);
      if ~isempty(col)
        rlsdata.value(t)    = vintdata.value(t,col);
        rlsdata.released(t) = vintdata.realtime(col);
        keepRow(t)  = 1;
      end
    end
    keepRow = find(keepRow);
    rlsdata.date     = rlsdata.date(keepRow);
    rlsdata.value    = rlsdata.value(keepRow);
    rlsdata.released = rlsdata.released(keepRow);

  %% Store revised final too

    % Grab the latest
    latest = fred.latest(series, 'units', units);

    % For each obs, store the revised final
    Nobs = length(rlsdata.date);
    rlsdata.latest = nan(Nobs,1);
    for t = 1:Nobs
      indInLatest = find(rlsdata.date(t) == latest.date);
      if ~isempty(indInLatest)
        rlsdata.latest(t) = latest.value(indInLatest);
      end
    end

end

