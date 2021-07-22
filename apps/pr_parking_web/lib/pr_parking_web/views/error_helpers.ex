defmodule PrParkingWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  def detail(:not_found), do: "Not Found"
  def detail(:bad_arg), do: "Bad Arguments Given"
  def detail(:too_many_requests), do: "Too Many Requests"
  def detail(:not_ready), do: "Not Ready"
  def detail(_), do: "Internal Server Error"

  @doc """
  Translates an error message.
  """
  def translate_error({msg, opts}) do
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
