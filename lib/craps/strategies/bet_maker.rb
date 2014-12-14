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
# place_on(6).for(12).press_to(18,24,30,60,90,120,180,210)
# place_on(8).for(12).press_to(18,24,30,60,90,120,180,210)
# place_on(5).after_making_point(1).press_to(15,20,40,80,100,120,180,200)
# place_on(5).working.press_to(15,20,40,80,100,120,180,200)
# place_on(9).for(10).after_making_point(2).press_to(15,20,40,80,100,120,180,200)
# place_on(9).for(10).after_rolls(2).press_to(15,20,40,80,100,120,180,200)
# place_on(6).for(10).after_rolls_beyond_first_point(1).press_to(15,20,40,80,100,120,180,200)
# buy_the(10).for(25).after_making_point(3).press_to(50,75,100,150,200,225,250).after_win(2)
# buy_the(4).for(25).after_making_point(2).press_by_additional(25).after_win(2)
# buy_the(4).for(100).after_making_point(3).full_press.after_win(2).no_press_after_win(4)
# come_out.for(25).at_most(2).with_full_odds
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
  attr_reader   :amount_to_bet
  attr_reader   :number_of_bets
  attr_reader   :bet_when_number_equals_point
  attr_reader   :when_table_is_off
  attr_reader   :stats

  def initialize(player, bet_short_name, number=nil)
    @player = player
    @table = player.table
    @bet_short_name = bet_short_name
    @number = number
    @when_table_is_off = false
    @craps_bet = table.find_bet_box(bet_short_name, number).craps_bet
    @stats = BetMakerStats.new(self)

    @bets_working = false # overrides a normally not makeable? bet
    @bets_off = false # player has made a normally active bet as OFF

    @number_of_bets = nil

    #
    # TODO: might want to make this an enumerator on an
    # array of BetPressers so disjoint sequences can be
    # defined.  e.g. up a unit of 6 for wins 2 thru 5
    # then up a unit of 30 for wins 6 thru 10, no press
    # after win 10
    # 
    @bet_presser = BetPresser.new(player, self, craps_bet)

    @bet_when_point_count = 0
    @bet_when_point_roll_count = 0
    @bet_when_roll_count = 0
    @start_point_roll_count = 0
    @bet_when_number_equals_point = false

    set_start_amount(player.bet_unit)
    reset_counters
  end

  def self.factory(player, bet_short_name, number)
    #
    # create the correct typed BetMaker, then install in the bet_makers array
    # at the appropriate location
    #
    maker = case bet_short_name
      when PassLineBet.short_name
        PassLineBetMaker.new(player)
      when ComeOutBet.short_name
        ComeOutBetMaker.new(player)
      when HardwaysBet.short_name
        HardwaysBetMaker.new(player, number)
      when PlaceBet.short_name, BuyBet.short_name
        PlaceBuyBetMaker.new(player, bet_short_name, number)
      else
        BetMaker.new(player, bet_short_name, number)
    end
  end

  def reset
    reset_counters
    bet_presser.reset
  end

  def reset_counters
    @start_point_count = current_point_count
  end

  def make_bet
    return if not_yet_at_roll_count || not_yet_at_point_count || not_yet_at_point_roll_count
    return if when_table_is_off && table.on?

    make_or_ensure_bet
  end

  def make_or_ensure_bet
    #
    # override this in subclass for more specialized makers
    #
    if already_made_the_required_number_of_bets
      return if bets_off
      # TODO: this ensure_bet isn't really needed because bets that win or lose
      # are always taken down.  So ensure is really here for upping the bet_amount
      # from a strategy that will up the amount without a win or point being made,
      # e.g. after n rolls
      player.ensure_bet(bet_short_name, bet_presser.next_bet_amount, number)
    else
      return if bet_not_normally_makeable unless bets_working
      make_the_bet
    end
  end

  def for(amount)
    set_start_amount(amount)
    self
  end
  
  def at_most(number_of_bets)
    #
    # this is a special case for place bets and come_out come_bets
    #
    @number_of_bets = number_of_bets
    self
  end

  def after_making_point(n)
    @bet_when_point_count = n
    self
  end

  def after_rolls(n)
    @bet_when_roll_count = n
    self
  end

  def after_rolls_beyond_first_point(n)
    @bet_when_point_roll_count = n
    self
  end

  def working
    @bets_working = true # override if bet is normally made
    @bets_off = false
    self
  end

  def on_the_come_out_roll
    @when_table_is_off = true
    self
  end

  def on_the_point
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

  def after_win(win_number)
    bet_presser.start_pressing_at_win = win_number
    self
  end

  def press_to(*bet_amounts)
    bet_presser.sequence(bet_amounts)
    self
  end

  def no_press_after_win(win_number)
    bet_presser.stop_win = win_number
    self
  end

  def press_by_additional(additional_amount)
    bet_presser.incremental(additional_amount)
    self
  end

  def press_by_additional_bet_unit
    bet_presser.incremental(player.bet_unit)
    self
  end

  def full_press
    bet_presser.incremental(BetPresser::PARLAY)
    self
  end

  def and_reset_win_count
    bet_presser.reset
    self
  end

  def to_s
    "#{craps_bet.name}: #{if_on_point}#{starter_s}#{bet_presser}"
  end

  private

  def make_the_bet
    #
    # make the bet and attach any standard callbacks
    #
    bet = player.make_bet(bet_short_name, bet_presser.next_bet_amount, number)
    bet.on(:win) do |amount_won|
      stats.winner(amount_won)
    end
    bet
  end

  def number_is_not_point?
    table.on? && table.table_state.point != number
  end

  def number_is_point?
    table.on? && table.table_state.point == number
  end

  def already_made_the_required_number_of_bets
    player.has_bet?(bet_short_name, number)
  end

  def starter_s
    return '' if @bet_when_point_count.zero? && @bet_when_roll_count.zero?
    "after making %d %s, " % if @bet_when_point_count > 0
      [@bet_when_point_count, "point".pluralize(@bet_when_point_count)]
    elsif @bet_when_roll_count > 0
      [@bet_when_roll_count, "roll".pluralize(@bet_when_roll_count)]
    end
  end

  def if_on_point
    return '' unless bet_when_number_equals_point 
    "when the point is #{number}, "
  end

  def set_start_amount(amount)
    bet_presser.set_start_amount(amount)
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
    @bet_when_roll_count > 0 && (current_roll_count < @bet_when_roll_count)
  end

  def not_yet_at_point_roll_count
    @bet_when_point_roll_count > 0 && (current_point_roll_count < @bet_when_point_roll_count)
  end

  def current_point_count
    table.tracking_bet_stats.pass_line_point.total
  end

  def current_roll_count
    table.shooter.num_rolls
  end

  def current_point_roll_count
    #
    # point_roll count starts at 1 after the first
    # point has been established in a shooter roll
    # this is useful for bettors that want to wait
    # a few rolls after the point is established before
    # making place bets
    table.shooter.num_rolls_after_first_point
  end

end
