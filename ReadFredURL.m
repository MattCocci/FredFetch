function [returned, success] = ReadFredURL(url, max_attempt)

  %% Get max attempt if not set
  if ~exist('max_attempt', 'var')
    opt = GlobalOptions();
    max_attempt = opt.max_attempt;
  end

  %% Try max_attempt times to download; if error, return error
  try
    returned = loadjson(urlread(url));
    success  = 1;
  catch
    if max_attempt - 1
      [returned, success] = ReadFredURL(url, max_attempt-1);
      return
    else
      returned = lasterror();
      returned.url = url;
      success  = 0;
    end
  end

end
