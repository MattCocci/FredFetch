# FredFetch

For fetching the latest and vintage data from
![Fred](http://research.stlouisfed.org/fred2/) and
![Alfred](https://alfred.stlouisfed.org/).

## Setup

Three steps:

1. Clone this repo somewhere, and add that somewhere to your Matlab path.

2. Go into `+fred/GlobalOptions.m` and supply an API key (see ![Fred
   website](http://api.stlouisfed.org/api_key.html) to get one.

3. As this is a Matlab package, call functions with a `fred.` prefix.
   Example `fred.latest('GDPC1')`

### Fetching the Latest Data

This is the simplest case, when you want to quickly import into Matlab
the latest data for one or many series. Examples:

- `fred.latest('GDPC1')`: Fetch the series GDPC1. Return in struct with
  dates and information/notes about the series.
- `fred.latest({'GDPC1', 'PAYEMS', 'NAPM'})`: Fetch multiple series at
  once, including data with different frequencies. The returned struct
  will have info, a single matrix of aligned data, and a common date
  vector.

All data are in the native Fred frequency, in levels.

The real advantage of `fred.latest` is that it's snappy. Though you
could download these data using the vintage functions below (with the
vintage date simply set to today's date), the returned json results from
the Fred API need to be parsed, which is slower. Not terribly slow, but
`fred.latest` is on the order of a second (or less) per series, so it's
preferred.


### Fetching Vintage Data

#### Main Usage

To fetch the data that would have existed at a certain date, run

- `fred.vint('GDPC1', '2001-01-01')`: For a single series.
- `fred.vint({'GDPC1', 'PAYEMS', 'NAPM'}, '2001-01-01')`: For multiple series.
- `fred.vintall('GDPC1')`: All vintages of a given series. Observation
  dates along the rows, unique vintage dates along the columns of
  returned data matrix.

#### Advanced Usage

All of the above vintage functions accept additional arguments that can
enter the query URL if you would like to take advantage of Fred's API
features. These optional arguments should take the exact form of Fred
API key and value combinations. In this way, this package acts as a thin
wrapper for the fully-featured Fred API.

Example:

```
  fred.vint('GDPC1', '2001-01-01', 'observation_start', '1991-03-14', 'observation_end', '2000-03-14')
```

Again, you can supply any number of additional Fred API that arguments you want,
provided they are not one of the following fields (which are set by the
series and vintage date arguments):

- `series`
- `realtime_start`
- `realtime_end`

See the ![Fred API documentation](http://api.stlouisfed.org/docs/fred/)
for more details on what you can provide.

Note that currently, if requesting many series, the optional arguments
provided will be _identical_ across each request. On the to-do list:
accepting cells that can be iterated over as we iterate over series.


#### Vintage Availability

Note that before 1990s, you won't have much (if any) luck pulling
vintage data. And before the 2000s, it will also be slim pickings.

To help, series without any data for the requested vintage date will be
an all-`NaN` column in the returned data matrix. That way, if you're
looping over vintage dates and downloading data for multiple series, the
size of the data matrix isn't changing with vintage availability.


