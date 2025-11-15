defmodule SpecificDepsTest do
  @moduledoc """
  Test file that uses ONLY jason dependency.
  Should NOT match ecto, decimal, or telemetry.
  """

  def parse_json(data) do
    Jason.decode(data)
  end

  def encode_json(data) do
    Jason.encode(data)
  end
end
