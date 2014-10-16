class BetPresser
  #
  # bring bet to exact amount in sequence until 
  # amounts array is exhausted, and maintain the last
  # amount until the bet is lost.  Or, press bet by
  # press_unit if not nil.  PARLAY in sequence or pres_unit means
  # full press of winnings to scale begin processing sequence at
  # press_sequence_start_win and stop after press_sequence_stop_win
  #
  #
  attr_reader   :player
  attr_reader   :bet_maker
  attr_reader   :amounts
  attr_reader   :press_unit
  attr_reader   :start_win
  attr_accessor :stop_win
  attr_reader   :start_win_count

  delegate :bet, to: :bet_maker

  FOREVER=-1
  PARLAY=-1

  def initialize(player, bet_maker)
    @player = player
    @bet_maker = bet_maker
    @press_unit = nil
    @amounts = []
    reset
  end

  def sequence(amounts, start_win)
    @amounts = amounts
    @start_win = start_win
    @stop_win = FOREVER
  end

  def incremental(amount, start_win)
    @press_unit = amount
    @start_win = start_win
    @stop_win = FOREVER
  end

  def next_bet_amount
    return bet.amount unless has_press_sequence? # bet amount doesn't change after win

    num_wins = current_bet_wins - start_win_count
    #
    # don't change the bet if we're outside the win/press window
    #
    return bet.amount if num_wins < start_win || (stop_win != FOREVER && num_wins >= stop_win)

    #
    # based on current win sequence and programmed press amount,
    # return the new/current bet amount
    #
    new_bet_amount = if press_unit.present?
      if press_unit == PARLAY
        # until we can figure out the last winnings,
        # just double existing bet amount
        bet.amount * 2
      else
        bet_maker.amount + (press_unit * num_wins)
      end
    else
      #
      # offset into the press_sequence to find the current betting level
      #
      amounts[num_wins > amounts.length ? -1 : num_wins-start_win]
    end
    new_bet_amount
  end

  def reset
    @start_win_count = current_bet_wins
  end

  private

  def bet_win_stat 
    @_ws ||= player.bet_stats.stat_by_name(bet_maker.bet_short_name)
  end

  def has_press_sequence?
    press_unit.present? || amounts.length > 0
  end

  def current_bet_wins
    bet_win_stat.total
  end
end
