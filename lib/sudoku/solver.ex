defmodule Sudoku.Solver do
  alias Sudoku.{Board, Strategy}

  @doc """
  Apply inferences to board. This is the process of taking a given inference
  and a board structure and updating the board to show the implications of the
  inference.

  Note: This may leave to an invalid board (so always check it's valid after
  applying any inference)

  We understand the following inferences:

  * {:naked_singles, one_or_more_inferences}
  * {:hidden_singles, one_or_more_inferences}
  * {:locked_candidates, one_or_more_inferences}
  * {:naked_tuples, one_or_more_inferences}
  * {:grid_analysis, one_or_more_inferences}
  * {:guess, %Square{}}

  and also the backtrack inference which simply returns the board to the previous state

  * {:backtrack, _}
  """
  defdelegate apply_inference(board, inference), to: Strategy

  @doc """
  Entry point to solve a sudoku board

  Pass in either:
  * a bitstring where 0, dot, or space is a blank and any other symbol is a board symbol
  * a Sudoku.Board type

  Returns: {status, inferences, final_board}

  Note: In the event of a non unique solution, the solver will stop at the first solution found.
  To continue simply extract the state from the final_board.backtrack and pass this back to solve/1 to
  get more solutions (or :invalid if no more solutions to be found)
  """
  def solve(initial = %Board{}) do
    step_until_finished(initial, [])
  end

  def solve(initial) do
    step_until_finished(Board.new(initial), [])
  end

  @doc """
  Iteratively compute a next inference to advance the board (including guessing) and then apply that inference
  to advance the board state.

  Stops when we either solve the board, or run out of ways to advance, eg the board is invalid
  """
  def step_until_finished(board, steps) do
    {next_step, board} = step_board(board)

    # IO.puts inspect(next_step)
    # board |> Board.to_string |> IO.puts

    case next_step do
      {:finished, status} -> {status, steps, board}
      _ -> step_until_finished(board, [next_step | steps])
    end
  end

  @doc """
  Advance the board by one inference step (including guessing).

  Computes the next inference and then applies it to the board state to get a new state.

  Returns:
  * {{:finished, why}, final_board}
  * {{:step, step_details}, next_board}
  """
  def step_board(board) do
    step = Strategy.find_next_step(board)

    # IO.puts inspect(step)
    # board |> Board.to_string |> IO.puts

    case step do
      {:invalid, true} -> {{:finished, :invalid}, board}
      {:solved, true} -> {{:finished, :solved}, board}
      # {:guess, _}     -> {{:finished, :cannot_solve}, board}
      _ -> {{:step, step}, apply_inference(board, step)}
    end
  end
end
