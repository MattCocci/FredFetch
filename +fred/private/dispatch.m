function [vintdata] = dispatch(toDatasetByVint, parworkers, fcn, series, varargin)


  if iscell(series) && (length(series) == 1)
    series = series{1};
  end
  if isstr(series)
    vintdata = feval(fcn, series, varargin{:});
  else
    vintdata = multipleSeries(toDatasetByVint, parworkers, fcn, series, varargin{:});
  end


end
