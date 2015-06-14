%% ReadFredData.m
%
% Wrapper for ReadFredURL tailored to download vintage data and
% associated series information.
%
function [returned, success] = ReadFredData(verbose_errors, varargin)

  %% Try to grab the data
  flds = {'info'; 'obs'};
  for n = 1:length(flds)
    [query.(flds{n}), success] = ReadFredURL(MakeFredURL(flds{n}, varargin{:}));

    % Check that there were no errors
    if ~success
      if verbose_errors
        fprintf('Error: Could not complete query using link\n\n\t%s\n', query.(flds{n}).url)
      end
      returned = query.(flds{n});
      return
    end
  end

  %% If it made it through without errors
  returned = query;

end

