defmodule Cached.Support.Mocks.Api do
  @moduledoc false
  @callback request(any()) :: any()
end

Mox.defmock(ApiMock, for: Cached.Support.Mocks.Api)
Mox.defmock(TimerMock, for: Cached.Timer.Behaviour)
