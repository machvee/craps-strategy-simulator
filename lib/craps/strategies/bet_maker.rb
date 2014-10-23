#
# want the dsl grammar to be close to how people think to themselves when at
# the craps table
#
# e.g.
#   
#   1. Keep a pass-line bet at table minimum up whenever the point is off
#   2. I have a conservative strategy when my rail reaches a certain level down (cold table)
#   3. I have a conservative strategy when I've lost several points in a row quickly (cold table)
#   4. I have an aggressive strategy when my rail reaches a certain level up (hot table)
#   3. I have an aggressive strategy when I've won several long points in a row quickly (hot table)
#   2. I'm going to be conservative on pass line odds.  2x for 6,8,5,9, 1x for 4,10
#   3. Always place bet for 12 on 6,8 unless one of those is the point
#   4. Don't press 6,8 after win on first win, but go up a unit each time after that
#   5. After going 12,18,24,30 on 6,8 place win, then switch to 60,90,120,180 and stop there
#   6. After the 5,9,4,10 is rolled twice without me covering it, put a place bet on it.
#   7. Buy the 4 or 10
#   8. Hardways bet for $1 (cold table), or $5 (hot table) on the point number 4,6,8,10
#   9. "Crap check" on the come-out roll
#
# strategy object builder
# no place bet on point number
# place bet priority [6,8,5,9,4,10] cover when available after rules below met
# place bet 6,8 always after point established
# 5 after 1st point won
# 9 after 2nd point won
# 4 after 3rd point won
# 10 after 3rd point won
#
# example grammar:
# pass_line.for(50).with_full_odds
# come_out.for(25).with_full_odds
# hard(8).for(1).full_press_after_win(2)
# hard(10).for(5).working.press_after_win_to(10,20,50)
# pass_line.for(10).with_odds_multiple(2).with_odds_multiple_for_numbers(1, 4,10)
# place_on(6).for(12).press_after_win_to(18,24,30,60,90,120,180,210)
# place_on(8).for(12).press_after_win_to(18,24,30,60,90,120,180,210)
# place_on(5).for(10).after_making_point(1).press_after_win_to(15,20,40,80,100,120,180,200)
# place_on(9).for(10).after_making_point(2).press_after_win_to(15,20,40,80,100,120,180,200)
# place_on(9).for(10).after_rolls(2).press_after_win_to(15,20,40,80,100,120,180,200)
# buy_the(10).for(25).after_making_point(3).press_after_win_to(50,75,100,150,200,225,250)
# buy_the(4).for(25).after_making_point(4).press_by_additional_after_win(25,1)
# buy_the(4).for(100).after_making_point(7).full_press_after_win(2).no_press_after_win(4)
#
class BetMaker

  attr_reader   :player
  attr_reader   :table
  attr_reader   :craps_bet
  attr_reader   :bet_short_name
  attr_reader   :number
  attr_reader   :bets_working
  attr_reader   :bets_off
  attr_reader   :bet_presser
  attr_reader   :start_amount
  attr_reader   :amount_to_bet
  attr_reader   :odds_multiple
  attr_reader   :make_odds_bet
  attr_reader   :bet_when_number_equals_point

  def initialize(player, bet_short_name, number=nil)
    @player = player
    @table = player.table
    @bet_short_name = bet_short_name
    @number = number
    @craps_bet = table.find_bet_box(bet_short_name, number).craps_bet

    @bets_working = false # overrides a normally not makeable? bet
    @bets_off = false # player has made a normally active bet as OFF

    @make_odds_bet = false
    @odds_multiple = [0]*(CrapsDice::POINTS.max+1)

    #
    # TODO: might want to make this an enumerator on an
    # array of BetPressers so disjoint sequences can be
    # defined.  e.g. up a unit of 6 for wins 2 thru 5
    # then up a unit of 30 for wins 6 thru 10, no press
    # after win 10
    # 
    @bet_presser = BetPresser.new(player, craps_bet)

    @bet_when_point_count = 0
    @bet_when_roll_count = 0
    @bet_when_number_equals_point = false

    set_start_amount(nil)
    reset_attrs
  end

  def reset
    reset_attrs
    bet_presser.reset(start_amount)
  end

  def reset_attrs
    @start_point_count = current_point_count
    @start_roll_count = 0
  end

  def make_bet
    return if not_yet_at_roll_count || not_yet_at_point_count
    return if bet_when_number_equals_point && (table.on? && table.table_state.point != number)

    if player.has_bet?(bet_short_name, number)
      return if bets_off
      bet = player.ensure_bet(bet_short_name, bet_presser.next_bet_amount, number)
      bet.maker = self
    else
      return if bet_not_normally_makeable unless bets_working
      if pass_line_point_bet?
        #
        # take down the place bet and let the player's strategy possibly remake the
        # bet on another place bet_box
        #
        player.take_down(place_bet) if (place_bet = player.find_bet(PlaceBet.short_name, number)).present?
      end
      bet = player.make_bet(bet_short_name, bet_presser.next_bet_amount, number)
      bet.maker = self
    end
  end

  def for(amount)
    set_start_amount(amount)
    self
  end

  def after_making_point(n)
    @bet_when_point_count = n
    self
  end

  def after_rolls(n)
    @bet_when_roll_count = n
  end

  def with_no_odds
    @make_odds_bet = false
  end

  def with_full_odds
    valid_odds
    @make_odds_bet = true
    CrapsDice::POINTS.each do |n|
      odds_multiple[n] = table.config.max_odds(n)
    end
    self
  end

  def working
    @bets_working = true # override if bet is normally made
    @bets_off = false
    self
  end

  def on_point
    #
    # useful for hardways betting to bet only on point number
    #
    @bet_when_number_equals_point = true
    self
  end

  def off
    #
    # bet is normally in play but is marked off by player
    # and will not win or lose on the next roll
    #
    @bets_off = true 
    @bets_working = false
    self
  end

  def with_odds_multiple(multiple)
    with_odds_multiple_for_numbers(multiple, *CrapsDice::POINTS)
    self
  end

  def with_single_odds
    with_odds_multiple(1)
  end

  def with_odds_multiple_for_numbers(multiple, *numbers)
    valid_odds
    @make_odds_bet = true
    numbers.each do |n|
      validate_odds_multiple(multiple, n)
      odds_multiple[n] = multiple
    end
    self
  end

  def press_after_win_to(*bet_amounts)
    bet_presser.sequence(bet_amounts, 1)
    self
  end

  def no_press_after_win(win_number)
    bet_presser.stop_win = win_number
    self
  end

  def press_by_additional_after_win(additional_amount, win_number)
    bet_presser.incremental(additional_amount, win_number)
    self
  end

  def full_press_after_win(win_number)
    bet_presser.incremental(BetPresser::PARLAY, win_number)
    self
  end

  def and_reset_win_count
    bet_presser.reset
    self
  end

  private

  def pass_line_point_bet?
    bet_short_name == PassLinePointBet.short_name
  end

  def set_start_amount(amount)
    @start_amount = amount
    bet_presser.amount_to_bet = start_amount
  end

  def bet_not_normally_makeable
    #
    # this call helps us know when to make pass_line bets, come out bets, place and hardways
    # bets. 
    #   - pass_line bets must be made when table is off.
    #   - come out bets must be made when the table is on.
    #   - hardways are off on the come out roll by default unless the player sets
    #     them on, so don't make hardways bets when the table is off.
    #   - place bets are typically off on the come out roll, so don't make them when
    #     the table is off and don't make them on the point number.  Move place_bets that
    #     are already on the point number to on open place bet using the place bet priority
    #     or bring them down
    #
    return !craps_bet.makeable? 
  end

  def not_yet_at_point_count
    @bet_when_point_count > 0 && (current_point_count - @start_point_count < @bet_when_point_count)
  end

  def not_yet_at_roll_count
    @bet_when_roll_count > 0 && (current_roll_count - @start_roll_count < @bet_when_roll_count)
  end

  def current_point_count
    table.tracking_bet_stats.pass_line_point.total
  end

  def current_roll_count
    table.shooter.dice.num_rolls
  end

  def valid_odds
    raise "#{craps_bet} doesn't support an odds bet" unless craps_bet.has_odds_bet?
  end

  def validate_odds_multiple(multiple, number)
    max = table.config.max_odds(number)
    raise "#{multiple} must be between 1 and #{max}" if multiple > max
  end
end
