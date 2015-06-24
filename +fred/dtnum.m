function [outdate] = dtnum(indate)

  fred_fmt = 'yyyy-mm-dd';

  if ischar(indate)
    indate = {indate};
  end
  if iscell(indate)
    outdate = cellfun(@(in) datenum(in, fred_fmt), indate);
  else
    outdate = indate;
  end

end
