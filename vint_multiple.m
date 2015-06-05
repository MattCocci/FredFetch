function [vintdata] = vint_multiple(series, vint_date, varargin)

  Nseries = length(series);
  individual = repmat(struct(), Nseries, 1);
  for s = 1:Nseries
    individual(s) = vint_single(series{s}, vint_date, varargin{:});
  end

end

