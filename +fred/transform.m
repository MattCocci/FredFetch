function [data] = transform(data, tf, frequency)

  %% Helper functions

    % Inline if
    iif = @(varargin) varargin{2*find([varargin{1:2:end}], 1, 'first')}();

    % For indexing: If x is a string (which happens whn you download a
    % single series); otherwise, x is a cell, so return x{idx}; might
    % want to change output so series, frequency, units, always returns
    % cells
    idx = @(x,idx) iif(ischar(x), x, true, @() x{idx});
    if ischar(tf), tf = {tf}; end


  %% Handle the different types of X data structures that might come in

  % If X is just an array, not a data struct from one of the programs
  if isnumeric
    Nseries = size(data,2);
    for n = 1:Nseries
      keyboard
      data(:,n) = fred.transform_(data(:,n), tf{n}, idx(frequency,n));
    end

  elseif isstruct(data)

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
          if valid
            data(n).units = tf{n};
          end
        elseif ~strcmp(data(n).units, tf{n})
          warning(sprintf('Cannot go from %s to %s units', data(n).units, tf{n}))
        end
      end

    else % You are working with a merged dataset with possibly mixed frequencies
      Nseries = size(data.value,2);
      if length(tf) ~= Nseries
        error('Size of transformation array not equal to number of series in data.value matrix.')
      end

      % Loop over series and make the transformation
      units = data.units;
      if ischar(units), units = {units}; end
      for n = 1:Nseries
        % Only transform if going from lin to a pct change or diff
        if strcmp(idx(units,n), 'lin') && ~strcmp(tf{n}, 'lin')
          notNaN = ~isnan(data.value(:,n));
          [data.value(notNaN,n), valid] = fred.transform_(data.value(notNaN,n), tf{n}, idx(data.frequency,n));

          if valid
            if ischar(data.units)
              data.units = tf{n};
            else
              data.units{n} = tf{n};
            end
          end
        elseif ~strcmp(data(n).units, tf{n})
          warning(sprintf('Cannot go from %s to %s units', data(n).units, tf{n}))
        end
      end
    end

  else
    error('I don''t know how to transform that')
  end

end
