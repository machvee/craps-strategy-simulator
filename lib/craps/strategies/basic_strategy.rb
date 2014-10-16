class BasicStrategy < BaseStrategy

  def name
    "Basic"
  end

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
    pass_line_bet.for(10).with_full_odds
    if table.is_hot?
      CrapsBets::INSIDE.each {|n| place_bet_on(n).for(10)}
    else
      [6,8].each {|n| place_bet_on(n).for(10)}
    end
    CrapsBets::HARDS.each {|n| hardways_bet_on(n).for(1)}
  end

end
