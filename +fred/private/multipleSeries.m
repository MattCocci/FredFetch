function [data] = multipleSeries(toDatasetByVint, parworkers, dl_fcn, series, varargin)


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
    if ~toDatasetByVint
      data = vertcat(individual{:});
      for n = 1:length(series)
        data(n).series = upper(series{n});
      end

    % Reshape into array structure where each element is a different
    % vintage data and the data for different series are merged into a
    % single data matrix of possibly mixed frequency
    else

      data = fred.reshapeByVint(individual);
    end


  %% Shut down parpool
  if parworkers
    delete(poolobj);
  end

end
