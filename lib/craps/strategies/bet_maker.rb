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
# come_bet(n).for(25).with_full_odds
# hard_ways_bet_on(8).for(1).full_press_after_win(2)
# hard_ways_bet_on(10).for(5).press_after_win_to(10,20,50)
# pass_line.for(10).with_odds_multiple(2).with_odds_multiple_for_numbers(1, 4,10)
# place_bet_on(6).for(12).after_point_established.press_after_win_to(18,24,30,60,90,120,180,210)
# place_bet_on(8).for(12).after_point_established.press_after_win_to(18,24,30,60,90,120,180,210)
# place_bet_on(5).for(10).after_making_point(1).press_after_win_to(15,20,40,80,100,120,180,200)
# place_bet_on(9).for(10).after_making_point(2).press_after_win_to(15,20,40,80,100,120,180,200)
# buy_the(10).for(25).after_making_point(3).press_after_win_to(50,75,100,150,200,225,250)
# buy_the(4).for(25).after_making_point(4).press_by_additional_after_win(25,1)
# buy_the(4).for(100).after_making_point(7).full_press_after_win(2).no_press_after_win(4)
#
#  parse DSL => find or create bet_maker_object => \
#    bet_maker_object[control params, win/rolled_number counts, active (or create) player_bet(s), action_procs]
#
class BetMaker

  attr_reader   :player
  attr_reader   :table
  attr_reader   :bet
  attr_reader   :odds_bet
  attr_reader   :bet_short_name
  attr_reader   :bet_presser

  def initialize(player, bet_short_name, number=nil)
    @player = player
    @table = player.table
    @bet_short_name = bet_short_name
    @number = number

    @bet = @odds_bet = nil

    @amount = nil
    @make_odds_bet = false
    @odds_multiple = [0]*(CrapsDice::POINTS.max+1)

    #
    # TODO: might want to make this an enumerator on an
    # array of BetPressers so disjoint sequences can be
    # defined.  e.g. up a unit of 6 for wins 2 thru 5
    # then up a unit of 30 for wins 6 thru 10, no press
    # after win 10
    # 
    @bet_presser = BetPresser.new(player, self)

    #
    # put the bet down only after the point is established?
    #
    @bet_when_table_state_on = true
    @bet_when_point_count = 0

    #
    # keep track of current point made in shooters roll
    #
    @start_point_count = current_points_won
  end

  def make_bet
    return if not_yet_at_point_count
    YOU ARE HERE what about the bet validation table on off?
    return if table.table_state.off? && @bet_when_table_state_on

    if player.has_bet?(bet_short_name, @number)
      player.ensure_bet(bet_short_name, bet_presser.next_bet_amount, @number)
    else
      @bet = player.make_bet(bet_short_name, @amount, @number)
    end
  end

  def for(amount)
    @amount = amount
    self
  end

  def before_point_established
    @bet_when_table_state_on = false
    self
  end

  def after_making_point(n)
    @bet_when_point_count = n
    self
  end

  def with_full_odds
    @make_odds_bet = true
    CrapsDice::POINTS.each do |n|
      @odds_multiple[n] = table.config.max_odds(n)
    end
    self
  end

  def with_odds_multiple(multiple)
    with_odds_multiple_for_numbers(multiple, *CrapsDice::POINTS)
    self
  end

  def with_odds_multiple_for_numbers(multiple, *numbers)
    @make_odds_bet = true
    numbers.each do |n|
      validate_odds_multiple(multiple, n)
      @odds_multiple[n] = multiple
    end
    self
  end

  def press_after_win_to(*amounts)
    bet_presser.sequence(amounts, 1)
    self
  end

  def no_press_after_win(win_number)
    bet_presser.stop_win = win_number
    self
  end

  def press_by_additional_after_win(amount, win_number)
    bet_presser.incremental(amount, win_number)
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

  def not_yet_at_point_count
    @bet_when_point_count > 0 && (current_point_count - @starting_point_count < @bet_when_point_count)
  end

  def current_points_won
    table.tracking_bet_stats.pass_line_point.total
  end

  def validate_odds_multiple(multiple, number)
    max = table.config.max_odds(number)
    raise "#{multiple} must be between 1 and #{max}" if multiple > max
  end
end
