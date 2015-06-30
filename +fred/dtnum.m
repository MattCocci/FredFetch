function [outdate] = dtnum(indate)
% FRED.DTNUM datenum for arguments of type char or cell
%  OUTDATE = FRED.DTNUM(INDATE) returns datenum(s) for each date in INDATE.

  if ischar(indate)
    indate = {indate};
  end
  if iscell(indate)
    outdate = cellfun(@(in) datenum(in), indate);
  else
    outdate = indate;
  end

end
