fred.dataset(series, vintdate, obs\_start, obs\_end)        to return data table
fred.dataset({series}, vintdate, obs\_start, obs\_end)      to return a data table with many series properly spaced
fred.vintages(series, vintsart, vintend, obstart, obsend)   to get all vintages of a dataset
fred.writecsv({series}, vintdate, obstart, obsend)
fred.vintdates(series)
fred.first\_release(series, obstart, obsend)


opt = (api); % Test connection
fred.vint(opt, series, vintdate, obs\_start, obs\_end)        to return data table
fred.vint(opt, {series}, vintdate, obs\_start, obs\_end)      to return a data table with many series properly spaced
fred.vintsall(series, vintsart, vintend, obstart, obsend)   to get all vintages of a dataset
fred.csv({series}, vintdate, obstart, obsend)
fred.xls({series}, vintdate, obstart, obsend)
fred.getvints(series)
fred.first\_release(series, obstart, obsend)

