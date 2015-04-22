% OVERVIEW - transform.m
function [ Y ] = transform(X, tform, lag_by)

  [T, N] = size(X);

  switch tform
    case '.'
      % No transformation
      Y = X;

    case 'diff'
      Y = [nan(lag_by,N); ...
           [X((lag_by+1):T,:) - X(1:T-lag_by,:)]];

    case 'pctchg'
      Y = 100*[nan(lag_by,N); ...
               [log(X((lag_by+1):T,:)) - log(X(1:T-lag_by,:))]];

    otherwise
      error(sprintf('Transformation %s undefined', tform));
  end


end
