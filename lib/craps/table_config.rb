class TableConfig
  attr_reader    :max_bet
  attr_reader    :min_bet
  attr_reader    :house_bank

  def initialize(min_bet=10, max_bet=5000)
    @min_bet = min_bet
    @max_bet = max_bet
    @house_bank = 1_000_000
  end

  def max_odds(number)
    case number
      when 4,10
        3
      when 5,9
        4
      when 6,8
        5
    end
  end

  def payoff_odds(craps_bet, number)
    #
    # each table can vary how they pay out different bets
    #
    # [pay this number of units, for every this many units bet]
    #
    case craps_bet
      when PassLineBet, PassLinePointBet, ComeOutBet, ComeBet
        [1,1]
      when PassOddsBet, ComeOddsBet
        case number
          when 4,10
            [2,1]
          when 5,9 
            [3,2]
          when 6,8 
            [6,5]
        end
      when FieldBet
        case number
          when 2
            [2,1]
          when 12 
            [3,1]
          else
            [1,1]
        end
      when PlaceBet
       case number
          when 4,10 
            [2,1]
          when 5,9 
            [7,5]
          when 6,8 
            [7,6]
        end
      when HardwaysBet
        case number
          when 4,10 
            [7,1]
          when 6,8 
            [9,1]
        end
      when CeBet
        case number
          when 2,3,12
            [3,1]
          when 11
            [7,1]
          when nil # combined
            [5,1]
        end
      when AnyCrapsBet
        [8,1]
      when AnySevenBet
        [5,1]
      when ElevenBet
        [16,1]
      when AceDeuceBet
        [16,1]
      when AcesBet
        [31,1]
      when TwelveBet
        [31,1]
    end
  end
end
