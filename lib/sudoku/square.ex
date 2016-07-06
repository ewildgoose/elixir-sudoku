defmodule Sudoku.Square do

  defstruct x: nil,
            y: nil,
            box_x: nil,
            box_y: nil,
            solution: nil,
            candidates: MapSet.new

  @doc """
  Elininate given candidates
  """
  def eliminate(square, candidates) do
    %{square | candidates: delete_candidates(square.candidates, candidates) }
  end

  @doc """
  Remove all candidates, except the given value.
  Assign the given value as the solution
  """
  def assign(square, value) do
    # unless MapSet.member?(square.candidates, value) do
    #   raise "Attempt to assign value: #{value} that is not within the allowed candidate values #{inspect(square.candidates)} for {#{square.x}, #{square.y}}"
    # end

    if MapSet.member?(square.candidates, value) do
      %{square | solution: value, candidates: MapSet.new([value])}
    else
      # Attempt to assign invalid value that is not within the allowed candidate values
    #   raise "Attempt to assign value: #{value} that is not within the allowed candidate values #{inspect(square.candidates)} for {#{square.x}, #{square.y}}"
      %{square | candidates: MapSet.new()}
    end
  end

  @doc """
  Remove all candidates, except the given values.

  Does not assign a solution
  """
  def assign_candidates(square, values = %MapSet{}) do
    # unless MapSet.subset?(values, square.candidates) do
    #   raise "Attempt to assign values that are not within the allowed candidate values"
    # end

    if MapSet.subset?(values, square.candidates) do
      %{square | candidates: values}
    else
      # raise "Attempt to assign values that are not within the allowed candidate values"
      %{square | candidates: MapSet.new()}
    end
  end

  def assign_candidates(square, value) do
    # unless MapSet.member?(square.candidates, value) do
    #   raise "Attempt to assign value that is not within the allowed candidate values"
    # end

    if MapSet.member?(square.candidates, value) do
      %{square | candidates: MapSet.new([value])}
    else
      # raise "Attempt to assign value that is not within the allowed candidate values"
      %{square | candidates: MapSet.new()}
    end
  end

  @doc """
  Fetch the solo candidate remaining
  """
  def solo_candidate(square) do
    candidates = square.candidates

    unless 1 == MapSet.size(candidates) do
      raise "Not a single candidate"
    end

    candidates
    |> MapSet.to_list
    |> List.first
  end

  @doc """
  We have an invalid state if candidates set is empty
  """
  def valid?(square) do
    MapSet.size(square.candidates) > 0
  end


  defp delete_candidates(candidates, eliminate) when is_integer(eliminate) do
    MapSet.delete(candidates, eliminate)
  end

  defp delete_candidates(candidates, eliminate = %MapSet{}) do
    MapSet.difference(candidates, eliminate)
  end

  defp delete_candidates(candidates, eliminate_list) when is_list(eliminate_list) do
    Enum.reduce(eliminate_list,
                candidates,
                fn(i, acc) -> MapSet.delete(acc, i) end )
  end
end