function [vints, success] = getvints(series)

  try
    vints = fred.dispatch_(0, 0, @fred.getvints_, series);
    success = 1;
  catch
    vints.series = series;
    vints.vintdates = [];
    success = 0;
  end

end
