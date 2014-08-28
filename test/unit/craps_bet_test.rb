require 'test_helper'

class CrapsBetTest < Test::Unit::TestCase
  class CoolBet < CrapsBet
    def name
      "Cool Bet on #{number}"
    end
  end

  def setup
    table_config = mock('table_config')
    table_config.expects(:payoff_odds).at_least_once.with(CoolBet, 2).returns([20,1])
    @table = mock('table')
    @table.expects(:config).at_least_once.returns(table_config)
    @cool_bet = CoolBet.new(@table, 2)
  end

  def test_cool_bet
    assert_equal "Cool Bet on 2", @cool_bet.name
    assert !@cool_bet.on?
  end
end
