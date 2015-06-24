function [vintdata] = dispatch(toDataset, parworkers, fcn, series, varargin)


  if iscell(series) && (length(series) == 1)
    series = series{1};
  end
  if isstr(series)
    vintdata = feval(fcn, series, varargin{:});
  else
    vintdata = fred.multipleSeries_(toDataset, parworkers, fcn, series, varargin{:});
  end


end
