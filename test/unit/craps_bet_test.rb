require 'test_helper'

class CrapsBetTest < ActiveSupport::TestCase
  class CoolBet < CrapsBet
    def name
      "Cool Bet on #{number}"
    end

    def outcome
      if table.win?
        Outcome::WIN
      elsif table.lose?
        Outcome::LOSE
      else
        Outcome::NONE
      end
    end
  end

  def setup
    @cool_bet = setup_cool(2, [20,1])
    @won_stat_name = 'craps_test/cool_2'
    @dice = mock('dice')
  end

  def setup_cool(number, payoff_odds)
    @number = number
    @table_config = mock('table_config')
    @table = mock('table')
    @state = mock('table_state')
    @table.expects(:config).at_least_once.returns(@table_config)
    @table_config.expects(:payoff_odds).at_least_once.returns(payoff_odds)
    bet = CoolBet.new(@table, @number)
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
    @table.expects(:table_state).at_least_once.returns(@state)
    @state.expects(:on?).returns(false).once
    assert !@cool_bet.on?, "bet should be off because table is off"
    @state.expects(:on?).returns(true).once
    assert @cool_bet.on?, "bet should be on because table is on"
  end

  def test_bet_payout
    @table.expects(:config).at_least_once.returns(@table_config)
    assert_equal [20,1], @cool_bet.payout
  end

  def test_rolled_the_number
    @dice = mock_dice
    @dice.expects(:rolled?).with(@number).returns(true)
    assert @cool_bet.rolled_the_number?, "dice.value is #@number, should've made the number"
    @dice.expects(:rolled?).with(@number).returns(false)
    assert !@cool_bet.rolled_the_number?, "dice.value is not #@number, shouldn't have made the number"
  end

  def test_determine_outcome_winning
    @table.expects(:win?).returns(true)
    assert_equal CrapsBet::Outcome::WIN, @cool_bet.outcome
  end

  def test_determine_outcome_losing
    @table.expects(:lose?).returns(true)
    @table.expects(:win?).returns(false)
    assert_equal CrapsBet::Outcome::LOSE, @cool_bet.outcome
  end

  def test_determine_outcome_none
    @table.expects(:lose?).returns(false)
    @table.expects(:win?).returns(false)
    assert_equal CrapsBet::Outcome::NONE, @cool_bet.outcome
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
    @cool_bet.expects(:min_bet).returns(bet_amount + 1).at_least_once

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
    @cool_bet.expects(:min_bet).returns(bet_amount).at_least_once
    @cool_bet.expects(:max_bet).returns(bet_amount-1).at_least_once

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
    @cool_bet.expects(:min_bet).returns(bet_amount).at_least_once
    @cool_bet.expects(:max_bet).returns(bet_amount+1).at_least_once

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
    @cool_bet.expects(:min_bet).returns(bet_amount).at_least_once
    @cool_bet.expects(:max_bet).returns(bet_amount+1).at_least_once

    @table_config.expects(:payoff_odds).at_least_once.with(@cool_bet, @number).returns([7,2])
    @table.expects(:config).at_least_once.returns(@table_config)

    @cool_bet.validate(player_bet, bet_amount)

  end
end
