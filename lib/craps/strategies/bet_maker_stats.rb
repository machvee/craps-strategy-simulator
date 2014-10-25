class BetMakerStats

  attr_reader :maker

  #
  # maintain these across points made/lost
  #
  attr_reader :total_presses
  attr_reader :max_presses
  attr_reader :max_amount_won # max winnings during a single point
  attr_reader :max_amount_bet # max amount bet across all poins

  attr_reader :current_press_count
  attr_reader :current_winnings

  def initialize(maker)
    @maker = maker
    @total_presses = 0
    @max_presses = 0
    @max_amount_won = 0
    @max_amount_bet = 0
    reset_counters
  end

  def winner(winnings)
    @current_winnings += winnings
    @max_amount_won = current_winnings if current_winnings > max_amount_won
  end

  def press(bet_amount)
    @total_presses += 1
    @current_press_count += 1
    @max_presses = current_press_count if current_press_count > max_presses
    @max_amount_bet = bet_amount if bet_amount > max_amount_bet
  end

  def reset
    reset_counters
  end

  def reset_counters
    @current_press_count = 0
    @current_winnings = 0
  end
end
