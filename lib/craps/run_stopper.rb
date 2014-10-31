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
    (up_percent.present?   && is_player_bank_percent_up?)      ||
    (down_percent.present? && is_player_bank_percent_down?)    ||
    (up_amount.present?    && is_player_bank_amount_up?)       ||
    (down_amount.present?  && is_player_bank_amount_down?)     ||
    (shooters.present?     && is_shooters_seven_outs_reached?) ||
    (points.present?       && is_points_made_reached?)
  end
  
  def explain
    "player run stopped because " + @msg
  end

  private

  def is_player_bank_percent_up?
    stopping = percentage_diff >= up_percent
    if stopping
      @msg = "player's bank (#{player.rail.balance}) is up by #{down_percent}%"
    end
    stopping
  end

  def is_player_bank_percent_down?
    stopping = percentage_diff <= down_percent
    if stopping
      @msg = "player's bank (#{player.rail.balance}) is down by #{down_percent.abs}%"
    end
    stopping
  end

  def is_player_bank_amount_up?
    diff = player_rail_delta
    stopping = diff >= up_amount
    if stopping
      @msg = "player's bank (#{player.rail.balance}) is up by #{down_amount}"
    end
    stopping
  end

  def is_player_bank_amount_down?
    diff = player_rail_delta
    stopping = diff <= down_amount
    if stopping
      @msg = "player's bank (#{player.rail.balance}) is down by #{down_amount}"
    end
    stopping
  end

  def is_shooters_seven_outs_reached?
    stopping = (seven_outs - @start_outs) >= shooters
    if stopping
      @msg = "#{shooters} #{"shooters".pluralize(shooters)} have completed their turn" 
    end
    stopping
  end

  def is_points_made_reached?
    stopping = (point_outcomes - @start_points) >= points
    if stopping
      @msg = "#{points} #{"point".pluralize(points)} have been established" 
    end
    stopping
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
