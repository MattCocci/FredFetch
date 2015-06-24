%% latest.m
%
%
function [data] = latest(series, varargin)

  opt = fred.parseVarargin_(varargin{:});
  data = fred.dispatch_(opt.toDataset, opt.parworkers, @fred.latest_, series);

end
