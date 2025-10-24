defmodule VulnerableCodeController do
  @moduledoc """
  Test Phoenix controller containing intentional security vulnerabilities for Sobelow detection.
  This simulates a Phoenix controller to trigger Medium/High confidence findings.
  """

  # Simulate Phoenix controller - Command injection with params (High Confidence)
  def execute_command(conn, %{"cmd" => cmd}) do
    # Direct use of params in System.cmd - High confidence
    System.cmd("sh", ["-c", cmd])
    conn
  end

  # Simulate Phoenix controller - File traversal with params (High Confidence)
  def read_file(conn, %{"filename" => filename}) do
    # Direct use of params in File.read - High confidence
    _content = File.read!("uploads/#{filename}")
    conn
  end

  # Simulate Phoenix controller - Code execution with params (High Confidence)
  def eval_code(conn, %{"code" => code}) do
    # Direct use of params in Code.eval_string - High confidence
    {_result, _} = Code.eval_string(code)
    conn
  end

  # Simulate Phoenix controller - String.to_atom DOS (High Confidence)
  def create_atom(conn, %{"name" => name}) do
    # Direct use of params in String.to_atom - High confidence
    _atom = String.to_atom(name)
    conn
  end
end
