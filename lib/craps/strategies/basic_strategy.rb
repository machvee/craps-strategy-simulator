class BasicStrategy < BaseStrategy
  def make_bets
    #
    # always have a pass line bet $10
    # make a full passline odds bet
    # if the point is a hardways number, make a $5 hardways bet
    # place $12 bet on 6 and 8 unless either is the point
    # make full inside place bets if table is hot
    # TBD: take full winnings on first 6/8 place after the point, but go
    # up a unit each win after that
    #
    pass_line_bet_with_full_odds
    if table.hot_or_cold == 'HOT'
      inside
    else
      six_and_eight 
    end
    hardways_bet_on_the_point(5)
  end

end
