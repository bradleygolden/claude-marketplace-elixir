defmodule VulnerableCodeController do
  @moduledoc """
  Test Phoenix controller containing intentional security vulnerabilities for Sobelow detection.
  This simulates a Phoenix controller to trigger security findings.
  Note: Without full Phoenix context, Sobelow conservatively marks these as Low Confidence.
  """

  # Simulate Phoenix controller - Command injection with params
  def execute_command(conn, %{"cmd" => cmd}) do
    System.cmd("sh", ["-c", cmd])
    conn
  end

  # Simulate Phoenix controller - File traversal with params
  def read_file(conn, %{"filename" => filename}) do
    _content = File.read!("uploads/#{filename}")
    conn
  end

  # Simulate Phoenix controller - Code execution with params
  def eval_code(conn, %{"code" => code}) do
    {_result, _} = Code.eval_string(code)
    conn
  end

  # Simulate Phoenix controller - String.to_atom DOS
  def create_atom(conn, %{"name" => name}) do
    _atom = String.to_atom(name)
    conn
  end
end
