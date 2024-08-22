defmodule Sudoku.Strategy do

  @moduledoc """
  Routines to implement algorithmic solving of Sudoku puzzles.
  See: http://www.stolaf.edu/people/hansonr/sudoku/12rules.htm

  Essentially all rules boil down to:

  1. naked singles
  2. hidden singles
  3,4. locked candidates
  5. naked tuples
  6. hidden tuples
  7. grid analysis (X-wings, Swordfish, etc.)
  """

  alias Sudoku.Board
  alias Sudoku.Square
  import Sudoku.Filter

  @doc """
  Apply inferences to board. This is the process of taking a given inference
  and a board structure and updating the board to show the implications of the
  inference.

  Note: This may leave to an invalid board (so always check it's valid after
  applying any inference)

  We understand the following inference rules:

  * :naked_singles
  * :hidden_singles
  * :locked_candidates
  * :naked_tuples
  * :grid_analysis
  * :guess

  and also the backtrack inference which simply returns the board to the previous state

  * :backtrack
  """


  def apply_inference(board, {inference_type, inferences}) when is_list(inferences) do
    inferences
    |> Enum.reduce(board, fn(inference, acc) -> apply_single_inference(acc, inference_type, inference) end)
  end

  def apply_inference(board, {:guess, square = %Square{x: x, y: y}}) do
    solution = Square.solo_candidate(square)
    # If we need to backtrack then implicitly this is no longer a candidate for this square
    backtrack = Board.eliminate(board, [square], solution)

    board = Board.assign(board, x, y, solution)
    %{board | backtrack: backtrack}
  end

  def apply_inference(board, {:backtrack, _reason}) do
    board.backtrack
  end

  def apply_single_inference(board, :naked_singles, square = %Square{x: x, y: y}) do
    solution = Square.solo_candidate(square)
    Board.assign(board, x, y, solution)
  end

  def apply_single_inference(board, :hidden_singles, {_, square = %Square{x: x, y: y}}) do
    solution = Square.solo_candidate(square)
    Board.assign(board, x, y, solution)
  end

  def apply_single_inference(board, :locked_candidates, {unit_type, squares}) do
    affected = other_squares_in_unit(board, squares, unit_type)
    to_eliminate = List.first(squares).candidates
    Board.eliminate(board, affected, to_eliminate)
  end

  def apply_single_inference(board, :naked_tuples, {unit_type, squares}) do
    affected = other_squares_in_unit(board, squares, unit_type)
    to_eliminate = unique_candidates(squares)
    Board.eliminate(board, affected, to_eliminate)
  end

  def apply_single_inference(board, :grid_analysis, {unit_type, squares}) do
    affected = other_squares_in_unit(board, squares, unit_type)
    to_eliminate = List.first(squares).candidates
    Board.eliminate(board, affected, to_eliminate)
  end



  @doc """
  Find naked singles

  A naked symbol is where there is only a single candidate option for a given square
  Essentially this is a formal assignment of this option to this square

  ## Formally
  ### 1. naked singles:

  ```
  1r. (r ^ c ^ k) ^ !(r ^ c ^ !k) --> !(r ^ !c ^ k)
  1c. (r ^ c ^ k) ^ !(r ^ c ^ !k) --> !(!r ^ c ^ k)
  1b. (b ^ (r ^ c) ^ k) ^ !(b ^ (r ^ c) ^ !k) --> !(b ^ !(r ^ c) ^ k)
  ```

  (1r) says, "If a candidate k is possible in a certain intersection of row
  and column (i.e., a cell), and no other candidates are possible in that
  cell, then k is not possible elsewhere in that row."

  (1c) says the same for "that column."

  (1b) says the same for "that block."
  """
  def find_naked_singles(board) do
    results = filter_for_unsolved_squares(board)
    |> filter_squares( &single_candidate?/1 )
    |> no_progress_as_sym

    {:naked_singles, results}
  end

  @doc """
  Find hidden singles

  A hidden single is where there is only a single position possible for a given
  symbol within a unit (but other options might be possible for that square).
  Therefore the given symbol must occupy this square.

  ## Formally
  ### 2. hidden singles:

  ```
  2r. (r ^ c ^ k) ^ !(r ^ !c ^ k) --> !(r ^ c ^ !k)
  2c. (r ^ c ^ k) ^ !(!r ^ c ^ k) --> !(r ^ c ^ !k)
  2b. (b ^ (r ^ c) ^ k) ^ !(b ^ !(r ^ c) ^ k) --> !(b ^ (r ^ c) ^ !k)
  ```

  (2r) says, "If a candidate k is possible in a certain intersection of row
  (and column (i.e., a cell) but is not possible elsewhere in that row, then
  (no other candidates are possible in the that cell."

  (2c) says the same for "elsewhere in that column."

  (2b) says the same for "elsewhere in that block."

  Replacing either the r or the c with b gives us locked candidate rules:
  """
  def find_hidden_singles(board) do
    unsolved = filter_for_unsolved_squares(board)

    hidden_singles = 1..board.per_unit
    |> Enum.map( &(find_hidden_singles(unsolved, &1)) )
    |> Enum.concat
    |> no_progress_as_sym

    {:hidden_singles, hidden_singles}
  end

  # Search squares for hidden singles using the given candidate symbol
  def find_hidden_singles(squares, candidate) do
    # Find squares containing our candidate
    matches = squares
    |> filter_squares( &(candidate_is_possible?(&1, candidate)) )

    # Search for solo candidate symbol in any of col/row/box
    find_hidden_singles(matches, candidate, &group_by_x/1, :col)
    ++ find_hidden_singles(matches, candidate, &group_by_y/1, :row)
    ++ find_hidden_singles(matches, candidate, &group_by_box/1, :box)
  end

  # Search within a specific unit type (row/col/box) for given candidate symbol
  #
  # Assumes it's passed all squares containing a given candidate
  # Groups them into the specific unit via the group_fn
  # Returns any solo square within a single unit
  # (ie exists only one valid position for this symbol within that unit)
  def find_hidden_singles(squares, candidate, group_fn, label) do
    squares
    |> Enum.group_by( group_fn )
    |> Map.values
    |> Enum.filter_map( &(1 == length(&1)),
                        fn([sq]) -> {label, Square.assign_candidates(sq, candidate)} end )
  end


  @doc """
  Find locked candidates

  A locked candidate is where there exists a box with two/three candidates in a row/col.
  a) If they don't exist elsewhere on the row, then they cannot be elsewhere in the box
  b) If they don't exist elsewhere in the box, then they cannot be elsewhere on the row/col

  Intuitively:
  a) If the candidate were elsewhere in the box, it could therefore not be in this row/col, hence
  we would have a contradiction because it would now not be possible anywhere on that row/col

  b) If the candidate were elsewhere in the row/col, it could therefore not be in this box, hence
  we would have a contradiction because it would now not be possible anywhere in this box

  ## Formally
  ### 3. locked candidates, type 1:

  ```
  3r. (r ^ b ^ k) ^ !(r ^ !b ^ k) --> !(!r ^ b ^ k)
  3c. (c ^ b ^ k) ^ !(c ^ !b ^ k) --> !(!c ^ b ^ k)
  ```

  (3r) says, "If a candidate k is possible in a certain intersection of
  row and block but is not possible elsewhere in that row, then it is
  also not possible elsewhere in that block."

  (3c) says the same for columns.

  ### 4. locked candidates, type 2:

  ```
  4r. (r ^ b ^ k) ^ !(!r ^ b ^ k) --> !(r ^ !b ^ k)
  4c. (c ^ b ^ k) ^ !(!c ^ b ^ k) --> !(c ^ !b ^ k)
  ```

  (4r) says, "If a candidate k is possible in a certain intersection of
  row and block but is not possible elsewhere in that block,
  then it is also not possible elsewhere in that row."

  (4c) says the same, but for columns.

  This basic logic generalizes to ALL of the standard types of analysis.
  Here X_n means a "exactly n of X", where X=r is row, X=c is column,
  and X=k is candidate.
  """

  def find_locked_candidates(board) do
    unsolved = filter_for_unsolved_squares(board)

    locked_candidates = 1..board.per_unit
    |> Enum.flat_map( &(find_locked_candidates(unsolved, &1)) )
    |> simplify_inferences(:locked_candidates, board)
    |> no_progress_as_sym

    {:locked_candidates, locked_candidates}
  end

  # Search squares for locked candidates using the given candidate symbol
  def find_locked_candidates(squares, candidate) do
    # Find squares containing our candidate (which haven't been solved)
    matches = squares
    |> filter_squares( &(candidate_is_possible?(&1, candidate)) )

    # Search for solo candidate symbol in any of col/row/box
    find_locked_candidates_1(matches, candidate, &group_by_x/1, :box)
    ++ find_locked_candidates_1(matches, candidate, &group_by_y/1, :box)
    ++ find_locked_candidates_2(matches, candidate, &squares_in_single_col?/1, :col)
    ++ find_locked_candidates_2(matches, candidate, &squares_in_single_row?/1, :row)
  end

  # Find locked candidates for a given candidate symbol
  #
  # Group squares by group_fn (row/col)
  # Then filter for those which are only in a single box
  def find_locked_candidates_1(squares, candidate, group_fn, label) do
    squares
    |> Enum.group_by( group_fn )
    |> Map.values
    |> Enum.filter_map( &squares_in_single_box?/1,
                        fn(squares) -> {label, assign_candidates(squares, candidate)} end )
  end

  # Find locked candidates for a given candidate symbol
  #
  # Group squares by box
  # Then filter for those which are only in a single row/col (using filter_fn)
  def find_locked_candidates_2(squares, candidate, filter_fn, label) do
    squares
    |> Enum.group_by( &group_by_box/1 )
    |> Map.values
    |> Enum.filter_map( filter_fn,
                        fn(squares) -> {label, assign_candidates(squares, candidate)} end )
  end


  @doc """
  Find naked tuples (and hidden tuples)

  A naked tuple is where there are only N choices for N squares in some unit.
  These choices must therefore belong only within these N squares and so can be removed
  from all other squares within the rest of the unit

  Note: some choices might only be valid in some squares.

  Intuitively we can see that if there are only N (total) choices for N squares, then
  those choices cannot exist elsewhere, if they did we would have N-1 choices for N squares

  Note: Hidden tuples are simply the reverse of naked tuples, ie a hidden pair is simply a
  naked tuple of order N-2

  ## Formally:
  ### 5. naked tuples (includes Rules 1r, 1c, and 1b):

  ```
  5r. (r ^ c_n ^ k_n) ^ !(r ^ c_n ^ !k_n) --> !(r ^ !c_n ^ k_n)
  5c. (c ^ r_n ^ k_n) ^ !(c ^ r_n ^ !k_n) --> !(c ^ !r_n ^ k_n)
  5b. (b ^ (r ^ c)_n ^ k_n) ^ !(b ^ (r ^ c)_n ^ !k_n) --> !(b ^ !(r ^ c)_n ^ k_n)
  ```

  (5r) says, "If n candidates are possible in a set of n columns of a given row,
  and no other candidates are possible and in those n cells, then those n
  candidates are not possible elsewhere in that row."

  (5c) says the same for columns. (3b) says the same for blocks.

  ### 6. hidden tuples (includes Rules 2r, 2c, and 2b):

  ```
  6r. (r ^ c_n ^ k_n) ^ !(r ^ !c_n ^ k_n) --> !(r ^ c_n ^ !k_n)
  6c. (c ^ r_n ^ k_n) ^ !(c ^ !r_n ^ k_n) --> !(c ^ r_n ^ !k_n)
  6b. (b ^ (r ^ c)_n ^ k_n) ^ !(b ^ !(r ^ c)_n ^ k_n) --> !(b ^ (r ^ c)_n ^ !k_n)
  ```

  (6r) says, "If n candidates are possible in a set of n columns of a given row,
  and those n candidates are not possible elsewhere in that row, then no other
  candidates are possible in those n cells."

  (6c) says the same for columns. (6b) says the same for blocks.

  Note that exchanging k_n and !k_n and exchanging c_n and !c_n in 6r gives an
  alternative statement of 5r:

  5r'. (r ^ !c_n ^ !k_n) ^ !(r ^ c_n ^ !k_n) --> !(r ^ !c_n ^ k_n)

  This says: "If other than n candidates are possible in other than n cells of a row,
  and those other candidates are not possible in this set of n cells, then this
  set of n candidates is not possible in those other cells. (5r) says the same thing,
  but in a simpler fashion. What this exchanging shows is that naked tuples are the same
  as hidden tuples, just seen from different perspectives.
  """
  def find_naked_tuples(board) do
    unsolved = filter_for_unsolved_squares(board)

    # Search for naked_tuples in any of col/row/box
    naked_tuples = find_naked_tuples_in_group(unsolved, &group_by_y/1, :row)
                    ++ find_naked_tuples_in_group(unsolved, &group_by_x/1, :col)
                    ++ find_naked_tuples_in_group(unsolved, &group_by_box/1, :box)
    |> simplify_inferences(:naked_tuples, board)
    |> no_progress_as_sym

    {:naked_tuples, naked_tuples}
  end


  # Find naked_tuples within a given type of unit
  #
  # Group squares by group_fn (row/col/box)
  # Generate all permutations of squares, in all possible sizes 2..n
  # Compute unique candidates within each permutation
  # Filter for N candidates in permutation of size N squares
  def find_naked_tuples_in_group(squares, group_fn, label) do
    squares
    |> Enum.group_by( group_fn )
    |> Map.values
    |> Enum.flat_map( &generate_all_combinations/1 )
    |> Enum.map( fn(squares) -> {unique_candidates(squares), squares} end )
    |> Enum.filter_map( &n_candidates_in_n_squares?/1,
                        fn({_unique, squares}) -> {label, squares} end )
  end


  @doc """
  Find eliminations through Grid Analysis

  ## Formally:
  ### 7. grid analysis (X-Wings, Swordfish, etc.)

  '''
  7r. (r_n ^ c_n ^ k) ^ !(r_n ^ !c_n ^ k) --> !(!r_n ^ c_n ^ k)
  7c. (r_n ^ c_n ^ k) ^ !(!r_n ^ c_n ^ k) --> !(r_n ^ !c_n ^ k)
  '''

  (7r) says, "If a candidate k is possible in the intersection of n rows and n
  columns but is not possible elsewhere in those n rows, then it is also not
  possible elsewhere in those n columns."

  (7c) says the same, but reversing rows and columns.
  """

    def find_grid_candidates(board) do
    unsolved = filter_for_unsolved_squares(board)

    grid_candidates = 1..board.per_unit
    |> Enum.flat_map( &(find_grid_candidates(unsolved, &1)) )
    |> simplify_inferences(:grid_analysis, board)
    |> no_progress_as_sym

    {:grid_analysis, grid_candidates}
  end

  # Search squares using grid analysis for the given candidate symbol
  def find_grid_candidates(squares, candidate) do
    # Find squares containing our candidate (which haven't been solved)
    matches = squares
    |> filter_squares( &(candidate_is_possible?(&1, candidate)) )

    # Grid analysis (row/col)
    find_grid_candidates_in_group(matches, candidate, &group_by_x/1, &group_by_y/1, :row)
    ++ find_grid_candidates_in_group(matches, candidate, &group_by_y/1, &group_by_x/1, :col)
  end

  # Find locked candidates for a given candidate symbol
  #
  # Group squares by group_fn (row/col)
  # Then filter for those which are only in a single box
  def find_grid_candidates_in_group(squares, candidate, group_fn_1, group_fn_2, label) do
    squares
    |> Enum.group_by( group_fn_1 )
    |> Map.values
    |> generate_all_combinations()
    |> Enum.map( &( {length(&1), Enum.concat(&1)} ) )

    |> Enum.filter_map( fn({num_rows, squares}) -> num_rows == count_groups(squares, group_fn_2) end,
                        fn({_num_rows, squares}) -> {label, assign_candidates(squares, candidate)} end )

  end



  @doc """
  Guess at a candidate to eliminate from a square.

  Considered a last ditch strategy, elimination through constraints is considered more elegant.
  Strategy is simply to select the square with the least candidates remaining.
  """
  def find_guess(board) do
    # {:guess, :no_can_do}
    best_square = filter_for_unsolved_squares(board)
    |> Enum.sort( &( MapSet.size(&1.candidates) <= MapSet.size(&2.candidates) ) )
    |> List.first

    candidate = best_square.candidates
    |> MapSet.to_list
    |> List.first

    {:guess, Square.assign(best_square, candidate)}
  end

  def find_is_solved(board) do
    {:solved, Board.solved?(board)}
  end

  def find_is_invalid_or_backtrack(board) do
    case Board.valid?(board) do
      true -> {:invalid, false}
      false ->  if board.backtrack == nil do
                  {:invalid, true}
                else
                  {:backtrack, :contradiction}
                end
    end

  end

  @doc """
  Examine a sudoku board and return either:
  * {:invalid, true} - (ie no candidates left for a given square and no backtracking opportunity)
  * {:backtrack, :contradition} - implies we must have a backtracking option, but we have reached an invalid board state
  * {:solved, true} - (ie all squares have a solution)
  * An inference rule which allows one or more eliminations to take place
  * A guess - no rule based inferences can be found, so make a guess
  *
  """
  def find_next_step(board) do
    with  {:invalid, false}                   <- find_is_invalid_or_backtrack(board),
          {:solved, false}                    <- find_is_solved(board),
          {:naked_singles,      :no_progress} <- find_naked_singles(board),
          {:hidden_singles,     :no_progress} <- find_hidden_singles(board),
          {:naked_tuples,       :no_progress} <- find_naked_tuples(board),
          {:locked_candidates,  :no_progress} <- find_locked_candidates(board),
          {:grid_analysis,      :no_progress} <- find_grid_candidates(board),
          {:guess,              :no_progress} <- find_guess(board),
    do: raise "Shouldn't be possible to get here."
  end


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
  Many strategies generate inferences that whilst true, may not advance the solution

  Here we filter out any inferences which don't advance the board state
  """
  def simplify_inferences(inferences, rule_type, board)

  def simplify_inferences(inferences, rule_type, board) do
    inferences
    |> Enum.filter( fn(inference) -> apply_inference(board, {rule_type, [inference]}).squares != board.squares end )
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
      _                   -> step_until_finished(board, [next_step|steps])
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
    step = find_next_step(board)

    # IO.puts inspect(step)
    # board |> Board.to_string |> IO.puts

    case step do
      {:invalid, true} -> {{:finished, :invalid}, board}
      {:solved, true} -> {{:finished, :solved}, board}
      # {:guess, _}     -> {{:finished, :cannot_solve}, board}
      _               -> {{:step, step}, apply_inference(board, step)}
    end
  end



  # Internal functions
  #

  # Take a list of squares and assign the given candidates
  # Note: Does NOT assign a solution, just affects the candidates
  def assign_candidates(squares, candidates) do
    squares
    |> Enum.map(fn(sq) -> Square.assign_candidates(sq, candidates) end)
  end

  @doc """
  Find all combinations of size 'num' from the list 'to_pick_from'
  """
  def combination(num, to_pick_from)

  def combination(0, _), do: [[]]
  def combination(_, []), do: []
  def combination(n, [x|xs]) do
     (for y <- combination(n - 1, xs), do: [x|y]) ++ combination(n, xs)
  end

  # Group by some group_fn and then count the number of groupings discovered
  defp count_groups(squares, group_fn) do
    squares
    |> Enum.group_by(group_fn)
    |> Enum.count
  end

  def filter_for_unsolved_squares(board) do
    board.squares
    |> Map.values
    |> filter_squares( &not_solved?/1 )
  end

  # Functions to use as our group_by filter
  def group_by_box(square), do: Board.key(square.box_x, square.box_y)
  def group_by_x(square), do: square.x
  def group_by_y(square), do: square.y

  # Do the number of candidates match the number of squares
  def n_candidates_in_n_squares?({candidates, squares}) do
    Enum.count(candidates) == Enum.count(squares)
  end

  # Replace empty list with the :no_progress symbol
  defp no_progress_as_sym([]), do: :no_progress
  defp no_progress_as_sym(results), do: results


  # Generate all combinations of the given list, of length 2 up to the whole list
  # (combinations are permutations where the order doesn't matter)
  def generate_all_combinations(list) when length(list) <= 1, do: []

  def generate_all_combinations(list) do
    for combination <-
          Enum.reduce(:lists.reverse(list), [[]], fn elem, acc ->
            acc ++ Enum.map(acc, fn combination -> [elem | combination] end)
          end),
        length(combination) > 1 do
      combination
    end
  end

  # Find all the other squares in a given unit (row/col/box),
  # but excluding the given squares
  def other_squares_in_unit(board, other_squares, unit_type) do
    board.squares
    |> Map.values
    |> filter_squares( &( same_rcb?(&1, other_squares, unit_type) ) )
    |> filter_squares( &(exclude_squares?(&1, other_squares)) )
  end

  # Given a group of squares, see if they are all contained in a single row/col/box
  def squares_in_single_box?(squares), do: 1 == count_groups(squares, &group_by_box/1)
  def squares_in_single_col?(squares), do: 1 == count_groups(squares, &group_by_x/1)
  def squares_in_single_row?(squares), do: 1 == count_groups(squares, &group_by_y/1)

  # Return the union of all candidates in all squares
  def unique_candidates(squares) do
    squares
    |> Enum.reduce(MapSet.new, fn(square, acc) -> MapSet.union(square.candidates, acc) end)
  end


end
