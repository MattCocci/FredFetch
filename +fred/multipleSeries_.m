function [data] = multipleSeries_(toDataset, parworkers, dl_fcn, series, varargin)


  %% Maybe open up parallel pool
  if parworkers
    poolcheck = gcp('nocreate')
    if isempty(poolcheck)
      poolobj = parpool(min([parworkers length(series)]))
    else
      poolobj = poolcheck;
    end
  end


  %% Download the series individually using dl_fcn

    Nseries    = length(series);
    individual = cell(Nseries, 1);
    if parworkers
      parfor s = 1:Nseries
        individual{s} = feval(dl_fcn, series{s}, varargin{:});
      end
    else
      for s = 1:Nseries
        individual{s} = feval(dl_fcn, series{s}, varargin{:});
      end
    end


  %% Merge or Join the downloaded objects

    % Just stack the returned arrays
    if ~toDataset
      data = vertcat(individual{:});
      for n = 1:length(series)
        data(n).series = upper(series{n});
      end

    else % Merge into data matrix

      not_empty = find(cellfun(@(s) ~isfield(s.info, 'url'), individual));

      % Add info
      carry_over = {'info', 'series', 'frequency_short'};
      for n = 1:length(carry_over)
        data.(carry_over{n}) = cellfun(@(s) s.(carry_over{n}), individual, 'un', 0);
      end

      % Add realtime dates; collapse to 1 if all the same
      data.realtime = nan(Nseries,1);
      data.realtime = cellfun(@(s) s.realtime, individual(not_empty));
      if length(unique(data.realtime)) == 1
        data.realtime = unique(data.realtime);
      end

      % Align the vintage datasets
      alldates      = cellfun(@(s) s.date, individual(not_empty), 'un', 0);
      data.date     = sort(unique(vertcat(alldates{:})));

      data.value = nan(length(data.date), Nseries);
      for n = 1:length(not_empty)
        s = not_empty(n);
        insert = arrayfun(@(t) find(data.date==t), individual{s}.date);
        data.value(insert,s) = individual{s}.value;
      end
    end


  %% Shut down parpool
  if parworkers
    delete(poolobj);
  end

end
