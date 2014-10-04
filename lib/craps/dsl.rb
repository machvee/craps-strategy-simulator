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
# pass_line.for(50).with_full_odds
# come_bet(n).for(25).with_full_odds
# hard_ways_bet_on(8).for(1).full_press_after_wins(2)
# hard_ways_bet_on(10).for(5).press_after_win_to(10,20,50)
# pass_line.for(10).with_odds_multiple(2).with_odds_multiple_for_numbers(1, 4,10)
# place_bet_on(6).for(12).after_point_established.press_after_win_to(18,24,30,60,90,120,180,210)
# place_bet_on(8).for(12).after_point_established.press_after_win_to(18,24,30,60,90,120,180,210)
# place_bet_on(5).for(10).after_making_point(1).press_after_win_to(15,20,40,80,100,120,180,200)
# place_bet_on(9).for(10).after_making_point(2).press_after_win_to(15,20,40,80,100,120,180,200)
# buy_the(10).for(25).after_making_point(3).press_after_win_to(50,75,100,150,200,225,250)
# buy_the(4).for(25).after_making_point(4).press_after_win_to(50,75,100,150,200,225,250)
#

class BetPresser
  #
  # keeps tabs on a bet by name and number, typically place bets and hardways.
  # This is attached to a BetMaker instance.  It keeps track of a bet and the number
  # of consecutive wins.  BetMaker will use the bet_amount method to know how to modify
  # a bet when it is taken down after a win, or while it is active, by returning one
  # of the following:  
  #
  #   1. a new bet amount > 0, possibly higher or lower than previous bet
  #   2. zero, indicating the bet is to be taken down and/or not to be remade
  #
  # the instance stays active on a bet until that bet loses and is taken down, or the instance
  # is destroyed, or a new instance is created matching the bet name and number
  #
  attr_reader   :index
  attr_reader   :press_amounts
  attr_reader   :bet_short_name
  attr_reader   :number

  def initialize(bet_short_name, number)
  end

  def bet_amount
  end
end


class BetMaker
  #
  # specify the bet and initial amount
  # specify when the bet is initially made
  # specify when to press it after win and by how much
  #
  attr_reader   :player
  attr_reader   :table
  attr_reader   :bet
  attr_reader   :odds_bet_multiple
  attr_reader   :amount
  attr_reader   :rules
  attr_reader   :bet_presser

  FULL_ODDS = -1 # this indicates full odds when odds bet is made

  delegate :table, to: :player
  delegate :table_state, to: :table

  def initialize(player)
    @player = player
    @bet = nil
    @amount = nil
    @rules = nil
    @bet_presser = BetPresser.new
    @odds_bet_multiple = nil
  end

end

module BetMakerDSL

  def pass_line
    @bet = 'pass_line'
    self
  end

  def come_bets(n)
    @bet = 'come_out'
    self
  end

  def with_full_odds
    @odds_bet_multiple = FULL_ODDS
    self
  end

  def with_odds_multiple_for_numbers(multiple, *numbers)
    self
  end

  def place_bet_on(number)
    self
  end

  def buy_the(number)
    self
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

  def press_after_win_to(*amounts)
    self
  end

  def no_press_after_wins(n)
    self
  end

  def press_by_amount_after_wins(amount, n)
    self
  end

  def full_press_after_wins(n)
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
end
