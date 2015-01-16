class Stickman
  attr_reader  :table

  delegate :table_state, :dice, to: :table

  def initialize(table)
    @table = table
    set_watchers
  end

  def call_it
    "%d -- %s" % [last_roll, words(last_roll)]
  end

  def words(roll)
    if point_made?
      "WINNER!!  Pay the line."
    elsif seven_out?
      "OUT"
    elsif winner_seven?
      "FRONT LINE WINNER!!"
    elsif yo_eleven?
      "YO!!" 
    elsif crapped_out?
      "CRAP!!" 
    elsif point_established
      "the point is #{last_roll}"
    elsif rolled?(5)
      "no field 5"
    end
  end

  private

  def set_watchers
    #
    # stickman wants to know when the dice have been rolled, so
    # he can call place you bets, unless its a seven out, in which
    # he will wait until the dealer take the puck down and OFF
    #
    # he will call no more bets when the dice are in the hand of 
    # the shooter
    #
    table_state.watch_for(:any_roll_not_seven_out) {
    }

  end

  def last_roll
    table_state.last_roll
  end

  def front_line_winner?(value=nil)
    table_state.off? && dice.winner? && match_roll?(value)
  end

  def point_made?
    table_state.point_made?
  end

  def seven_out?
    table_state.seven_out?
  end

  def crapped_out?
    off? && dice.craps?
  end

  def yo_eleven?
    front_line_winner?(11)
  end

  def winner_seven?
    front_line_winner?(7)
  end

  def rolled?(value)
    last_roll == value
  end
  
  def point?(value)
    point == value
  end

  def match_roll?(value)
    value.nil? || last_roll == value
  end

end
