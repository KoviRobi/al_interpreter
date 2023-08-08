defmodule AlInterpreter do
  def main(_args \\ []) do
    repl()
  end

  def repl(definitions \\ %{}) do
    IO.write("> ")
    line = IO.read(:line)

    try do
      statements = parse(line)
      {result, definitions1} = evaluate(statements, nil, definitions)
      IO.inspect(result)
      repl(definitions1)
    catch
      kind, error ->
        Exception.format(kind, error)
        repl(definitions)
    end
  end

  # Abstract syntax tree (AST) types:
  @type ast_statements :: [ast_statement]
  @type ast_statement :: {:assign, ast_identifier, ast_expr} | ast_expr
  # The case `{:fn, ast_var_list, ast_expr}` is a subtype of
  # `{:fn, ast_var_list, ast_statement}` as `ast_expr` is a subtype of
  # `ast_statement`.
  @type ast_expr :: {:fn, [ast_identifier], ast_statement} | ast_app
  @type ast_app :: {:application, ast_app, ast_infix} | ast_infix
  @type ast_infix ::
          {ast_infix_op, ast_infix, ast_infix}
          | ast_number
          | ast_identifier
          | ast_expr
  @type ast_infix_op :: :add_op | :sub_op | :mul_op | :div_op
  @type ast_number :: {:number, number, number}
  @type ast_identifier :: {:identifier, number, charlist}

  @type eval_result :: eval_number | eval_identifier | eval_fn
  @type definitions :: %{identifier => eval_result}
  @type eval_number :: number
  @type eval_identifier :: binary
  @type eval_fn :: {:closure, [eval_identifier], ast_statement, definitions}

  @spec parse(binary) :: ast_statements
  def parse(string) do
    with {:ok, tokens, _line} <- :lexer.string(String.to_charlist(string)),
         {:ok, tree} <- :parser.parse(tokens) do
      tree
    end
  end

  @spec evaluate_identifier(ast_identifier) :: eval_identifier
  def evaluate_identifier({:identifier, _line, charlist}) do
    to_string(charlist)
  end

  @spec evaluate_number(ast_number) :: eval_number
  def evaluate_number({:number, _line, charlist}) do
    for char <- charlist, reduce: 0 do
      acc -> acc * 10 + (char - 48)
    end
  end

  @spec evaluate(ast_statements, eval_result | nil, definitions) :: {eval_result, definitions}
  def evaluate(statements, result \\ nil, definitions \\ %{})

  def evaluate([statement | statements], _result, definitions) do
    {result, definitions1} = evaluate_statement(statement, definitions)
    evaluate(statements, result, definitions1)
  end

  def evaluate([], result, definitions) do
    {result, definitions}
  end

  @spec evaluate_statement(ast_statement, definitions) :: {eval_result, definitions}
  def evaluate_statement({:assign, identifier, expr}, definitions) do
    name = evaluate_identifier(identifier)
    {result, definitions1} = evaluate_expr(expr, definitions)
    definitions2 = Map.put(definitions1, name, result)
    {result, definitions2}
  end

  def evaluate_statement(expr, definitions) do
    evaluate_expr(expr, definitions)
  end

  @spec evaluate_expr(ast_expr, definitions) :: {eval_result, definitions}
  def evaluate_expr({:fn, identifiers, statement}, definitions) do
    vars = Enum.map(identifiers, &evaluate_identifier/1)
    {{:closure, vars, statement, definitions}, definitions}
  end

  def evaluate_expr(app, definitions) do
    evaluate_app(app, definitions)
  end

  @spec evaluate_app(ast_app, definitions) :: {eval_result, definitions}
  def evaluate_app({:application, lhs, rhs}, definitions) do
    {lhs_result, definitions1} = evaluate_app(lhs, definitions)
    {rhs_result, definitions2} = evaluate_infix(rhs, definitions1)
    apply_closure(lhs_result, rhs_result, definitions2)
  end

  def evaluate_app(infix, definitions) do
    evaluate_infix(infix, definitions)
  end

  def apply_closure({:closure, [var], statement, captured_definitions}, rhs, definitions) do
    definitions1 = Map.put(captured_definitions, var, rhs)
    {result, _definitions} = evaluate_statement(statement, definitions1)
    {result, definitions}
  end

  @spec apply_closure(eval_fn, eval_result, definitions) :: {eval_result, definitions}
  def apply_closure({:closure, [var | vars], statement, captured_definitions}, rhs, definitions) do
    definitions1 = Map.put(captured_definitions, var, rhs)
    {{:closure, vars, statement, definitions1}, definitions}
  end

  @spec evaluate_infix(ast_infix, definitions) :: {eval_result, definitions}
  def evaluate_infix(infix, definitions)

  def evaluate_infix({:identifier, _line, _charlist} = identifier, definitions) do
    name = evaluate_identifier(identifier)
    {Map.fetch!(definitions, name), definitions}
  end

  def evaluate_infix({:number, _line, _charlist} = number, definitions) do
    {evaluate_number(number), definitions}
  end

  def evaluate_infix({op, lhs, rhs}, definitions)
      when op in [:add_op, :sub_op, :mul_op, :div_op] do
    {lhs_result, definitions1} = evaluate_infix(lhs, definitions)
    {rhs_result, definitions2} = evaluate_infix(rhs, definitions1)

    case op do
      :add_op -> {lhs_result + rhs_result, definitions2}
      :sub_op -> {lhs_result - rhs_result, definitions2}
      :mul_op -> {lhs_result * rhs_result, definitions2}
      :div_op -> {lhs_result / rhs_result, definitions2}
    end
  end

  def evaluate_infix(parenthesised_expr, definitions) do
    evaluate_expr(parenthesised_expr, definitions)
  end
end
