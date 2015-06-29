function [data] = transform(data, tf, frequency)

  %% Helper functions

    % Inline if
    iif = @(varargin) varargin{2*find([varargin{1:2:end}], 1, 'first')}();

    if ischar(tf), tf = {tf}; end
    if exist('frequency', 'var')
      if ischar(frequency), frequency = {frequency}; end
    end


  %% Handle the different types of X data structures that might come in

  % If X is just an array, not a data struct from one of the programs
  if isstruct(data)

    % If there are multiple series stacked in an array struct.  Each
    % element of the struct array should have data on the same series in
    % "value" (whether value is a column vector or a matrix of the
    % series at different vintage dates).
    %
    % This if block operates on what you get back from calls to
    % fred.vint with multiple series *and* vintages or calls fred.vint
    % with toDataset = 0.
    if length(data) > 1

      Nseries = length(data);
      for n = 1:Nseries
        if strcmp(data(n).units, 'lin') && ~strcmp(tf{n}, 'lin')
          [data(n).value, valid] = fred.transform_(data(n).value, tf{n}, data(n).frequency);
          if valid,
            data(n).units = tf{n};
          end

        elseif ~strcmp(data(n).units, tf{n})
          warning(sprintf('Cannot go from %s to %s units', data(n).units, tf{n}))
        end
      end

    % Dataset is all the same series over multiple vintage dates
    elseif ischar(data.series)
      [data.value, valid] = fred.transform_(data.value, tf{:}, data.frequency);
      if valid
        data.units = tf{:};
      end

    % Dataset merges multiple series, possible frequency-mixing
    elseif iscell(data.series)

      % Loop over series and make the transformation
      Nseries = length(data.series);
      for n = 1:Nseries

        % Only transform if going from lin to a pct change or diff
        if strcmp(data.units{n}, 'lin') && ~strcmp(tf{n}, 'lin')
          notNaN = ~isnan(data.value(:,n));
          [data.value(notNaN,n), valid] = fred.transform_(data.value(notNaN,n), tf{n}, data.frequency{n});

          if valid
            data.units{n} = tf{n};
          end
        elseif ~strcmp(data.units, tf{n})
          warning(sprintf('Cannot go from %s to %s units', data.units, tf{n}))
        end
      end
    end


  elseif isnumeric(data)

    Nseries = size(data,2);
    for n = 1:Nseries
      data(:,n) = fred.transform_(data(:,n), tf{n}, frequency{n});
    end


  else
    error('I don''t know how to transform that')
  end

end
