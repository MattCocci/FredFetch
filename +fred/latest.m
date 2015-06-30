function [data] = latest(series, varargin)

  opt = parseVarargin({'parworkers', 'pseudo', 'units'}, varargin{:});
  data = dispatch(opt.toDatasetByVint, opt.parworkers, @latest, series);

  % Maybe transform
  if iscell(opt.units) | ischar(opt.units)
    data = fred.transform(data, opt.units);
  end

end
