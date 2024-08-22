defmodule SudokuSolverTest do
  use ExUnit.Case

  alias Sudoku.{Board, Solver}

  @easy1 "000000012000035000000600070700000300000400800100000000000120000080000040050000600"
  @easy1_soln "673894512912735486845612973798261354526473891134589267469128735287356149351947628"

  @gentle "000004028406000005100030600000301000087000140000709000002010003900000507670400000"
  @gentle_soln "735164928426978315198532674249381756387256149561749832852617493914823567673495281"

  @moderate "400010000000309040070005009000060021004070600190050000900400070030608000000030006"
  @moderate_soln "459716382612389745873245169387964521524173698196852437965421873731698254248537916"

  # Believed unique, but cannot be solved by advanced heuristics alone
  @hardest "..53.....8......2..7..1.5..4....53...1..7...6..32...8..6.5....9..4....3......97.."
  @hardest_soln "145327698839654127672918543496185372218473956753296481367542819984761235521839764"

  @non_unique ".....6....59.....82....8....45........3........6..3.54...325..6.................."

  test "easy solution 1" do
    {status, _steps, board} = Solver.solve(@easy1)

    assert status == :solved
    assert(@easy1_soln == Board.to_string(board, :flat))
  end

  test "gentle solution" do
    {status, _steps, board} = Solver.solve(@gentle)

    assert status == :solved
    assert(@gentle_soln == Board.to_string(board, :flat))
  end

  test "moderate solution" do
    {status, _steps, board} = Solver.solve(@moderate)

    assert status == :solved
    assert(@moderate_soln == Board.to_string(board, :flat))
  end

  test "hardest solution" do
    {status, _steps, board} = Solver.solve(@hardest)

    assert status == :solved
    assert(@hardest_soln == Board.to_string(board, :flat))
  end

  test "non_unique solution" do
    {status, _steps, _board} = Solver.solve(@non_unique)

    assert status == :solved
  end
end
