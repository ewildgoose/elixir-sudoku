# Sudoku

This is an elixir Sudoku solver, which prefers to use rule based induction to
analyse and solve the board, over guessing.

It is inspired by the post "12 Rules for solving Sudoku" which can be found here:
* http://www.stolaf.edu/people/hansonr/sudoku/12rules.htm

## Heuristics

The following heuristic rules are implemented:

1. naked singles
2. hidden singles
3,4. locked candidates
5. naked tuples
6. hidden tuples
7. grid analysis (X-wings, Swordfish, etc.)

Not implemented (but would like them) are:
* Y wings, XY chains, XYZ chains

Not implemented and no intention to implement (because from an implementation
point of view they are basically just "fancy guessing"):

* chain-based logic


## Performance

Without the guessing rule, ie only using inferences it can solve:
* 41665 of 49151 from minimum_sudoku_17.txt (17 clue puzzles)
* 29 of 95 from top95.txt

With guessing it solves all puzzles, with no puzzles taking any significant
longer time to solve (adds about 20% to processing minimum_sudoku_17.txt, but
of course some puzzles are now solved, hence taking more steps, so it's
expected to take some extra time anyway)

On my Mid 2014, 2.5Ghz Macbook Pro, it takes under 600 seconds to solve the
49151 puzzles from minimum_sudoku_17.txt, which is a rate of around 80
per/second

Overall, solving performance is relatively low compared with an optimised
dancing links in a low level language. In fact Peter Norvig's python based
solver can solve most puzzles in less than 0.01s, so on average this solver is
likely slower.  However, because of the use of heuristics, it's branching
factor appears to be lower, so also it's worst case performance on difficult
puzzles is relatively unchanged

## Why?

The world already has enough sudoku solvers... I wrote this solver after being
inspired by Peter Norvig's article (http://norvig.com/sudoku.html) and also
Bob Hanson's page (https://www.stolaf.edu/people/hansonr/sudoku/12rules.htm).
Why?

This was an exercise in trying to understand "functional programming". To me,
one part of this means unlearning the habit of writing functions with "side-
effects". In the context of our solver this means separating the steps of
computing what rule to apply next and then applying that rule separately. This
makes for easier testing and possibly better code re-usability or readability

The most popular solver example is perhaps Peter Norvig's solver, which is a
depth first solver, essentially making use of an optimisation that you only
need to check squares which have changed against your constraints. Intuitively
this seems a simple algorithm to code, although it does explore your ability
to express cleanly a depth first search, ie there is a need to (cleanly) abort
the upper levels of the search due to some finger of the tree reporting a
contradition.  From a functional point of view this algorithm gets passed some
state and then computes some new state without returning details of the
operations used.

This functional solver is an experiment in maintaining the split between
idempotent computation of "how should we change the state" from the
application of that operation. We succeed in maintaining that split right up
to the top level solver, which basically spins asking for a rule to change the
state, then applying that rule.  Of course this is less efficient than
modifying your state whilst searching for a next move, but offers some
benefits as above.


## Use

The input board should be prepared as a bitstring with either 0, dot or space
as the unknown, and any other character is a symbol to assign to that location

    example:

    iex> {:solved, steps, board} = Sudoku.solve("400010000000309040070005009000060021004070600190050000900400070030608000000030006"); Sudoku.Board.to_string(board, :flat)
    "459716382612389745873245169387964521524173698196852437965421873731698254248537916"

The Sudoku.Strategy module contains solve/1, find_next_step/1, step_board/1,
apply_inference/2. These functions can be used to analyse a board, find an
inference to advance the board and apply that inference to the board.

Solve also returns the inference steps applied to move the board to it's
solution (or discovery that the board is inconsistent)

## TODO

The main heuristic I would like to see implemented is the XY chain (and
perhaps XYZ chain) heuristic. I am hopeful that this will give a moderate
increase in the number of puzzles which can be solved using only heuristics.

I see no benefit in implementing most of the chain based heuristics, since
they will be implemented by "guessing" with backtracking - as this is a
computer solver, we might as well just guess and not backtrack
(immediately)...

