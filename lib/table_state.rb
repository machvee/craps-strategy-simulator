class TableState
  attr_reader :on_off #  true table on, false table off
  attr_reader :point  # 4,5,6,8,9 or 10
  attr_reader :table  # table we belong to

  delegate :dice, to: :table

  def initialize(table)
    @table = table
    table_off
  end

  def update
    if point_established?
      table_on_with_point(last_roll)
    elsif point_made?
      table_off
    elsif seven_out?
      table_off
      table.shooter.done
    end
  end

  def last_roll
    dice.value
  end

  def table_off
    @on_off = false
    @point = nil
  end

  def table_on_with_point(point)
    @on_off = true
    @point = point
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
    off? && dice.points?  && match_roll?(value)
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

  def match_roll?(value)
    value.nil? || rolled?(value)
  end

  def stickman_calls_roll
    if point_made?
      "winner #{last_roll}. pay the line" 
    elsif seven_out?
      "7 out"
    elsif front_line_winner?
      "7 front line winner!"
    elsif yo_eleven?
      "yo 11!" 
    elsif crapped_out?
      "crap!" 
    elsif point_established?
      "the point is #{last_roll}"
    elsif rolled?(5)
      "no field 5"
    end
  end

end
