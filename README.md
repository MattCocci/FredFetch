# FredFetch

For fetching the latest and vintage data from
[Fred](http://research.stlouisfed.org/fred2/) and
[Alfred](https://alfred.stlouisfed.org/).

This package aims to be simple enough for importing data quickly and
interactively, while still having enough muscle to download many series
over many vintage dates.

## Table of Contents

1. [Setup](#setup)
2. [Basic Usage](#basic)
  - [Fetching the Latest Data](#latest)
  - [Fetching Vintage Data](#vintage)
    - [Basic Examples](#vintexamples)
    - [Pseudo-Vintages](#pseudo)
    - [Parallel Calls](#parallel)
3. [Additional Features](#features)
4. [FredFetch as a Fred API Wrapper](#wrapper)

<a name="setup"/>
## Setup

Three steps:


1. Clone this repo somewhere, and add that somewhere to your Matlab path.


2. Supply an API key in a file named `api.txt` in the top-level
   directory (the one `README.md` lives in). See the [Fred
   website](http://api.stlouisfed.org/api_key.html) to get one.


3. As this is a Matlab package, call functions with a `fred.` prefix.
   Example `fred.latest('GDPC1')`.


<a name="basic"/>
## Basic Usage

You really only need to interact with two functions:

1. `fred.latest(series)`: For fetching the latest data.
2. `fred.vint(series, vint)`: For fetching data as it existed at some vintage date.

Where `series` is a Fred series code (or cell of codes), and `vint` is a
Matlab datenum or array of datenums (or, alternatively, cell and cell
array of datestrings).

Calls to these functions return structs with the following fields:

- `info`: Detailed information about the series.
- `series`: Series code
- `frequency_short`: Short identifier of the native frequency (`Q`, `M`,
  etc.)
- `realtime`: The vintage date. If you pull the latest data, this is
  the current date.
- `pseudo`: Whether it is a true or simulated vintage (see below).
- `date`: Observation dates
- `value`: Array of series values.

All series are returned in the native Fred units (so often levels, not
percent changes, or differences). If you need to transform the data, see
the function `fred.transform`.


<a name="latest"/>
### Fetching the Latest Data

This is the simplest case, when you want to quickly import into Matlab
the latest data for one or many series. Examples:

- `fred.latest('GDPC1')`: Fetch the series GDPC1.
- `fred.latest({'GDPC1', 'PAYEMS', 'NAPM'})`: Fetch multiple series at
  once, including data with different frequencies. The returned data
  will be merged into a single data matrix (aligned and accounting for
  different frequencies).
- `fred.latest({'GDPC1', 'PAYEMS', 'NAPM'}, 0)`: Same as above, but
  returns a struture array, with one entry per series. Does _not_ merge data into common data matrix.

The real advantage of `fred.latest` is that it's snappy. Though you
could download these data using the vintage functions below (with the
vintage date simply set to today's date), the returned json results from
the Fred API need to be parsed, which is slower. Not terribly slow, but
`fred.latest` is on the order of a second (or less) per series, so it's
preferred.


<a name="vintage"/>
### Fetching Vintage Data

<a name="vintexamples"/>
#### Basic Examples

To fetch the data that would have existed at a certain date, run

- `fred.vint('GDPC1', '2001-01-01')`: Fetch series as it existed
  01-Jan-2001.
- `fred.vint({'GDPC1', 'PAYEMS', 'NAPM'}, '2001-01-01')`: Fetch multiple series.
- `fred.vint({'GDPC1', 'PAYEMS', 'NAPM'}, '2001-01-01', 0)`: Fetch
  multiple series, but don't merge into common matrix.
- `fred.vint('GDPC1', datenum(2000:2015,1,1))`: Get series at
  January 1 of every year from 2000 to 2015.
- `fred.vint({'GDPC1', 'PAYEMS', 'NAPM'}, datenum(2000:2015,1,1))`: Get
  multiple series at January 1 of every year from 2000 to 2015.
- `fred.vintall('GDPC1')`: All available vintages of a given series.
  Observation dates along the rows, unique vintage dates along the
  columns of returned data matrix.

In general, within the `value` field of returned structure, rows
correspond to different observation dates, while columns represent
*either* different series or different vintage dates of the same series.
Should be clear from the function call and sizes of the returned
information.

<a name="pseudo"/>
#### Pseudo-Vintages

Most series do not have vintage data available at any arbitrary date.
Often, you can only download vintage data after some specific date.  For
example, Fred does not have `GDPC1` vintages from before 1991. However,
you might like to do the best you can and *simulate* vintages.

In particular, you might not have the 01-Jan-1989 `GDPC1` vintage, but you
can take the first available vintage for the series from 12-Dec-1991,
and chop off enough of the 1989 and 1990 releases to simulate
publication lags, constructing an information set close to what you
*would have had* at 01-Jan-1989.

To do this, simply run

```
  `fred.vint('GDPC1', '1989-01-01', 'pseudo', 1)
```

This package will do exactly the method described above, using the
median publication delay (computed over the entire available history of
the series) to discard observations.

<a name="parallel"/>
#### Parallel Calls

When downloading vintages for many, many series, you might want to
download in parallel. (The json parsing is the bottleneck, so if you're
just running `fred.latest`, which doesn't use json, you problably don't
need to worry about parallelizing, though you could.)

To do this, simply add the following argument

```
  `fred.vint({'GDPC1', 'NAPM', 'PAYEMS'}, '1989-01-01', 'parworkers', Nworkers)
```

where `Nworkers` is the number of parallel workers you would like to
use. The package will select the minimum of that and the number of
series, so you could even set it to NaN or Inf if you would like.

Note also that this will not conflict if you pass the optional `pseudo`
key and value before or after. But any additional arguements that should
be handed to the Fred API (like `observation_start` and it's value)
should come last in the argument list.

<a name="features"/>
## Additional Features

Here are some examples for the remaining user-oriented functions:

- `fred.firstRelease('GDPC1')`: For all observation dates of `GDPC1`,
  return the first release (rather than subsequent revisions or the
  latest value).
- `fred.firstRelease('GDPC1', 'units', 'pca')`: First releases of GDPC1
  in percent-annualized units. Transformation done by `fred.transform`
  (since passing this to the Fred API does not work, for some reason).
- `getvints('GDPC1')`: Return available vintage dates for `GDPC1`.
- `transform(X, tform, frqcy)`: Transform a series, where `tform` is a
  string for the transformation type (same as Fred API conventions). If
  `X` is a matrix of data, `tform` and `frqcy` should be cell arrays,
  one entry for each column of `X`.
- `transform(dataStruct, transform)`: For transforming data within a
  structure returned by `fred.vint` or `fred.latest`. Again, multiple
  series require that `transform` be a cell of transformation strings.

The remaining non-user oriented functions have names ending with an
underscore, like `latest_.m`.  Often, the user-oriented functions are
just wrappers that parse the user's input and then call these underscore
functions. You don't ever really need to worry about them.

<a name="wrapper"/>
## FredFetch as a Fred API Wrapper

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

See the [Fred API documentation](http://api.stlouisfed.org/docs/fred/)
for more details on what you can provide.

Note that currently, if requesting many series, the optional arguments
provided will be _identical_ across each request. Maybe on the to-do
list: accepting cells that can be iterated over as we iterate over
series.


