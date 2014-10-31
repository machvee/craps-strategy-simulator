class RunStopper
  attr_reader :down_percent # integer 1-99 percent player bank down
  attr_reader :up_percent   # positive integer 1-unlimited precent player bank up
  attr_reader :down_amount  # integer 1-99 percent player bank down
  attr_reader :up_amount    # positive integer 1-unlimited precent player bank up
  attr_reader :points       # int number of points to play
  attr_reader :shooters     # int number of shooter turns (shooter 7's out ends 1 turn)

  attr_reader :player
  attr_reader :table

  delegate :table, to: :player

  def initialize(player, options)
    @player = player
    reset
    @down_percent = options.fetch(:down_percent) {nil}
    if down_percent.present?
      @down_percent = down_percent.to_i * -1
    end
    @up_percent   = options.fetch(:up_percent) {nil}
    if up_percent.present?
      @up_percent = up_percent.to_i
    end
    @down_amount  = options.fetch(:down_amount) {nil}
    if down_amount.present?
      @down_amount = down_amount.to_i * -1
    end
    @up_amount    = options.fetch(:up_amount) {nil}
    if up_amount.present?
      @up_amount = up_amount.to_i
    end
    @shooters     = options.fetch(:shooters) {nil}
    if shooters.present?
      @start_outs = seven_outs
    end
    @points       = options.fetch(:points) {nil}
    if points.present?
      @start_points = point_outcomes
    end
  end

  def reset
    @down_percent =
    @up_percent =
    @down_amount =
    @up_amount =
    @shooters =
    @points = nil
  end

  def stop?
    if up_percent.present?
      return true if is_player_bank_percent_up?
    end
    if down_percent.present?
      return true if is_player_bank_percent_down?
    end
    if up_amount.present?
      return true if is_player_bank_amount_up?
    end
    if down_amount.present?
      return true if is_player_bank_amount_down?
    end
    if shooters.present?
      return true if is_shooters_seven_outs_reached?
    end
    if points.present?
      return true if is_points_made_reached?
    end
    false
  end
  
  private

  def is_player_bank_percent_up?
    percentage_diff >= up_percent
  end

  def is_player_bank_percent_down?
    percentage_diff <= down_percent
  end

  def is_player_bank_amount_up?
    diff = player_rail_delta
    diff >= up_amount
  end

  def is_player_bank_amount_down?
    diff = player_rail_delta
    diff <= down_amount
  end

  def is_shooters_seven_outs_reached?
    (seven_outs - @start_outs) >= shooters
  end

  def is_points_made_reached?
    (point_outcomes - @start_points) >= points
  end

  def percentage_diff
    diff = player_rail_delta
    (((diff*1.0)/player.rail.start_balance)*100.0).truncate
  end

  def player_rail_delta
    player.rail.balance - player.rail.start_balance
  end

  def seven_outs
    table.tracking_bet_stats.pass_line_point.total_lost
  end

  def point_outcomes
    table.tracking_bet_stats.pass_line_point.count # total won and lost
  end
end
