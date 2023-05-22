defmodule AppError do
  @moduledoc """
  Documentation for `AppError`.
  """

  defstruct nested_err: nil,
            msg: "",
            trace: nil

  def wrap(nil, _), do: nil

  def wrap(err, msg),
    do: %AppError{
      nested_err: err,
      msg: msg,
      trace: get_caller_trace()
    }

  defp get_caller_trace() do
    {:current_stacktrace, traces} = Process.info(self(), :current_stacktrace)
    Enum.at(traces, 3)
  end

  def get_trace(nil), do: []
  def get_trace(%AppError{} = err), do: AppError.get_trace(err.nested_err) ++ [err.trace]
  def get_trace(_), do: []

  def get_message(nil), do: ""
  def get_message(err) when is_atom(err), do: to_string(err)
  def get_message(err) when is_bitstring(err), do: err
  def get_message(%AppError{} = err), do: "#{err.msg}: #{get_message(err.nested_err)}"
  def get_message(err), do: inspect(err)

  def unwrap(nil), do: nil
  def unwrap(%AppError{} = err), do: err.nested_err
  def unwrap(_), do: nil

  def root(nil), do: nil
  def root(%AppError{} = err), do: root(err.nested_err)
  def root(err), do: err

  def is?(nil, nil), do: true
  def is?(_, nil), do: false

  def is?(err, target) do
    cond do
      err === nil -> false
      err === target -> true
      true -> is?(unwrap(err), target)
    end
  end
end

defimpl String.Chars, for: AppError do
  def to_string(app_err), do: AppError.get_message(app_err)
end
