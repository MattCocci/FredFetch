function [vintdata] = vint_multiple(series, vint_date, varargin)

  % Download the series individually
  Nseries = length(series);
  individual = cell(Nseries, 1);
  for s = 1:Nseries
    individual{s} = vint_single(0, series{s}, vint_date, varargin{:});
  end
  not_empty = find(cellfun(@(s) ~isfield(s.info, 'url'), individual));

  % Add info
  vintdata.info      = cellfun(@(s) s.info, individual, 'un', 0);
  vintdata.series    = series;
  vintdata.frequency = repmat({''},Nseries,1);
  vintdata.frequency(not_empty) = cellfun(@(s) s.info.frequency_short, individual(not_empty), 'un', 0);

  % Align the vintage datasets
  alldates       = cellfun(@(s) s.date, individual(not_empty), 'un', 0);
  vintdata.date  = sort(unique(vertcat(alldates{:})));
  vintdata.value = nan(length(vintdata.date), Nseries);
  for n = 1:length(not_empty)
    s = not_empty(n);
    insert = arrayfun(@(t) find(vintdata.date==t), individual{s}.date);
    vintdata.value(insert,s) = individual{s}.value;
  end

end
