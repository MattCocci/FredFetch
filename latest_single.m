function [data] = latest_single(series)

  url = sprintf('http://research.stlouisfed.org/fred2/data/%s.txt', series);
  [query, success] = ReadFredURL(url, 0);
  if ~success
    data.info = returned;
    data.date = [];
    data.date = [];
    return
  end

  %% Split returned data string into info and data components to parse
  [~, ~, ~, ~, ~, ~, query] = regexp(query, 'DATE[\s]*VALUE');
  info_str = query{1};
  data_str = query{2};


  %% Parse info
  tomatch = {'Title'; 'Series ID'; 'Source'; 'Release'; ...
             'Seasonal Adjustment'; 'Frequency'; 'Units'; ...
             'Date Range'; 'Last Updated'; 'Notes'};
  storeas = {'title'; 'id'; 'source'; 'release'; ...
                'seasonal_adjustment'; 'frequency'; 'units'; ...
                'date_range'; 'last_updated'; 'notes';};
  inds = zeros(length(tomatch), 2);
  for n = 1:length(tomatch)
    [inds(n,1) inds(n,2)] = regexp(info_str, [tomatch{n} ':[\s]']);
  end

  for n = 1:length(tomatch)
    start = inds(n,2)+1;
    if n < length(tomatch)
      stop = inds(n+1,1)-1;
    else
      stop = length(info_str);
    end
    info.(storeas{n}) = strtrim(info_str(start:stop));
  end


  %% Parse the data
  date_value = textscan(data_str, '%s\t%f');


  %% Store and return
  data.info   = info;
  data.date   = datenum(date_value{1}, 'yyyy-mm-dd');
  data.value  = date_value{2};

end

