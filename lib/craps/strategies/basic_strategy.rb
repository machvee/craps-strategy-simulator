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
    pass_line.for(10).with_full_odds.
      with_odds_multiple_for_numbers(1, 4, 10).
      with_odds_multiple_for_numbers(2, 5, 9)
    place_on(6).for(12).press_after_win_to(18,24,30,60,90,120,180)
    place_on(8).for(12).press_after_win_to(18,24,30,60,90,120,180)

    buy_the(10).for(25).after_making_point(1).press_after_win_to(50,75,100,150,200)

    [4,10].each {|n| hard(n).for(1).on_point.press_after_win_to(10,25,50)}
    [6,8].each {|n| hard(n).for(5).on_point.press_after_win_to(25,50)}
  end

end
