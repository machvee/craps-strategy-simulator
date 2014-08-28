require 'test_helper'

class CrapsBetTest < Test::Unit::TestCase
  class CoolBet < CrapsBet
    def name
      "Cool Bet on #{number}"
    end
  end

  def setup
    @number = 2
    @table_config = mock('table_config')
    @table = mock('table')
    @cool_bet = CoolBet.new(@table, @number)
  end

  def test_cool_bet
    assert_equal "Cool Bet on #@number", @cool_bet.name
    assert_equal @number, @cool_bet.number
    assert @cool_bet.on?, "default should be always on"
    assert @cool_bet.bet_remains_after_win?, "default expected that bet remains on table after win"
    assert @cool_bet.player_can_set_off?, "default expected that player can mark bet off"
  end

  def test_bet_follow_table
    @cool_bet.expects(:table_on_status).twice.returns(CrapsBet::OnStatus::FOLLOW)
    @table.expects(:on?).returns(false).once
    assert !@cool_bet.on?, "bet should be off because table is off"
    @table.expects(:on?).returns(true).once
    assert @cool_bet.on?, "bet should be on because table is on"
  end

  def test_bet_payout
    @table_config.expects(:payoff_odds).at_least_once.with(@cool_bet, @number).returns([20,1])
    @table.expects(:config).at_least_once.returns(@table_config)
    assert_equal [20,1], @cool_bet.payout
  end

  def test_made_the_number
    @table.expects(:last_roll).once.returns(@number)
    assert @cool_bet.made_the_number?, "table last_roll is #@number, should've made the number"
    not_number=@number+1
    @table.expects(:last_roll).once.returns(not_number)
    assert !@cool_bet.made_the_number?, "table last_roll is #{not_number}, shouldn't have made the number"
  end

  def test_validate_player_already_has_that_bet
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(CrapsBetTest::CoolBet, @number).returns(true).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_validate_player_must_bet_min_bet
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(CrapsBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount + 1).at_least_once

    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_validate_player_must_bet_under_max_bet
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(CrapsBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount).at_least_once
    @table.expects(:max_bet).returns(bet_amount-1).at_least_once

    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_betting_multiple_not_a_multiple_of_for_every_payout
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(CrapsBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount).at_least_once
    @table.expects(:max_bet).returns(bet_amount+1).at_least_once

    @table_config.expects(:payoff_odds).at_least_once.with(@cool_bet, @number).returns([5,3])
    @table.expects(:config).at_least_once.returns(@table_config)

    assert_raise RuntimeError do
      @cool_bet.validate(player_bet, bet_amount)
    end
  end

  def test_all_validations_pass
    player_bet = mock('player_bet')
    player = mock('player')
    player.expects(:has_bet?).with(CrapsBetTest::CoolBet, @number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    bet_amount = 10
    @table.expects(:min_bet).returns(bet_amount).at_least_once
    @table.expects(:max_bet).returns(bet_amount+1).at_least_once

    @table_config.expects(:payoff_odds).at_least_once.with(@cool_bet, @number).returns([7,2])
    @table.expects(:config).at_least_once.returns(@table_config)

    @cool_bet.validate(player_bet, bet_amount)

  end
end
