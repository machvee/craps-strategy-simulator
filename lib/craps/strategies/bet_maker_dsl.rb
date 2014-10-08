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
# buy_the(4).for(25).after_making_point(4).press_after_win_to(50,75,100)
# buy_the(4).for(100).after_making_point(7).full_press_after_win
#
#  parse DSL => find or create bet_maker_object => \
#    bet_maker_object[control params, win/rolled_number counts, active (or create) player_bet(s), action_procs]
#

class BetMaker

  attr_reader   :player
  attr_reader   :table
  attr_reader   :place_sequence # order in which to make place bets when they're down

  def initialize(player)
    @player = player
    @bet_makers = []
    @place_sequence = DEFAULT_PLACE_SEQUENCE
  end
end

module BetMakerDsl

  #
  # bet makers are destroyed and created before eah roll.   Win counts for each
  # player bet are preserved across win (unless reset)
  #

  attr_reader   :bet_makers

  DEFAULT_PLACE_SEQUENCE = [6,8,5,9,4,10]

  delegate :table, to: :player

  def place_bet_priority(sequence)
    @place_sequence = sequence
  end

  def pass_line
    @bet_maker = BetMaker.find_or_create_maker(@bet_makers, 'pass_line')
    self
  end

  def all_bets_off
    self
  end

  def and_reset_win_count
    #
    # remove the bet_maker in place, if any, and reset win count
    #
    self
  end

  def come_bets(n)
    @bet_maker = find_or_create_maker(@bet_makers, 'come_out')
    self
  end

  def place_bet_on(number)
    @bet_maker = find_or_create_maker(@bet_makers, 'pass_line')
    self
  end

  def buy_the(number)
    @bet_maker = find_or_create_maker(@bet_makers, 'buy', number)
    self
  end

  def hardways_bet_on(number)
    @bet_maker = find_or_create_maker(@bet_makers, 'hardways', number)
  end

  def for(amount)
    self
  end

  def after_point_established
    self
  end

  def after_making_point(n)
    self
  end

  def with_full_odds
    @odds_bet_multiple = FULL_ODDS
    self
  end

  def with_odds_multiple(multiple)
    self
  end

  def with_odds_multiple_for_numbers(multiple, *numbers)
    self
  end

  def press_after_win_to(*amounts)
    self
  end

  def no_press_after_win(win_number)
    self
  end

  def press_by_amount_after_win(amount, win_number)
    self
  end

  def full_press_after_win(win_number)
    self
  end

  def when_tables_hot
    self
  end

  def when_tables_cold
    self
  end

  def when_tables_up_and_down
    self
  end

  private

  def find_or_create_maker(bet_short_name, number=nil)
    bet_maker = bet_makers.find {|b| b.bet_short_name == bet_short_name && (number.nil? || number == b.number)}
    bet_maker || BetMaker.new(bet_short_name, number)
  end

end

