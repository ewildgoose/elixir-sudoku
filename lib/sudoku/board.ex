defmodule Sudoku.Board do

  defstruct size_x: 9,
            size_y: 9,
            per_box_x: 3,
            per_box_y: 3,
            per_unit: 9,
            squares: nil,
            backtrack: nil

  alias Sudoku.Square
  alias Sudoku.Board
  alias Sudoku.Filter

  # Number of rows to fold candidates into when converting with to_string()
  @rows_per_cell 3

  @line_end "\n"


  ############################################################################
  # Constructors
  #

  def new() do
    size_x = 9
    size_y = 9
    per_box_x = 3
    per_box_y = 3
    per_unit = per_box_x * per_box_y
    candidates = MapSet.new(1..per_unit)

    squares = for x <- 0..(size_x - 1),
                  y <- 0..(size_y - 1), into: Map.new do
      { key(x,y), %Square{  x: x,
                            y: y,
                            box_x: div((x), per_box_x),
                            box_y: div((y), per_box_y),
                            candidates: candidates } }
    end

    %Board{ size_x: size_x,
            size_y: size_y,
            per_box_x: per_box_x,
            per_box_y: per_box_y,
            per_unit: per_unit,
            squares: squares }
  end



  @doc """
  Update board and assign value to square x,y - this in turn will cause the value
  to be eliminated from squares in all other units containing this square
  """
  def assign(board = %Board{squares: squares}, x, y, value) do
    square = squares[key(x,y)]
    squares = Map.put(squares, key(x, y), Square.assign(square, value))

    board = %{board | squares: squares}
    eliminate(board, other_squares_in_units(board, square), value)
  end

  @doc """
  Apply fixed assignments to a board
  """
  def assign_board(board, initial) when is_list(initial) do
    initial
    |> Enum.with_index
    |> Enum.reduce(board, &assign_row/2)
  end

  @doc """
  Apply fixed assignments to a board, from a bitstring

  Accepts any +ve_number/letter as a symbol. 0, ".", "_" and anything else are considered a blank
  """
  def assign_board(board = %Board{size_x: size_x, size_y: size_y}, initial) when is_bitstring(initial) do
    assign_board(board, string_to_lists(initial, size_x, size_y))
  end

  # Internal
  # Take a row [1, nil, nil...] and assign() any squares with numeric elements
  # We ignore nil/0 as blanks
  defp assign_row({assign, y}, board = %Board{size_x: size_x}) when length(assign) == size_x do
    assign
    |> Enum.with_index
    |> Enum.reduce(board, fn
                            ({nil, _}, acc) -> acc
                            ({0, _}, acc)   -> acc
                            ({val, x}, acc) -> assign(acc, x, y, val)
                          end )
  end



  @doc """
  Update board and eliminate elim_values from list of squares elim_from
  """
  def eliminate(board = %Board{squares: squares}, elim_from, elim_values) do
    # iterate over elim_from, evolving our squares by calling &eliminate/4 on each
    squares = elim_from
              |> Enum.reduce(squares, fn(sq, acc) -> eliminate(acc, sq.x, sq.y, elim_values) end)

    %{board | squares: squares}
  end

  # Update square and eliminate elim_values from individual square x,y
  defp eliminate(squares, x, y, elim_values) do
    Map.update!(squares, key(x, y), &(Square.eliminate(&1, elim_values)))
  end

  @doc """
  Return the key used to store a given square in our squares map
  """
  def key(x, y) when is_integer(x) and is_integer(y), do: {x,y}
  # def key(x, y), do: "#{x}:#{y}"

  @doc """
  Create a new board and do initial assignment and population from fixed clues
  """
  def new(initial) do
    new()
    |> assign_board(initial)
  end

  @doc """
  Find all the other squares in all units that contain the given square.
  Excludes the given square from the results returned.
  """
  def other_squares_in_units(%Board{squares: squares}, target) do
    squares
    |> Map.values
    |> Enum.filter( &(Filter.same_unit?(&1, target)) )
  end

  @doc """
  Test if the board is solved? Every square should have a value for solution
  """
  def solved?(%Board{squares: squares}) do
    squares
    |> Map.values
    |> Enum.all?( &(&1.solution  != nil) )
  end

  @doc """
  Ensure that the board is valid? This simply means there is at least
  one candidate option for each cell
  """
  def valid?(%Board{squares: squares}) do
    squares
    |> Map.values
    |> Enum.all?(&Square.valid?/1)
  end



  @doc false
  #Convert symbols 1..z into the range 1..35
  def convert_symbol(<<sym>>) when sym in ?1..?9, do: sym - 48
  def convert_symbol(<<sym>>) when sym in ?a..?z, do: sym - 97 + 10
  def convert_symbol(<<sym>>) when sym in ?A..?Z, do: sym - 65 + 10
  def convert_symbol(_), do: nil

  @doc false
  # Fold a long single line definition of a sudoku board into a list of lists,
  # each list for each row. Convert the string symbols into integers.
  def string_to_lists(input, x \\ 9, y \\ 9) do
    unless(String.length(input) == x * y) do
      raise "Insufficient input data"
    end

    input
    |> String.graphemes
    |> Enum.map(&convert_symbol/1)
    |> Enum.chunk(x)
  end

  ############################################################################
  # Output to string
  #

  @doc """
  Convert the board to a text representation
  """
  def to_string(board, format \\ :square)

  def to_string(board, :flat) do
    for y <- 0..(board.size_y - 1) do
      # Convert a row to n lists
      for x <- 0..(board.size_x - 1) do
        case board.squares[key(x,y)].solution do
          nil -> "."
          s   -> "#{s}"
        end
      end
    end
    |> Enum.concat
    |> Enum.join
  end

  def to_string(board, :square) do
    line_end = @line_end

    digits_per_row = div(board.per_unit, @rows_per_cell) * board.size_x
    break_row_every = div(digits_per_row, board.per_box_x)
    # Our horizontal row break: --+--+--
    row_unit_break = List.duplicate("-", digits_per_row)
                      |> breakup_box(break_row_every, "+")
                      |> Enum.concat( [line_end] )

    for y <- 0..(board.size_y - 1) do
      # Convert a row to n lists
      for x <- 0..(board.size_x - 1) do
        square_to_lists(board.squares[key(x,y)], board.per_unit)
      end
      # rotate to n rows
      |> List.zip
      |> Enum.map( &Tuple.to_list/1 )
      # insert a | to breakup column boxes
      |> breakup_boxes(board.per_box_x, "|")
      |> insert_line_endings(line_end)
    end
    # Insert a row of --|-- to break up row units
    |> Enum.chunk(board.per_box_y)
    |> Enum.intersperse( [[ row_unit_break ]] )
    # |> Enum.concat
  end


  # Insert a | character to break up units
  defp breakup_boxes(rows, every_x, char) do
    for r <- rows do
      breakup_box(r, every_x, char)
    end
  end

  # Insert a | character to break up boxes
  defp breakup_box(row, every_x, char) do
    row
    |> Enum.chunk(every_x)
    |> Enum.intersperse(char)
    # |> List.flatten
  end

  # Insert line endings
  defp insert_line_endings(rows, line_end) do
    for r <- rows do
      r ++ [line_end]
    end
  end

  # Turn the candidates list into list of lists, one for each line of display
  def square_to_lists(%Square{solution: solution}, per_unit) when not is_nil(solution) do
    List.duplicate(" ", per_unit - 1)
    |> List.insert_at( div(per_unit, 2), "#{solution}")
    |> Enum.chunk( div(per_unit, @rows_per_cell) )
  end

  def square_to_lists(%Square{candidates: candidates}, per_unit) do
    1..per_unit
    |> Enum.map( fn(c) -> if(MapSet.member?(candidates, c), do: "#{c}", else: " ") end )
    |> Enum.chunk( div(per_unit, @rows_per_cell) )
  end

end
