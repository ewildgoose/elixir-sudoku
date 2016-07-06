defmodule SudokuBoardTest do
  use ExUnit.Case
  doctest Sudoku.Board

  alias Sudoku.Board

  @candidates MapSet.new(1..9)

  test "elininate" do
    board = Board.new()
    sq1 = board.squares[Board.key(0,0)]
    sq2 = board.squares[Board.key(4,5)]

    # update the board for those squares
    board = Board.eliminate(board, [sq1, sq2], [8,9])

    # fetch our two modified squares
    sq1 = board.squares[Board.key(0,0)]
    sq2 = board.squares[Board.key(4,5)]

    # Other (non modified) squares
    others = board.squares
    |> Map.drop([Board.key(0,0), Board.key(4,5)])
    |> Map.values

    # Check nothing eliminated from all other candidates
    assert Enum.all?(others, &( MapSet.equal?(&1.candidates, @candidates) ))

    # Check [8,9] eliminated from candidates
    candidates39 = MapSet.new(1..7)
    assert MapSet.equal?(sq1.candidates, candidates39)
    assert MapSet.equal?(sq2.candidates, candidates39)
  end

  test "assign" do
    board = Board.new()
    # Update board, assign a value to a square
    board = Board.assign(board, 4, 0, 1)

    squares = board.squares
    eliminated = MapSet.new(2..9)

    # Check solution is set
    assert MapSet.equal?( squares[Board.key(4,0)].candidates, MapSet.new([1]) )
    assert squares[Board.key(4,0)].solution == 1

    # Check other candidates have been eliminated
    assert MapSet.equal?( squares[Board.key(1,0)].candidates, eliminated )
    assert MapSet.equal?( squares[Board.key(8,0)].candidates, eliminated )

    assert MapSet.equal?( squares[Board.key(4,4)].candidates, eliminated )
    assert MapSet.equal?( squares[Board.key(4,8)].candidates, eliminated )

    assert MapSet.equal?( squares[Board.key(3,1)].candidates, eliminated )
    assert MapSet.equal?( squares[Board.key(5,2)].candidates, eliminated )

    # Check other cells not changed
    assert MapSet.equal?( squares[Board.key(0,1)].candidates, @candidates )
    assert MapSet.equal?( squares[Board.key(0,4)].candidates, @candidates )
  end

  test "impossible assign" do
    board = Board.new()
    sq1 = board.squares[Board.key(0,0)]
    # update the board for those squares
    board = Board.eliminate(board, [sq1], [8,9])

    # Update board, assign an invalid value to a square
    board = Board.assign(board, 0, 0, 9)

    refute Board.valid?(board)
  end

  test "valid" do
    board = Board.new()
    assert Board.valid?(board)
  end

  test "invalid" do
    board = Board.new()
    sq1 = board.squares[Board.key(0,0)]
    # update the board for those squares
    board = Board.eliminate(board, [sq1], 1..9 |> Enum.to_list)

    refute Board.valid?(board)
  end
end
