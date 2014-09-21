class BasicStrategy < BaseStrategy
  def make_bets
    #
    # always have a pass line bet $10
    # make a full passline odds bet
    # if the point is a hardways number, make a $5 hardways bet
    # Place $12 bet on 6 and 8 unless either is the point
    #
    player.pass_line if table_state.off? unless player.has_bet?('pass_line')
    player.pass_odds if \
      table_state.on? &&
      player.has_bet?('pass_line_point', table_state.point) &&
      !player.has_bet?('pass_odds', table_state.point)
    [4,6,8,10].each do |n|
      player.hardways(n, 5) if table_state.on? &&
        table_state.point?(n) unless player.has_bet?('hardways', n)
    end
    [6,8].each do |n|
      player.place(n) if table_state.on? &&
        (!player.has_bet?('place', n) || table_state.point?(n))
    end
  end

  def pass_line_strategy
  end
end
