defmodule SudokuMassSolvingTest do
  use ExUnit.Case
  doctest Sudoku.Board

  alias Sudoku.Solver


  # WARNING
  # This test takes a significant time to run (200-600 seconds on a Macbook Pro)
  @tag timeout: 2_000_000
  test "solve minimum_sudoku" do
    result =
    File.read!("test/minimum_sudoku_17.txt")
    |> String.split("\n", trim: true)
    |> solve_a_bunch_of_puzzles_in_parallel()

    assert result == {49151, 0}
  end

  test "solve top95" do
    result =
    File.read!("test/top95.txt")
    |> String.split("\n", trim: true)
    |> solve_a_bunch_of_puzzles_in_parallel()

    assert result == {95, 0}
  end

  # Very basic parallelisation of solving puzzles by breaking them up into chunks
  def solve_a_bunch_of_puzzles_in_parallel(puzzles) do
    chunk_size = div(length(puzzles), :erlang.system_info(:schedulers_online)) + 1

    puzzles
    |> Enum.chunk_every(chunk_size, chunk_size, [])
    |> Enum.map(&Task.async(fn -> solve_a_bunch_of_puzzles(&1) end))
    |> Enum.map(&Task.await(&1, 2_000_000))
    |> Enum.reduce({0, 0}, fn({solved, failed}, {acc_solved, acc_failed}) ->
                                {acc_solved + solved, acc_failed + failed} end)
  end

  def solve_a_bunch_of_puzzles(puzzles) do
    puzzles
    |> Enum.reduce({0,0}, fn(board_str, {win, loss}) ->
                              case Solver.solve(board_str) do
                                {:solved, _, _} -> {win+1, loss}
                                {_, _,  _}      -> {win, loss+1}
                              end
                          end)
  end

end
