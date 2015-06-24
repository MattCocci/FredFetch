%% ReadFredData.m
%
% Wrapper for ReadFredURL tailored to download vintage data and
% associated series information.
%
function [returned, success] = ReadFredData_(varargin)

  %% Try to grab the data
  flds = {'info'; 'obs'};
  for n = 1:length(flds)
    [query.(flds{n}), success] = fred.ReadFredURL_(fred.MakeFredURL_(flds{n}, varargin{:}), 1);

    % Check that there were no errors
    if ~success
      returned = query.(flds{n});
      return
    end
  end

  %% If it made it through without errors
  returned = query;

end

