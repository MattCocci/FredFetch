function [X] = transform(X, transform, frequency)

  % Define series that are annualized and those that are one period
  % changes
  onePd  = {'chg', 'pch', 'cch'};
  annual = {'ch1', 'pc1', 'pca', 'cca'};

  if any(strcmp(transform, onePd))
    Npd = 1;

  elseif any(strcmp(transform, annual))
    % Set the number of periods per year to use when computing percent
    % changes and differences and such
    switch upper(frequency)
      case 'Q'
        pdsPerYear = 4;
      case 'M'
        pdsPerYear = 12;
      case 'W'
        pdsPerYear = 52;
      case 'D'
        pdsPerYear = 365;
      otherwise
        pdsPerYear = [];
    end
    if any(strcmp(transform, annual)) && isempty(pdsPerYear)
      error(['Periods per year not defined for frquency of type ' frqcy]);
    else
      Npd = pdsPerYear;
    end
  end

  % Define the transformation to be made
  Xlead     = X(2:end,:);
  Xlag      = X(1:end-1,:);
  pad       = nan(1,size(X,2));
  if any(strcmp(transform, annual))
    Xlead_Npd = X(Npd+1:end,:);
    Xlag_Npd  = X(1:end-Npd,:);
    pad_Npd   = nan(Npd,size(X,2));
  end


  switch transform
    case 'chg'
      X = [pad; Xlead - Xlag];

    case 'ch1'
      X = [pad_Npd; Xlead_Npd - Xlag_Npd];

    case 'pch'
      X = [pad; 100*((Xlead ./ Xlag)-1)];

    case 'pc1'
      X = [pad_Npd; 100*((Xlead_Npd ./ Xlag_Npd)-1)];

    case 'pca'
      X = [pad; 100*(((Xlead ./ Xlag).^4)-1)];

    case 'cch'
      X = [pad; 100*(log(Xlead)-log(Xlag))];

    case 'cca'
      X = [pad; 400*(log(Xlead)-log(Xlag))];

    case 'log'
      X = log(X);

  end

end
