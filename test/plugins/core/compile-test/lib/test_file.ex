defmodule TestFile do
  def parse_json(data) do
    Jason.decode(data)
  end

  def query_data do
    Ecto.Query.from(u in User)
  end
end
