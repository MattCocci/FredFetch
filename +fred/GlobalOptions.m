function [opt] = GlobalOptions()

  opt.max_attempt = 3;
  opt.first_realtime = '1776-07-04';
  opt.last_realtime  = '9999-12-31';
  api = textread(['api.txt'], '%s');
  opt.api = api{:};

end
