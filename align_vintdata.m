% OVERVIEW - align_vintdata.m
%
% This file will take a folder of txt files for various series (likely with
% different frequencies) and merge them into a single dataset stored in an
% struct, accounting for mixed-frequency data and different starting/ending
% points. Will also move the files into a subfolder so as not to clutter the
% folder.
%
% IMPORTANT:
% - This function builds a dataset where observations are at the monthly
%   frequency.
% - For series whose native frequency is NOT monthly (like quarterly or annual
%   data), the data is spaced out with NaNs. For example, a 2013Q1 observation
%   will be matched to month March 2013 with NaNs in Jan and Feb.
% - To reiterate: Observations for lower-than-monthly-frequency series are
%   placed at the END OF THE PERIOD.
% - For daily or weekly data, FRED automatically does the aggregation to
%   monthly frequency, provided that you specify monthly in the url request
%   string.
%
% Required Arguments:
% - vint_dir      Directory where all of the saved series are stored (i.e. the
%                   ones produced by fetch_multiple_singlevint)
% - codes         Cell array of series codes that will be found in vint_dir
% - frequencies   Cell array with corresponding frequencies of the series
% - transforms    Cell array with corresponding transforms to do
% - descs         Cell array with descriptions of the series
%
% Output: Matlab structure, vintdata with fields
% - dates         A vector of common (matlab) dates for all series.
% - series        A cell array of FRED codes corresponding to the series in
%                   vintdata
% - values        A big matrix with the combined data.
%                   rows: different observation date (NaN if unobserved)
%                   cols: the different series
% - frqcy         A cell array with the native frequencies of the data. Lowest
%                   should be monthly
% - transf        A cell array with the transformations relevant to the series
% - transf_ind    An indicator variable. 1 if the transformations specified by
%                   transf have been applied to the data in the vintage
%                   structure. 0 otherwise.
%
function [ vintdata ] = align_vintdata(vint_dir, lgd, pseudinfo, vint_date)

  % Replace high frequencies with lower frequencies
  high_frequency = ~cellfun(@(f) sum(strcmp(f, {'q', 'm'})), lgd.frequency);
  lgd.frequency(high_frequency) = repmat({'m'}, sum(high_frequency),1);

  % Check that you have all the series you should; if not, throw away the
  % series you don't have
  files       = arrayfun(@(s) sprintf('%s/IndividualSeries/%s_%s', vint_dir, lgd.code{s}, lgd.frequency{s}), 1:length(lgd.code), 'un', 0)';
  files_exist = logical(cellfun(@(f) exist(f, 'file'), files));
  not_found   = [lgd.code(~files_exist), lgd.frequency(~files_exist), lgd.transform(~files_exist), lgd.desc(~files_exist)];

  mainflds = {'code'; 'frequency'; 'transform'; 'desc'; 'countercyclical'; 'group'};
  D = struct();
  for f = 1:length(mainflds)
    D.(mainflds{f}) = lgd.(mainflds{f})(files_exist);
  end
  D.group_names = lgd.group_names;
  pseudinfo = pseudinfo(files_exist);


  % Initialize data struct
  nseries = length(D.code);
  data = repmat(struct('dates', [], 'values', [], 'frequency', []),...
                nseries, 1);

  %% Read in series and save in data structure
  for s = 1:nseries
    d = dlmread(sprintf('%s/IndividualSeries/%s_%s', vint_dir, D.code{s}, D.frequency{s}));
    data(s).dates     = d(:,1);
    data(s).values    = d(:,2);

    % For quarterly series, increment the months by 2 so the value lands on the
    % end of the quarter (i.e. make 2013Q4 be represented as 12-01-2013 not
    % 10-01-2013)
    if strcmp(D.frequency{s}, 'q')
      data(s).dates = arrayfun(@(d) addtodate(d, 2, 'month'), data(s).dates);
    end
  end

  %% Construct the entire common date range (from the first obs to the last)
  r = [datevec(min(arrayfun(@(i_) data(i_).dates(1),   1:nseries))); ...
       datevec(max(arrayfun(@(i_) data(i_).dates(end), 1:nseries)))];
  nmonths = diff(r(:,1:3))*[12 1 0]'; % number of months in the data
  all_dates = datenum(cumsum([r(1,1:3); ones(nmonths, 1)*[0 1 0]]));
    % ^date vector of the 1st day of each month in date_range
  ndates = length(all_dates);


  %% Loop over series and expand dates and values
  for s = 1:nseries

    % Indices of all_dates where we have data for series s
    available_idx = find(ismember(all_dates, data(s).dates));

    % Initialize an expanded values series for series s
    expanded_values = nan(ndates, 1);

    % Fill in expanded data with available data
    expanded_values(available_idx) = data(s).values;

    % Update data structure
    data(s).dates = all_dates;
    data(s).values = expanded_values;
  end


  %% Merge across series and save metadata
  mainflds = {'code'; 'frequency'; 'transform'; 'desc'; 'countercyclical'; 'group'; 'group_names'};
  mainflds_rename = {'series'; 'frqcy'; 'transf'; 'desc'; 'ctrcyclical'; 'group'; 'group_names'};

  vintdata.dates       = all_dates;
  vintdata.not_found   = not_found;
  vintdata.values      = [data(:).values];
  for f = 1:length(mainflds)
    vintdata.(mainflds_rename{f}) = D.(mainflds{f});
  end
  vintdata.pseudinfo   = pseudinfo;
  vintdata.transf_ind  = 0;
  vintdata.vint_date   = vint_date;

end
