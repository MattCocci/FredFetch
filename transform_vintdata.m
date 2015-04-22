% OVERVIEW - transform.m
%
% This function takes in a vintdata structure produced by align_vintdata.m and
% applies the transformations. It also changes vintdata.transf_ind (an
% indicator for whether the series are transformed) to 1.
%
% This calls transform.m which does the actual trnsformations
function [ vintdata, varargout ] = transform_vintdata(vintdata)

  old = vintdata;

  for s = 1:length(vintdata.series)

    switch vintdata.frqcy{s}
    case 'm'
      lag_by = 1;
    case 'q'
      lag_by = 3;
    end
    vintdata.values(:,s) = transform(vintdata.values(:,s), ...
                            vintdata.transf{s}, lag_by);
  end

  vintdata.transf_ind = 1;
  if nargout > 1
    varargout{1} = old;
  end

end
