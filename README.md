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

## Running tests

- `mix test`
