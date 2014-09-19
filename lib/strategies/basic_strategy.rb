module Craps
  class BasicStrategy < BaseStrategy
    def make_bets
      #
      # always have a pass line bet $10
      # make a full passline odds bet
      # if the point is a hardways number, make a $5 hardways bet
      # Place $12 bet on 6 and 8 unless either is the point
      #
      player.pass_line_bet if table_state.off? unless player.has_bet?(PassLineBet)
      player.pass_odds_bet if table_state.on? &&
                              player.has_bet?(PassLineBet) unless player.has_bet?(PassOddsBet, table_state.point)
      [4,6,8,10].each do |n|
        player.hardways_bet(n, 5) if table_state.on? && table_state.point?(n) unless player.has_bet?(HardwaysBet, n)
      end
      [6,8].each do |n|
        player.place_bet(n) if table_state.on? unless player.has_bet?(PlaceBet, n) || table_state.point?(n)
      end
    end

    def pass_line_strategy
    end
  end
end
