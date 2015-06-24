function [returned] = vints_fromAll(series, vintdates, pseudo, varargin)

  % See whether you'll even need to use pseudo vintages
  if pseudo
    available = fred.getvints_single(series);
    if fred.dtnum(vintdates(1)) >= available.vintdates(1)
      pseudo = 0;
    end
  end

  % Pull all vintages from beginning to end of dates
  vintdates = fred.dtnum(vintdates);
  if pseudo
    start = '1776-07-04';
    stop  = '9999-12-31';
  else
    start = vintdates(1);
    stop  = vintdates(end);
  end

  vintall = fred.vintrange_single(series, start, stop, varargin{:});

  if pseudo
    publag  = fred.compute_publag(vintall.date, vintall.realtime, vintall.value);
  end

  % Select data column for each given vintage date from the matrix of
  % all vintages
  transfer = {'info', 'series', 'date'};
  for n = 1:length(transfer)
    returned.(transfer{n}) = vintall.(transfer{n});
  end
  returned.realtime = vintdates;

  Nobs  = length(returned.date);
  Nvint = length(returned.realtime);
  returned.value = nan(Nobs, Nvint);
  for n = 1:Nvint
    vint = returned.realtime(n);
    col = find(vint >= vintall.realtime, 1, 'last');
    if ~isempty(col)
      returned.value(:,n) = vintall.value(:,col);
    elseif pseudo
      % What would have been available: Anything >= publag days after
      % the observation date
      available = ((vint-vintall.date) >= publag.median);
      returned.value(find(available),n) = vintall.value(find(available),1);
    end
  end

end
