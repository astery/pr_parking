# Assignment - P+R Parking
We are building a platform for parking places monitoring. We need to collect
data from a public API and provide a custom REST API to our clients. In this
assignment we want to verify how you can access 3rd party resource, manage a state
and provide an API to server part of this resource.

## External Data
The public API for fetching data is here [https://mojepraha.eu/apispecs](https://mojepraha.eu/apispecs)
and we are interested in P+R parking endpoint only. For the sake of simplicity, we will be using
a single hardcoded resource (534013) in the assignment:
[http://private-b2c96-mojeprahaapi.apiary-mock.com/pr-parkings/534013](http://private-b2c96-mojeprahaapi.apiary-mock.com/pr-parkings/534013)

```
curl http://private-b2c96-mojeprahaapi.apiary-mock.com/pr-parkings/534013 | jq .

{
  "type": "Feature",
  "geometry": {
    "type": "Point",
    "coordinates": [
      14.350451,
      50.05053
    ]
  },
  "properties": {
    "id": 534013,
    "last_updated": 1502178725000,
    "name": "Nové Butovice",
    "num_of_free_places": 0,
    "num_of_taken_places": 57,
    "total_num_of_places": 57,
    "pr": true,
    "district": "praha-13",
    "address": "Seydlerova 2152/1, Stodůlky, 158 00 Praha-Praha 13, Česko"
  }
}
```

Our application needs to fetch data periodically however the period
should be configurable and it should be between 1-10 minutes. For simplicity, we
will keep these resources with parameters in a config which may look like:

```
config: parking_service
  endpoint_url: "http://private-b2c96-mojeprahaapi.apiary-mock.com/pr-parkings/"
  resources: [
    %{id: 534013, refresh_period: 5}, # period is in minutes
    ...
  ]
```

You must assume that there might be eventually several thousands of these resources
and every resource might have a different `refresh_period`.

We are interested in `total_num_of_places` and `num_of_taken_places` only from the
response and the rest can be discarded.

## Our REST API
There will be two endpoints only. One for getting data about parking places and
the second for changing `refresh_period` for a particular resource. We will use same
resource ids as in the original public API e.g. if the original resource id was `534013`
our resource id will be the same.

Endpoint: `/parkings/{ID}`
Method: `GET`
Response data:
```
{
  "total_places": 57,
  "taken_places": 0
}
```

Endpoint: `/crawlers/{ID}`
Method: `POST`
Body:
```
{
  "refresh_period": 8
}
```

For both endpoints, use relevant HTTP status.

In our simplified case, the `ID` for both endpoints would `534013`.

You don't need to persist a new value of `refresh_period`. The application can use
the default values when it is started or even when it is partially restararted (crash).


## Be carufull about
- We must not overload the mojepraha.eu API. That means fetching a single resource
(`http://private-b2c96-mojeprahaapi.apiary-mock.com/pr-parkings/534013`) once per
a minute or a few times per minute is fine but sending 100 or 1000 requests per minute
to the resource is not fine.
- You must expect that our clients will access our REST API very frequently. There
might be over 100 requests per minute for a single resource (e.g. 534013).
- Keep in mind there might be several thousands of resources (e.g. http://private-b2c96-mojeprahaapi.apiary-mock.com/pr-parkings/XXXX)
