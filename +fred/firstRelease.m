function [returned] = firstRelease(series, varargin)

  [opt, toPass] = fred.parseUserVarargin_({'parworkers', 'pseudo'}, varargin{:});
  returned = fred.dispatch_(0, opt.parworkers, @fred.firstRelease_, series, toPass{:});

end
