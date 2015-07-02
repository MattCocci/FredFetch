function [vints, success] = getvints(series, max_attempt)

  if ~exist('max_attempt', 'var')
    opt = fred.GlobalOptions();
    max_attempt = opt.max_attempt;
  end

  try
    vints = fred.dispatch_(0, 0, @fred.getvints_, series);
    success = 1;
  catch
    if max_attempt - 1
      pause(3);
      [vints, success] = getvints(series, max_attempt-1);
      return
    else
      vints.series = series;
      vints.vintdates = [];
      success = 0;
    end
  end

end
