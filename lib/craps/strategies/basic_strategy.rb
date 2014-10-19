class BasicStrategy < BaseStrategy

  def name
    "Basic"
  end

  def set
    #
    # always have a pass line bet $10
    # make a full passline odds bet
    # if the point is a hardways number, make a $5 hardways bet
    # place $12 bet on 6 and 8 unless either is the point
    # make full inside place bets if table is hot
    # TBD: take full winnings on first 6/8 place after the point, but go
    # up a unit each win after that
    #
    pass_line.for(10).with_full_odds
    CrapsDice::INSIDE.each {|n| place_on(n).for(10).press_after_win_to(15,20,25,30,60,90)}
    CrapsDice::HARDS.each {|n| hard(n).for(1).press_after_win_to(10,25,50)}
  end

end
