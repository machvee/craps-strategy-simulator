class BetMakerStats
  attr_reader :maker
  attr_reader :num_bets
  attr_reader :wins
  attr_reader :losses
  attr_reader :total_won
  attr_reader :total_lost
  attr_reader :total_presses
  attr_reader :max_amount_bet

  #
  # in a single shooter turn
  #
  attr_reader :max_presses
  attr_reader :press_count
  attr_reader :max_amount_won
  attr_reader :current_winnings

  def initialize(maker)
    @maker = maker
    reset
  end

  def won(winnings)
    @wins += 1
    @total_won += winnings
    @current_winnings += winnings
  end

  def lost(amount)
    @losses += 1
    @total_lost += amount
  end

  def shooter_start
    @press_count = 0
    @current_winnings = 0
  end

  def shooter_done
    @max_presses = press_count if press_count > max_presses
    @max_amount_won = current_winnings if current_winnings > max_amount_won
  end

  def reset
    @wins = 0
    @losses = 0
    @total_won = 0
    @total_lost = 0
    @total_presses = 0
    @max_amount_bet = 0
    @max_presses = 0
    @max_amount_won = 0
  end
end
