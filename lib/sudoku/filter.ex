defmodule Sudoku.Filter do
  alias Sudoku.Square

  @doc """
  Filter a list of squares, applying the given filter function
  Returns those where the filter function is true
  """
  def filter_squares(squares, filter_fn) do
    squares
    |> Enum.filter( fn(square) -> filter_fn.(square) end )
  end

  @doc """
  Is candidate value a valid option in this square
  """
  def candidate_is_possible?(square, candidate) do
    MapSet.member?(square.candidates, candidate)
  end

  def exclude_squares?(_square = %Square{x: x, y: y}, excluded) do
    excluded
    |> Enum.all?( fn(excl) -> (excl.x != x) or (excl.y != y) end )
  end

  @doc """
  Is square solved
  """
  def not_solved?(square) do
    square.solution == nil
  end

  @doc """
  Is there only a single candidate option left for this square
  """
  def single_candidate?(square) do
    1 == Enum.count(square.candidates)
  end

  @doc """
  Filter function to find all other squares in all units containing target
  """
  def same_unit?(square, target) do
    # Exclude our target square
    !(square.x == target.x and square.y == target.y)
    # x or y match, or in same unit
    and (square.x == target.x or square.y == target.y or same_box?(square, target))
  end

  @doc """
  Convenience method to compare two squares are in the same box
  """
  def same_box?(square1, square2) do
    # (square1.box_x == square2.box_x) and (square1.box_y == square2.box_y)
    not ((square1.box_x != square2.box_x) or (square1.box_y != square2.box_y))
  end

  @doc """
  Filter function to find all other squares in specific unit type containing one of the target squares
  """
  def same_rcb?(square, targets, :row) do
    Enum.any?(targets, &(square.y == &1.y))
  end

  def same_rcb?(square, targets, :col) do
    Enum.any?(targets, &(square.x == &1.x))
  end

  def same_rcb?(square, targets, :box) do
    Enum.any?(targets, &(same_box?(square, &1)))
  end


end