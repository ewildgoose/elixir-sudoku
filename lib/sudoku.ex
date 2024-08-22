defmodule Sudoku do
  alias Sudoku.Solver

  @doc """
  Entry point to solve a sudoku board

  Pass in a bitstring where 0, dot, or space is a blank and any other symbol is a board symbol

  Returns: {status, inferences, final_board}

  Note: In the event of a non unique solution, the solver will stop at the first solution found.
  To continue simply extract the state from the final_board.backtrack and pass this back to solve/1 to
  get more solutions (or :invalid if no more solutions to be found)
  """
  def solve(initial) do
    Solver.solve(initial)
  end
end
