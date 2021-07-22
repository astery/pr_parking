defmodule MojeprahaApi do
  @moduledoc """
  A wraper to https://mojepraha.eu/apispecs endpoints

  Usually I do not put any conversion logic and keep responses as close
  as origin. And conversion logic goes into anti-corruption layer.

  But for the sake of briefity we retun the simplified result.
  """

  defmodule Error do
    defexception code: nil, message: nil

    def message(%__MODULE__{} = e), do: "(#{e.code}) #{e.message}"
  end

  defmodule ConnectionError do
    defexception reason: nil, status_code: nil

    def message(%__MODULE__{} = e), do: "(HTTP status: #{e.status_code}) #{e.reason}"
  end

  defmodule HttpApi do
    @moduledoc false

    use Tesla

    plug(Tesla.Middleware.BaseUrl, "http://private-b2c96-mojeprahaapi.apiary-mock.com")

    plug(Tesla.Middleware.Headers, [
      {"content-type", "application/json"}
    ])

    plug(Tesla.Middleware.JSON)
    plug(Tesla.Middleware.Logger)

    # Simplyfied output
    def get_pr_parking(id) do
      with {:ok,
            %{
              "properties" => %{
                "num_of_taken_places" => taken,
                "total_num_of_places" => total
              }
            }} <- get_full_pr_parking(id) do
        {:ok,
         %{
           num_of_taken_places: taken,
           total_num_of_places: total
         }}
      end
    end

    # Real output
    def get_full_pr_parking(id) do
      get("/pr-parkings/#{id}")
      |> handle_response()
    end

    def handle_response({:ok, %{body: %{"error" => error}}}),
      do: {:error, %Error{code: error["code"], message: error["message"]}}

    def handle_response({:ok, %{body: body, status: 200}}), do: {:ok, body}
    def handle_response({:ok, %{body: body, status: 201}}), do: {:ok, body}

    def handle_response({:ok, %{body: body, status: status}}),
      do: {:error, %ConnectionError{status_code: status, reason: unexpected_reason(body)}}

    def handle_response({:error, :econnrefused}),
      do: {:error, %ConnectionError{reason: "Connection refused"}}

    def handle_response({:error, e}),
      do: {:error, %ConnectionError{reason: inspect(e)}}

    defp unexpected_reason(body),
      do: "Unexpected server response: #{String.slice(body, 0, 50)}(maybe truncated)"
  end

  defmodule Behaviour do
    @moduledoc false

    @type error :: {:error, %Error{} | %ConnectionError{}}

    @type parking_id :: String.t()
    @type parking_properties :: %{
            num_of_taken_places: integer(),
            total_num_of_places: integer()
          }

    @type pr_parking_response :: {:ok, parking_properties} | error()

    @callback get_pr_parking(parking_id) :: pr_parking_response
  end

  @behaviour Behaviour
  @adapter Application.compile_env(:packbox, :easy_post_api_module, HttpApi)

  defdelegate get_pr_parking(id), to: @adapter
end
