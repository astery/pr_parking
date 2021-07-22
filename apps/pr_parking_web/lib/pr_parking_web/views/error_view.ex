defmodule PrParkingWeb.ErrorView do
  use PrParkingWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  def from(atom) when is_atom(atom) do
    error(PrParkingWeb.ErrorHelpers.detail(atom))
  end

  def render("error.json", %{detail: detail}) do
    error(detail)
  end

  def template_not_found(template, _assigns) do
    error(Phoenix.Controller.status_message_from_template(template))
  end

  defp error(detail), do: %{"errors" => %{"detail" => detail}}
end
