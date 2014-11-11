#
# example grammar:
# pass_line.with_full_odds
# come_out.for(25).with_full_odds
# pass_line.for(10).with_odds_multiple(2).with_odds_multiple_for_numbers(1, 4,10)
# come_out.for(25).at_most(2).with_full_odds
#
class OddsBetMaker < BetMaker

  attr_reader   :odds_multiple
  attr_reader   :make_odds_bet

  def initialize(player, bet_short_name, number=nil)
    @make_odds_bet = false
    @odds_multiple = [0]*(CrapsDice::POINTS.max+1)
    super
  end

  def make_or_ensure_bet
    return if bet_not_normally_makeable
    return if already_made_the_required_number_of_bets
    take_down_any_place_bets_on_the_new_point_number
    bet = player.make_bet(bet_short_name, bet_presser.next_bet_amount, number)
    bet.maker = self
  end

  def create_odds_bet(point_craps_bet, amount, point_number)
    #
    # build an odds bet based on the BetMaker odds multiples
    #
    odds_bet_box = table.find_bet_box(point_craps_bet.odds_bet_short_name, point_number)
    odds_bet = odds_bet_box.new_player_bet(player, odds_multiple[point_number] * amount)
    odds_bet.maker = self
  end

  def with_no_odds
    @make_odds_bet = false
    self
  end

  def with_full_odds
    valid_odds
    @make_odds_bet = true
    CrapsDice::POINTS.each do |n|
      odds_multiple[n] = table.config.max_odds(n)
    end
    self
  end

  def with_single_odds
    with_odds_multiple(1)
  end

  def with_odds_multiple(multiple)
    with_odds_multiple_for_numbers(multiple, *CrapsDice::POINTS)
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

  def to_s
    super + "#{odds_bet_s}"
  end

  private

  def take_down_any_place_bets_on_the_new_point_number
    return if table.off?
    #
    # take down any place/buy bet and let the player's strategy possibly remake the
    # bet on another place bet_box
    #
    [PlaceBet, BuyBet].each do |bclass|
      place_bet = player.find_bet(bclass.short_name, table.table_state.point)
      if place_bet.present?
        player.take_down(place_bet) 
      end
    end
  end

  def odds_bet_s
    return '' unless make_odds_bet
    h = Hash.new {|h,k| h[k] = []}
    odds_multiple.each_with_index do |n,i|
      next if n.zero?
      h["%dx" % n] << i
    end
    ', with odds bet: ' + h.map {|k,v| "#{k}: #{v.map(&:to_s).join(',')}"}.join('  ')
  end

  def valid_odds
    #
    # this is misleading because its the point number morph of this bet that
    # supports odds, not the come out/pass line bet
    #
    raise "#{craps_bet} doesn't support an odds bet" unless craps_bet.has_odds_bet?
  end

  def validate_odds_multiple(multiple, number)
    max = table.config.max_odds(number)
    raise "#{multiple} must be between 1 and #{max}" if multiple > max
  end
end
