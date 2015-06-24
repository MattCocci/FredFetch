function [opt, toPass] = parseVarargin_(varargin)
% PARSE_VARARGIN - Check for various flags in varargin and return stuff
%                  to pass as additional options to FRED API
%
% [PAR, PSEUDO, VARAGOUT] = parse_varargin(VARARGIN) will parse the
% varargin and check for arguments of type boolean or logical, which
% would follow a string denoting either 'parallel' (to download series
% in parallel) or 'pseudo' (to construct pseudo vintages).
%
% The rest of varargin should just be strings that will be passed along
% as additional options to the FRED API. They are returned as VARARGOUT
% so you can use them (without the par and pseudo flags)

  %% toDataset option

    % If the first entry is a straight number, no options, it represents
    % "toDataset" flag
    opt.toDataset = 1;
    if ~isempty(varargin) && isnumeric(varargin{1})
      opt.toDataset = varargin{1};
      varargin = varargin(2:end);
    end


  %% Now check for parallel and pseudo-vintage flags

    opt.parworkers = 0; opt.pseudo = 0;

    bool_inds = find(cellfun(@(arg) isnumeric(arg) || islogical(arg), varargin));
    if isempty(bool_inds)
      toPass = varargin;
    else
      keys = varargin(bool_inds - 1);
      vals = [varargin{bool_inds}];

      par_ind = find(strcmp(keys, 'parworkers'));
      if ~isempty(par_ind)
        opt.parworkers = vals(par_ind);
      end

      pseudo_ind = find(strcmp(keys, 'pseudo'));
      if ~isempty(pseudo_ind)
        opt.pseudo = vals(pseudo_ind);
      end

      % Return varargin, with the parallel and pseudo shit stripped out
      toPass = varargin(setdiff(1:length(varargin), [bool_inds bool_inds-1]));
    end

end
