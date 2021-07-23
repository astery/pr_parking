[![build](https://github.com/astery/pr_parking/actions/workflows/ci.yml/badge.svg)](https://github.com/astery/pr_parking/actions)

## PR Parking

## What is this?

This is the solution to the test assignment. You can read the problem description in [pages/problem.md](https://github.com/astery/pr_parking/blob/master/pages/problem.md)

## Dependencies

- Elixir: 1.12
- Erlang/OTP: 24.0

## Setup

1. `mix deps.get`
1. `mix setup`
1. `mix dialyzer --plt` # Will take a long time for the first run

Consider to add local git hooks to prevent pushing malformed commit:

`cp .hooks/* .git/hooks`

## Run

- Start server `mix phx.server`

## Checking behaviour

While server loads resources on start up api requests should return :not_ready errors.

After load completes you can checkout a value of the resource (there only the single one
in the config 534013).

```
$ curl http://localhost:4000/api/parkings/534013

{"taken_places":57,"total_places":57}
```

And should see no requests to majapraha api. Wait a minute and you should see
a debug messages showing requests to majapaha api.

```
[debug] 
>>> REQUEST >>>
...
<<< RESPONSE <<<
...
{
    "type": "Feature",
    "geometry": {
        "type": "Point",
        "coordinates": [14.350451, 50.05053]
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

You can set refresh period:

```
curl -X POST http://localhost:4000/api/crawlers/534013 --data '{"refresh_period": 2}' -H  "Content-Type: application/json"

{"refresh_period":2}
```

If you post refresh_period for a new parking id, it will become available for requesting.

## Running tests

- `mix test`
