#
# example grammar:
# pass_line.with_full_odds
# come_out.for(25).with_full_odds
# pass_line.for(10).with_odds_multiple(2).with_odds_multiple_for_numbers(1, 4,10)
# come_out.for(25).at_most(2).with_full_odds
#
# OddsBetMaker  additional place/buy bet duties
#
#    take_down place/buy bets unless working
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
    bet = make_the_bet
    bet.on(:morph) do
      point_number = table.last_roll
      create_odds_bet(bet.amount, point_number) if make_odds_bet
      take_down_any_place_buy_bets_unless_working(point_number)
    end
  end

  def take_down_any_place_buy_bets_unless_working(number)
    place_buy_bet_to_remove = get_the_current_place_buy_bet(number)
    if place_buy_bet_to_remove.present? 
      # TODO: need to reverse lookup maker and check maker.working, and if true, don't take down
      player.take_down(place_buy_bet_to_remove)
    end
  end

  def create_odds_bet(amount, point_number)
    #
    # build an odds bet based on the BetMaker odds multiples
    #
    point_bet_box = table.find_bet_box(craps_bet.morph_bet_name, point_number)
    odds_bet_box = table.find_bet_box(point_bet_box.craps_bet.odds_bet_short_name, point_number)
    odds_bet = odds_bet_box.new_player_bet(player, odds_multiple[point_number] * amount)
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

  def get_the_current_place_buy_bet(number)
    player.find_bet(PlaceBet.short_name, number) ||
    player.find_bet(BuyBet.short_name, number)
  end
end
