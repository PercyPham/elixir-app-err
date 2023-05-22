defmodule AppErrorTest do
  use ExUnit.Case
  doctest AppError

  describe "&get_trace/1" do
    test "get trace from app error" do
      err = :error
      # The test depends on the stacktrace of errors created.
      # Assertion modification is required if these lines are relocated.
      app_err = AppError.wrap(err, "do something")
      app_err = AppError.wrap(app_err, "do other thing")

      trace = AppError.get_trace(app_err)

      assert trace === [
               {
                 AppErrorTest,
                 :"test &get_trace/1 get trace from app error",
                 1,
                 [file: 'test/app_error_test.exs', line: 10]
               },
               {AppErrorTest, :"test &get_trace/1 get trace from app error", 1,
                [file: 'test/app_error_test.exs', line: 11]}
             ]
    end

    test "get trace from nil" do
      trace = AppError.get_trace(nil)
      assert trace === []
    end

    test "get trace from non-app-error" do
      err = :error

      trace = AppError.get_trace(err)

      assert trace === []
    end
  end

  describe "error message" do
    test "wrap nil" do
      err = nil
      app_err = AppError.wrap(err, "do something")

      assert app_err == nil
      assert_msg(app_err, "")
    end

    test "wrap an atom" do
      err = :some_error
      app_err = AppError.wrap(err, "do something")

      assert_msg(app_err, "do something: some_error")
    end

    test "wrap a string" do
      err = "some error"
      app_err = AppError.wrap(err, "do something")

      assert_msg(app_err, "do something: some error")
    end

    test "wrap another app error" do
      app_err = AppError.wrap("some error", "do something")
      app_err = AppError.wrap(app_err, "do other thing")

      assert_msg(app_err, "do other thing: do something: some error")
    end

    test "wrap unknown format" do
      err = {:unknown1, :unknown2}
      app_err = AppError.wrap(err, "do something")

      assert_msg(app_err, "do something: {:unknown1, :unknown2}")
    end

    defp assert_msg(err, expected_err_msg) do
      assert expected_err_msg === AppError.get_message(err)
      assert expected_err_msg === "#{err}"
    end
  end

  describe "&unwrap/1" do
    test "unwrap nil" do
      assert AppError.unwrap(nil) === nil
    end

    test "normal err" do
      assert AppError.unwrap(:error) === nil
    end

    test "unwrap app error" do
      err = :some_err
      app_err = AppError.wrap(err, "some msg")

      unwrapped_err = AppError.unwrap(app_err)

      assert unwrapped_err === err
    end
  end

  describe "&root/1" do
    test "root of nil" do
      assert AppError.root(nil) === nil
    end

    test "root of non-app-error" do
      assert AppError.root(:root_error) === :root_error
    end

    test "root of app error" do
      root_err = :root_error

      app_err =
        root_err
        |> AppError.wrap("msg")
        |> AppError.wrap("other msg")

      assert AppError.root(app_err) === root_err
    end
  end

  describe "&is/2" do
    test "target are nil & input is nil" do
      assert AppError.is?(nil, nil)
    end

    test "target is nil & input is not nil" do
      [
        "some_err",
        :some_err,
        :some_err |> AppError.wrap("msg")
      ]
      |> Enum.each(fn err ->
        refute AppError.is?(err, nil)
      end)
    end

    test "target is not app error" do
      [
        {true, :target, :target},
        {true, :target, :target |> AppError.wrap("msg")},
        {true, :target, :target |> AppError.wrap("msg") |> AppError.wrap("other msg")},
        {false, :target, nil},
        {false, :target, :other},
        {false, :target, :other |> AppError.wrap("msg")},
        {true, "target", "target"},
        {true, "target", "target" |> AppError.wrap("msg")},
        {true, "target", "target" |> AppError.wrap("msg") |> AppError.wrap("other msg")},
        {false, "target", nil},
        {false, "target", :other},
        {false, "target", :other |> AppError.wrap("msg")}
      ]
      |> Enum.each(fn {expected?, target, input} ->
        actual? = AppError.is?(input, target)

        assert actual? === expected?,
               "checking #{inspect(input)}: expected #{expected?}, got #{actual?}"
      end)
    end

    test "wrapper of target app error" do
      target = :error |> AppError.wrap("msg")
      app_err = target |> AppError.wrap("other msg")

      assert AppError.is?(app_err, target)
    end

    test "not wrapper of target app error" do
      target = :error |> AppError.wrap("msg")
      app_err = :other |> AppError.wrap("other msg")

      refute AppError.is?(app_err, target)
    end
  end
end
