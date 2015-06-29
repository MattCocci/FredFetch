function [opt] = GlobalOptions()

  opt.max_attempt = 3;
  opt.first_realtime = '1776-07-04';
  opt.last_realtime  = '9999-12-31';

  % Whether leading and trailing NaNs on a data matrix should be trimmed
  % when possible
  opt.trimLeadTrailNaN = 1;


  try
    api = textread(['api.txt'], '%s');
    opt.api = api{:};
  catch
    error('Please supply an API Key in +fred/GlobalOptions.m')
  end

end
