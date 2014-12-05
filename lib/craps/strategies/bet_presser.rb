class BetPresser
  #
  # bring bet to exact amount in sequence until 
  # press_amounts array is exhausted, and maintain the last
  # amount until the bet is lost.  Or, press bet by
  # press_unit if not nil.  PARLAY in sequence or press_unit means
  # full press of winnings to scale. begin processing sequence at
  # start_pressing_at_win and stop after stop_win
  #
  #
  attr_reader   :player
  attr_reader   :maker
  attr_reader   :press_amounts
  attr_reader   :press_unit
  attr_accessor :start_amount
  attr_reader   :start_win_count

  attr_accessor :start_pressing_at_win
  attr_accessor :amount_to_bet
  attr_accessor :stop_win

  FOREVER=-1
  PARLAY=-1

  def initialize(player, maker, craps_bet)
    @player = player
    @maker = maker
    @press_unit = nil
    @press_amounts = []
    @craps_bet = craps_bet
    @start_amount = nil
    @amount_to_bet = nil
    @start_pressing_at_win = 1 # default is press immediately after first win
    @stop_win = FOREVER        # default is not never stop pressing once its started
    reset
  end

  def set_start_amount(amount)
    @start_amount = amount
    @amount_to_bet = start_amount
  end

  def sequence(amounts)
    @press_amounts = amounts
  end

  def incremental(amount)
    @press_unit = amount
  end

  def next_bet_amount
    raise "You haven't set a starting amount to bet on #{@craps_bet}" if amount_to_bet.nil?

    return amount_to_bet unless has_press_sequence? # bet amount doesn't change after win

    num_wins = current_bet_wins - start_win_count

    #
    # don't change the bet if we're outside the win/press window
    #
    if num_wins < start_pressing_at_win || (stop_win != FOREVER && num_wins >= stop_win)
      return amount_to_bet
    end

    #
    # based on current win sequence and programmed press amount,
    # return the new/current bet amount
    #
    new_bet_amount =
      if press_unit.present?
        press_to_amt =
          if press_unit == PARLAY
            # until we can figure the amount just won,
            # just double existing bet amount
            amount_to_bet * 2
          else
            current_pressable_wins = (num_wins - start_pressing_at_win) + 1
            start_amount + (press_unit * current_pressable_wins)
          end
        maker.stats.press(press_to_amt)
        press_to_amt
      else
        if num_wins > press_amounts.length
          press_amounts[-1]
        else
          #
          # offset into the press_sequence to find the current betting level
          #
          press_amounts[num_wins-start_pressing_at_win].tap do |press_to_amt|
            maker.stats.press(press_to_amt)
          end
        end
      end

    @amount_to_bet = new_bet_amount
    amount_to_bet
  end

  def reset
    @start_win_count = current_bet_wins
    @amount_to_bet = @start_amount
  end

  def to_s
    amt = "bet $#{@amount_to_bet} " 

    when_press = if start_pressing_at_win > 1
        ", after %d %s," % [start_pressing_at_win, "win".pluralize(start_pressing_at_win)]
      else
        ''
      end

    the_press = if press_unit.present?
      "then#{when_press} press by #{press_unit}"
     elsif press_amounts.present?
      "then#{when_press} press to #{press_amounts}"
     else
      'with no press'
     end
     
     amt + the_press
  end

  private

  def current_bet_wins
    player_bet_win_stat.total
  end

  def player_bet_win_stat 
    @_pbws ||= player.bet_stats.stat_by_name(@craps_bet.stat_name)
  end

  def has_press_sequence?
    press_unit.present? || press_amounts.length > 0
  end
end
