function [data] = latest(series, varargin)

  opt = fred.parseVarargin_({'parworkers', 'pseudo'}, varargin{:});
  data = fred.dispatch_(opt.toDataset, opt.parworkers, @fred.latest_, series);

end
