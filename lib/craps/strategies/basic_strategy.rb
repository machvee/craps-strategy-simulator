class BasicStrategy < BaseStrategy
  def make_bets
    #
    # always have a pass line bet $10
    # make a full passline odds bet
    # if the point is a hardways number, make a $5 hardways bet
    # place $12 bet on 6 and 8 unless either is the point
    #
    pass_line_bet_with_full_odds
    six_and_eight
    hardways_bet_on_the_point(5)
  end

end
