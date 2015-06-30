function [dataByVint] = reshapeByVint(individualBySeries)
% reshapeByVint - Take a cell array where each element is a structure
%                 with a different *series* (over possibly different
%                 vintage dates along columns of the "value" field) and
%                 reshape it into a structure array with different
%                 *vintages* in each element of the array and different
%                 series along the columns of the "value" field.
%
% Effectively, this puts merged, possibly-mixed frequency *vintage
% datasets* in each element of the returned structure array, which is
% maybe more useful than one series per element.


  opt = fred.GlobalOptions();

  % Make sure the individualbyseries argument is an array structure; if
  % it's a cell of structs, stack them
  if iscell(individualBySeries)
    dataBySeries = vertcat(individualBySeries{:});
  else
    dataBySeries = individualBySeries;
  end
  Nseries = length(dataBySeries);

  % Vintages
  vints = unique([dataBySeries.realtime]);
  Nvint = length(vints);

  % Loop over vintages and build up the dataByVint array struct
  for v = 1:Nvint

    % Current vintage date
    vint = vints(v);

    % Add info about the series
    carry_over = {'info', 'series', 'frequency', 'units'};
    for n = 1:length(carry_over)
      dataByVint(v).(carry_over{n}) = {dataBySeries.(carry_over{n})}';
    end

    % Fill in pseudo across different series for this vintage
    vintMatchInd = cell(Nseries,1);
    dataByVint(v).pseudo = nan(Nseries,1);
    for n = 1:Nseries

      % For series n, find the index among its different vintage dates
      % that matches vint; store it
      vintMatchInd{n} = find(vint == dataBySeries(n).realtime);

      % If that's not empty, store pseudo info
      if ~isempty(vintMatchInd{n})
        dataByVint(v).pseudo(n) = dataBySeries(n).pseudo(vintMatchInd{n});
      end
    end

    % Add the vintage date
    dataByVint(v).realtime = vint;

    % Fill in the obs dates
    dataByVint(v).date = sort(unique(vertcat(dataBySeries.date)));

    % Fill in the data, and data, accounting for mixed frequency
    dataByVint(v).value = nan(length(dataByVint(v).date), Nseries);
    for n = 1:Nseries
      if ~isempty(vintMatchInd{n})
        insert = arrayfun(@(t) find(dataByVint(v).date==t), dataBySeries(n).date);
        dataByVint(v).value(insert,n) = dataBySeries(n).value(:,vintMatchInd{n});
      end
    end

    % Trim the leading and trailing nans
    if opt.trimLeadTrailNaN
      [dataByVint(v).value, rem] = fred.RemLeadTrailNaN_(dataByVint(v).value, 'all');
      dataByVint(v).date = dataByVint(v).date(~rem);
    end

  end

end
