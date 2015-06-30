function [vints, success] = getvints(series)

  try
    vints = dispatch(0, 0, @getvints, series);
    success = 1;
  catch
    vints.series = series;
    vints.vintdates = [];
    success = 0;
  end

end
