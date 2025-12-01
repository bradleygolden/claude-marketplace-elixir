defmodule PrecommitTestFail do
  @moduledoc """
  Test module with intentional warning to trigger precommit failure.
  """

  def hello do
    # Intentional unused variable to cause --warnings-as-errors to fail
    unused_variable = :this_will_cause_warning
    :world
  end
end
