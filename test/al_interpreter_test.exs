defmodule AlInterpreterTest do
  use ExUnit.Case
  doctest AlInterpreter

  test "evaluate number" do
    assert AlInterpreter.parse("123")
           |> AlInterpreter.evaluate() == {123, %{}}
  end

  test "evaluate addition" do
    assert AlInterpreter.parse("123 + 456")
           |> AlInterpreter.evaluate() == {123 + 456, %{}}
  end

  test "evaluate assignment" do
    assert AlInterpreter.parse("x = 123")
           |> AlInterpreter.evaluate() == {123, %{"x" => 123}}
  end

  @add123 {:closure, ["x"], {:add_op, {:identifier, 1, 'x'}, {:number, 1, '123'}}, %{}}

  test "evaluate function" do
    assert AlInterpreter.parse("fn x => x + 123")
           |> AlInterpreter.evaluate() == {@add123, %{}}
  end

  test "evaluate application" do
    assert AlInterpreter.parse("add123 = fn x => x + 123; add123 456")
           |> AlInterpreter.evaluate() == {123 + 456, %{"add123" => @add123}}
  end

  test "evaluate parenthesised" do
    assert AlInterpreter.parse("(fn x => x + 123) 456")
           |> AlInterpreter.evaluate() == {123 + 456, %{}}
  end

  test "evaluate curried" do
    assert AlInterpreter.parse("(fn x, y => x + y) 123 456")
           |> AlInterpreter.evaluate() == {123 + 456, %{}}
  end

  test "evaluate complex" do
    assert AlInterpreter.parse("""
           Y       = fn f => (fn x => f(fn v => x x v)) (fn x => f(fn v => x x v));
           zero    = fn f, x => x;
           one     = fn f, x => f(x);
           ten     = fn f, x => f(f(f(f(f(f(f(f(f(f(x))))))))));
           succ    = fn n => fn f, x => f(n f x);
           add     = fn n, m => fn f, x => n f (m f x);
           pair    = fn a, b => fn f => f a b;
           first   = fn pair => pair (fn a, b => a);
           second  = fn pair => pair (fn a, b => b);
           sub1    = fn n => second
                              (n (fn pred =>
                                    pair (succ (first pred)) (first pred))
                                 (pair zero zero));
           true    = fn a, b => a;
           false   = fn a, b => b;
           if      = fn cond, true, false => cond true false 0;
           is_zero = fn n => n (fn x => false) true;
           sum     = fn sum => fn n => if (is_zero n)
                                          (fn x => zero)
                                          (fn x => add n (sum (sub1 n)));
           (Y sum) ten (fn x => x + 1) 0
           """)
           |> AlInterpreter.evaluate()
           |> elem(0) == Enum.reduce(0..10, 0, &+/2)
  end
end
