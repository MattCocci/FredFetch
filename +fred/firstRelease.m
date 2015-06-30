function [returned] = firstRelease(series, varargin)

  [opt, toPass] = parseVarargin({'parworkers', 'pseudo'}, varargin{:});
  returned = dispatch(0, opt.parworkers, @firstRelease, series, toPass{:});

end
