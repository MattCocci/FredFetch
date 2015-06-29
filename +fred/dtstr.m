function [outdate] = dtstr(indate)

  fred_fmt = 'yyyy-mm-dd';

  if isnumeric(indate)
    outdate = arrayfun(@(in) datestr(in, fred_fmt), indate, 'un', 0);
    if length(outdate) == 1
      outdate = outdate{1};
    end
  else
    outdate = indate;
  end

end
