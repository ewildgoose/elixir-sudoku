defmodule SudokuSquareTest do
  use ExUnit.Case
  doctest Sudoku.Square

  alias Sudoku.Square

  @candidates MapSet.new(1..9)
  @square     %Square{  x: 1,
                        y: 1,
                        box_x: 0,
                        box_y: 1,
                        solution: nil,
                        candidates: @candidates }


  test "elininate" do
    s = @square
    |> Square.eliminate([9,8])

    assert MapSet.equal?(s.candidates, MapSet.new(1..7))
  end

  test "assign" do
    s = @square
    |> Square.assign(4)

    assert MapSet.equal?(s.candidates, MapSet.new([4]))
    assert s.solution == 4
  end

  test "invalid" do
    s = %{@square | candidates: MapSet.new()}

    refute Square.valid?(s)
  end
end
