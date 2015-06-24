function [returned] = process_typical_call(fcn, series, varargin)


  % Dispatch the call to different function depending upon whether one
  % or multiple series are specified
  if isstr(series)
    returned = feval(fcn, series, varargin{:});

  elseif length(series) == 1
    returned = feval(fcn, series{1}, varargin{:});

  else
    returned = fred.multiple_(fcn, series, varargin{:});
  end

end
