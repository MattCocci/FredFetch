function [outdate] = dtstr(indate)

  fred_fmt = 'yyyy-mm-dd';

  if isnumeric(indate)
    outdate = arrayfun(@(in) datestr(in, fred_fmt), indate, 'un', 0);
  else
    outdate = indate;
  end

end
