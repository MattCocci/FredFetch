% OVERVIEW - FredPullFcn.m
%
% This function is called by Main.m or can be used by another script to
% initiate a Fred pull.
%
% Required Arguments:
% - api_file      txt file with the api key from the Fred website
% - dpath         Data path -- where the pulled series will be saved
% - lgd           Legend structure as from read_legend.m
% - parworkers    Number of parallel workers. Set to 0 if you want to
%                   run sequentially or if you don't have a parallel
%                   license
% - path_dep      Path dependencies -- cell array where the elements are
%                   paths to functions you need to pull data from Fred.
%                   Most important is jsonlab. Left as an argument
%                   rather than hardcoded into downstream functions for
%                   flexibility. Also, if running in parallel, you need
%                   to provide the path dependencies to the job.
% - vint_date     Vintage dates(s). This argument can be
%                     - A file with multiple dates, each on a separate line.
%                     - A cell array of dates.
%                     - A single data
%                   In each case, this function will detect the correct thing to
%                   do and either pull many dates or just the one passed.
% - remerge_only  An indicator whether we just want to re-merge the data
%                   (1) or if want to actually pull/repull data. Usually
%                   want this to be 0, but can set to 1 if you want to
%                   simply change a transformation being done and then
%                   remerge everything into vintdata structures
function [ pullstats ] = FredPullFcn(api_file, dpath, lgd, parworkers, path_dep, vint_dates, remerge_only)

  max_attempt = 5;

  tic;

  %% Set up the api

    % Get api
    api = textread(api_file, '%s');
    api = api{:};

  %% Set up the vintage dates

    % If "vint_date" is a file (and not a cell), read it for multiple vints and
    % get it in a cell
    if ~iscell(vint_dates) && exist(vint_dates, 'file')
      f = fopen(vint_date, 'r');
      vint_dates = textscan(f, '%s');
      fclose(f);
      vint_dates = vint_dates{1};
    end

    % Convert vintnames to a datenum
    vint_strs  = vint_dates;
    vint_dates = cellfun(@datenum, vint_dates);

    % Get parameters
    nvint   = length(vint_dates);
    nseries = length(lgd.code);


  %% Set up the directories to hold the output (named for the vint dates)

    save_dirs = ...
      arrayfun(@(d) sprintf('%s/%s/', dpath, datestr(d, 'yyyy-mm-dd')), vint_dates, 'un', 0);
    for v = 1:length(vint_dates)
      if ~exist(save_dirs{v}, 'dir')
        mkdir(save_dirs{v});
      end
      if ~exist([save_dirs{v}, 'IndividualSeries'], 'dir')
        mkdir([save_dirs{v}, 'IndividualSeries']);
      end
    end


  %% Fetch and save

    % Sort so that low_frequency are at the end (this is because parfor
    % must loop over indices that are consecutive; we use parfor for the
    % low frequency variables, so let's put them all together at the
    % beginning)
    lf_labels = {'q', 'm'};
    low_frequency = logical(cellfun(@(f) sum(strcmp(f, lf_labels)), lgd.frequency));
    flds = fieldnames(lgd);
    for f = 1:length(flds)
      if length(lgd.(flds{f})) == nseries
        lgd.(flds{f}) = [lgd.(flds{f})(low_frequency);...
                        lgd.(flds{f})(~low_frequency)];
      end
    end
    low_frequency = cellfun(@(f) sum(strcmp(f, lf_labels)), lgd.frequency);


    % For tracking success/downloading problems
    pseudo_vints  = cell(nseries, nvint);
    pullstats     = cell(nseries,1);
    lf_success    = nan(nseries, nvint);


    %% (Maybe) open up a parallel pool
    if parworkers && ~remerge_only
      poolsetup(min(parworkers, nseries), path_dep)
        % path_dep to Make sure the jsonlab functions and other path
        % dependencies are available to the workers
    end


    %% If you want to repull
    if ~remerge_only

      %% Parallel Data Pull: if pulling more than one vintage given
      if nseries > 1 && parworkers

        % Fetch low frequency series (monthly or less)
        parfor s = find(low_frequency)'
          fprintf('Fetching series: %s...\n', lgd.code{s});
          [pseudo_vints(s,:), pullstats{s}] = ...
            fetch_single_multiplevint(api, dpath, path_dep, lgd.code{s}, lgd.frequency{s}, ...
                                      vint_dates, max_attempt);
        end
        % Fetch high frequency series (weekly or more frequent)
        parfor s = find(~low_frequency')
          fprintf('Fetching series: %s...\n', lgd.code{s});
          for v = 1:nvint
            [pseudo_vints{s,v}, lf_success(s,v)] = ...
              fetch_single_singlevint(api, lgd.code{s}, ...
                sprintf('%s/IndividualSeries/%s_m', save_dirs{v}, lgd.code{s}), ...
                'm', vint_dates(v), path_dep);
          end
        end

      %% If doing 1 vint only OR if running many vints sequentially
      else

        % Fetch low frequency series (monthly or less)
        for s = find(low_frequency)'
          fprintf('Fetching series: %s...\n', lgd.code{s});
          [pseudo_vints(s,:), pullstats{s}] = ...
            fetch_single_multiplevint(api, dpath, path_dep, lgd.code{s}, lgd.frequency{s}, ...
                                      vint_dates, max_attempt);
        end

        % Fetch high frequency series (weekly or more frequent)
        for s = find(~low_frequency')
          fprintf('Fetching series: %s...\n', lgd.code{s});
          for v = 1:nvint
            [pseudo_vints{s,v}, lf_success(s,v)] = ...
              fetch_single_singlevint(api, lgd.code{s}, ...
                sprintf('%s/IndividualSeries/%s_m', save_dirs{v}, lgd.code{s}), ...
                'm', vint_dates(v), path_dep);
          end
        end
      end
    end

    %% Make vintage data structures and write
    vintdatas = cell(nvint,1);
    for v = 1:nvint
      fprintf('Creating vintage data structures for: %s\n', vint_strs{v});

      if remerge_only
        old = load(sprintf('%s/vintdata%s.mat', save_dirs{v}, vint_strs{v}));
        for s = 1:nseries
          p_ind = find(strcmp(old.vintdata.series, lgd.code{s}));
          if ~isempty(p_ind)
            pseudo_vints(s,v) = old.vintdata.pseudinfo(p_ind);
          end
        end
      end

      vintdatas{v} = align_vintdata(save_dirs{v}, lgd, pseudo_vints(:,v), vint_strs{v});
    end

    %% Loop through and write vintdata
    for v = 1:nvint
      vintdata = vintdatas{v};
      save(sprintf('%s/vintdata%s.mat', save_dirs{v}, vint_strs{v}), 'vintdata');
    end

    %% Pack the high-frequency pull information in
    for s = find(~low_frequency)'
      pullstats{s} = lf_success(s,:);
    end


  %% Report results

    if parworkers && ~remerge_only
      %delete(poolobj)
    end
    fprintf('\nDownloading finished. Elapsed time: %9.1f Minutes\n', toc/60);

end

