class TableState

  include Watchable

  attr_reader  :point   # 4,5,6,8,9 or 10
  attr_reader  :table   # table we belong to

  #
  # betting is allowed from the point in time that the:
  #   dice are in the tray
  #     -- or --
  #   the dice have just completed a roll
  # until the:
  #   shooter takes the dice in hand
  #
  attr_reader  :betting_allowed

  delegate :dice, to: :table

  def initialize(table, history_length, options={})
    @table = table

    watcher(:point_established) {|ts| ts.point_established?}
    watcher(:point_made)        {|ts| ts.point_made?}
    watcher(:seven_out)         {|ts| ts.seven_out?}

    @betting_allowed = true

    table_off
  end

  def on?
    point.present?
  end

  def off?
    point.nil?
  end

  def reset
    clear_point
  end

  def no_more_bets
    @betting_allowed = false
  end

  def place_your_bets
    @betting_allowed = true
  end

  def last_roll
    #
    # this is how all table objects should get the
    # current value of the thrown dice
    #
    dice.value
  end

  def seven_out?
    on? && dice.seven?
  end

  def point_established?
    off? && dice.points?
  end

  def point_made?
    on? && (last_roll == point)
  end

  private

  def pending_state(state)
    @pending = state
  end

  def table_off
    clear_point
  end

  def clear_point
    @point = nil
  end

  def table_on(point)
    @point = point
    point_numbers_rolled.reset
    return
  end

end
