#
# example grammar:
# pass_line.for(50).with_full_odds
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
    raise "#{craps_bet} doesn't support an odds bet" unless craps_bet.has_odds_bet?
  end

  def validate_odds_multiple(multiple, number)
    max = table.config.max_odds(number)
    raise "#{multiple} must be between 1 and #{max}" if multiple > max
  end
end
