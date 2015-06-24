function [parworkers, pseudo, varargout] = check_par_pseudo(varargin)
% PARSE_VARARGIN - Check for parallel and pseudo-vintage options
%
% [PAR, PSEUDO, VARAGOUT] = check_par_pseudo(VARARGIN) will parse the
% varargin and check for arguments of type boolean or logical, which
% would follow a string denoting either 'parallel' (to download series
% in parallel) or 'pseudo' (to construct pseudo vintages).
%
% The rest of varargin should just be strings that will be passed along
% as additional options to the FRED API. They are returned as VARARGOUT
% so you can use them (without the par and pseudo flags)

  par = 0; pseudo = 0;

  bool_inds = find(cellfun(@(arg) isnumeric(arg) || islogical(arg), varargin));
  if ~isempty(bool_inds)
    keys = varargin(bool_inds - 1);
    vals = [varargin{bool_inds}];

    par_ind = find(strcmp(keys, 'parworkers'));
    if ~isempty(par_ind)
      parworkers = vals(par_ind);
    end

    pseudo_ind = find(strcmp(keys, 'pseudo'));
    if ~isempty(pseudo_ind)
      par = vals(pseudo_ind);
    end

    % Return varargin, with the parallel and pseudo shit stripped out
    varargout = varargin(setdiff(1:length(varargin), [bool_inds bool_inds-1]));
  end

end
