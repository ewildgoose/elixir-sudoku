defmodule SudokuStrategyTest do
  use ExUnit.Case
  doctest Sudoku.Board

  alias Sudoku.Board
  alias Sudoku.Strategy

  @easy1 "000000012000035000000600070700000300000400800100000000000120000080000040050000600"
  @easy1_soln "673894512912735486845612973798261354526473891134589267469128735287356149351947628"

  @gentle "000004028406000005100030600000301000087000140000709000002010003900000507670400000"
  @gentle_soln "735164928426978315198532674249381756387256149561749832852617493914823567673495281"

  @moderate "400010000000309040070005009000060021004070600190050000900400070030608000000030006"
  @moderate_soln "459716382612389745873245169387964521524173698196852437965421873731698254248537916"

  # Believed unique, but cannot be solved by advanced heuristics alone
  @hardest "..53.....8......2..7..1.5..4....53...1..7...6..32...8..6.5....9..4....3......97.."
  @hardest_soln "145327698839654127672918543496185372218473956753296481367542819984761235521839764"

  @locked_candidates_1 "017903600000080000900000507072010430000402070064370250701000065000030000005601720"

  # @locked_candidates_2 "032006100410000000000901000500090004060000071300020005000508000000000519057009860"

  # @grid1 "100000569492056108056109240009640801064010000218035604040500016905061402621000005"

  @non_unique ".....6....59.....82....8....45........3........6..3.54...325..6.................."

  test "easy solution 1" do
    {status, _steps, board} = Strategy.solve(@easy1)

    assert status == :solved
    assert(@easy1_soln == Board.to_string(board, :flat))
  end

  test "gentle solution" do
    {status, _steps, board} = Strategy.solve(@gentle)

    assert status == :solved
    assert(@gentle_soln == Board.to_string(board, :flat))
  end

  test "moderate solution" do
    {status, _steps, board} = Strategy.solve(@moderate)

    assert status == :solved
    assert(@moderate_soln == Board.to_string(board, :flat))
  end

  test "hardest solution" do
    {status, _steps, board} = Strategy.solve(@hardest)

    assert status == :solved
    assert(@hardest_soln == Board.to_string(board, :flat))
  end

  test "non_unique solution" do
    {status, _steps, _board} = Strategy.solve(@non_unique)

    assert status == :solved
  end

  test "find hidden singles" do
    step =
      Board.new("246070038580306274370040600408620703100004006607030400704080069860400007910060842")
      |> Strategy.find_hidden_singles()

    assert(
      step ==
        {:hidden_singles,
         [
           col: %Sudoku.Square{box_x: 1, box_y: 2, candidates: MapSet.new([7]), solution: nil, x: 5, y: 8},
           row: %Sudoku.Square{box_x: 1, box_y: 1, candidates: MapSet.new([7]), solution: nil, x: 3, y: 4},
           box: %Sudoku.Square{box_x: 1, box_y: 1, candidates: MapSet.new([7]), solution: nil, x: 3, y: 4}
         ]}
    )
  end

  test "naked singles" do
    step =
      Board.new("246975138589316274371040695498621753132754986657830421724183569865492317913567842")
      |> Strategy.find_naked_singles()

    assert(
      step ==
        {:naked_singles,
         [
           %Sudoku.Square{box_x: 1, box_y: 0, candidates: MapSet.new([8]), solution: nil, x: 5, y: 2},
           %Sudoku.Square{box_x: 1, box_y: 1, candidates: MapSet.new([9]), solution: nil, x: 5, y: 5},
           %Sudoku.Square{box_x: 1, box_y: 0, candidates: MapSet.new([2]), solution: nil, x: 3, y: 2}
         ]}
    )
  end

  test "naked singles 2" do
    step =
      Board.new("246970038580316274370040690498620753132754986607030421724183569865492317913567842")
      |> Strategy.find_naked_singles()

    assert(
      step ==
        {:naked_singles,
         [
           %Sudoku.Square{box_x: 0, box_y: 0, candidates: MapSet.new([1]), solution: nil, x: 2, y: 2},
           %Sudoku.Square{box_x: 0, box_y: 1, candidates: MapSet.new([5]), solution: nil, x: 1, y: 5},
           %Sudoku.Square{box_x: 2, box_y: 0, candidates: MapSet.new([1]), solution: nil, x: 6, y: 0},
           %Sudoku.Square{box_x: 0, box_y: 0, candidates: MapSet.new([9]), solution: nil, x: 2, y: 1},
           %Sudoku.Square{box_x: 1, box_y: 1, candidates: MapSet.new([8]), solution: nil, x: 3, y: 5},
           %Sudoku.Square{box_x: 1, box_y: 1, candidates: MapSet.new([1]), solution: nil, x: 5, y: 3},
           %Sudoku.Square{box_x: 1, box_y: 0, candidates: MapSet.new([5]), solution: nil, x: 5, y: 0},
           %Sudoku.Square{box_x: 2, box_y: 0, candidates: MapSet.new([5]), solution: nil, x: 8, y: 2}
         ]}
    )
  end

  test "locked candidates" do
    {:locked_candidates, candidates} =
      @locked_candidates_1
      |> Board.new()
      |> Strategy.find_locked_candidates()

    assert candidates ==
              [
                box: [
                  %Sudoku.Square{box_x: 0, box_y: 0, candidates: MapSet.new([3]), solution: nil, x: 2, y: 2},
                  %Sudoku.Square{box_x: 0, box_y: 0, candidates: MapSet.new([3]), solution: nil, x: 1, y: 2}
                ],
                row: [
                  %Sudoku.Square{box_x: 2, box_y: 0, candidates: MapSet.new([3]), solution: nil, x: 6, y: 1},
                  %Sudoku.Square{box_x: 2, box_y: 0, candidates: MapSet.new([3]), solution: nil, x: 8, y: 1}
                ],
                row: [
                  %Sudoku.Square{box_x: 0, box_y: 1, candidates: MapSet.new([9]), solution: nil, x: 1, y: 4},
                  %Sudoku.Square{box_x: 0, box_y: 1, candidates: MapSet.new([9]), solution: nil, x: 2, y: 4}
                ]
              ]
  end

  test "Combinations of squares" do
    assert [[:a, :b], [:a, :b, :c], [:a, :c], [:b, :c]] == Strategy.generate_all_combinations([:a, :b, :c]) |> sort_lol

    assert [[:a, :b]] == Strategy.generate_all_combinations([:a, :b]) |> sort_lol()

    assert [] == Strategy.generate_all_combinations([:a])
  end

  test "Locating other squares in a unit" do
    board = Board.new()
    square1 = board.squares[Board.key(0, 0)]
    square2 = board.squares[Board.key(3, 8)]

    rest_of_units = Strategy.other_squares_in_unit(board, [square1, square2], :col)

    # Assert only in column 0 or 3
    assert Enum.all?(rest_of_units, &(&1.x == 0 || &1.x == 3))

    # Assert the original squares aren't in the results
    refute Enum.any?(rest_of_units, &((&1.x == 0 && &1.y == 0) || (&1.x == 3 && &1.y == 8)))
  end

  def sort_lol(list) when is_list(list) do
    list |> Enum.map(&Enum.sort(&1)) |> Enum.sort
  end
end
