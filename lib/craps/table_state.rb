class TableState
  attr_reader  :on_off #  true table on, false table off
  attr_reader  :point  # 4,5,6,8,9 or 10
  attr_reader  :table  # table we belong to
  attr_reader  :numbers # history of number of rolls between ON and OFF
  attr_reader  :roll_counter
  attr_reader  :table_heat

  delegate :dice, to: :table
  delegate :numbers, :hot_numbers_average, to: :roll_counter

  delegate :is_hot?, :is_good?, :is_choppy?, :is_cold?,
           :heat_index_in_words,
           :heat_index, to: :table_heat

  def initialize(table, history_length, options={})
    @table = table
    @roll_counter = options[:frequency_counter] || FrequencyCounter.new(history_length)
    @table_heat = options[:table_heat] || TableHeat.new(self, history_length)
    clear_point
  end

  def update
    if point_established?
      table_on_with_point(last_roll)
    elsif point_made?
      table_off
    elsif seven_out?
      table_off
      table.shooter.done
      table.reset_player_strategies
    elsif dice.points?
      roll_counter.bump
    end
  end

  def reset
    roll_counter.clear
    clear_point
  end

  def last_roll
    dice.value
  end

  def table_off
    clear_point
    roll_counter.commit
  end

  def clear_point
    @on_off = false
    @point = nil
  end

  def table_on_with_point(point)
    @on_off = true
    @point = point
    roll_counter.reset
    return
  end

  def seven_out?
    on? && dice.seven?
  end

  def on?
    on_off
  end

  def off?
    !on?
  end

  def point_established?(value=nil)
    off? && dice.points? && match_roll?(value)
  end

  def point_made?(value=nil)
    on? && (last_roll == point) && match_roll?(value)
  end

  def front_line_winner?(value=nil)
    off? && dice.winner? && match_roll?(value)
  end

  def crapped_out?(value=nil)
    off? && dice.craps? && match_roll?(value)
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
    value.nil? || rolled?(value)
  end

  def stickman_calls_roll
    if point_made?
      trailer = "===== #{table.tracking_bet_stats.pass_line_point.current_winning_streak + 1} ====="
      "WINNER!! #{last_roll}. Pay the line.  #{trailer}"
    elsif seven_out?
      ("7 out  " + '='*20)
    elsif winner_seven?
      "7 Front line winner!!"
    elsif yo_eleven?
      "yo 11!!" 
    elsif crapped_out?
      "crap!!" 
    elsif point_established?
      "the point is #{last_roll}"
    elsif rolled?(5)
      "no field 5"
    end
  end
end
