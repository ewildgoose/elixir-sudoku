
  alias Sudoku.Board
  alias Sudoku.Square
  alias Sudoku.Strategy
  import Sudoku.Filter

    # result =
    # File.read!("test/top95.txt")
    # |> String.split("\n", trim: true)
    # |> Enum.reduce({0,0}, fn(board_str, {win, loss}) ->
    #                     case Strategy.solve(board_str) do
    #                       {:solved, _, _} -> {win+1, loss}
    #                       {_, _,  _}      -> {win, loss+1}
    #                     end
    #                 end)

    # IO.puts inspect(result)

    Strategy.solve("000004028406000005100030600000301000087000140000709000002010003900000507670400000")