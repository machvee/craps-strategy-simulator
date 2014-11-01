ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/setup'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...


  def mock_bet_setup(bet_class, number=nil, pay_off=[1,1])
    @table = mock('table')
    @number = number
    @table_config = mock('table_config')
    @table.expects(:config).at_least_once.returns(@table_config)
    @table_config.expects(:payoff_odds).at_least_once.returns(pay_off)
    bet_class.new(@table, number)
  end

  def assert_outcome_won(bet)
    assert_equal CrapsBet::Outcome::WIN, bet.outcome
  end

  def assert_outcome_lost(bet)
    assert_equal CrapsBet::Outcome::LOSE, bet.outcome
  end

  def assert_outcome_none(bet)
    assert_equal CrapsBet::Outcome::NONE, bet.outcome
  end

  def assert_outcome_morph(bet)
    assert_equal CrapsBet::Outcome::MORPH, bet.outcome
  end

  def mock_state(mockery={})
    table_state = mock('table_state', mockery)
    @table.expects(:table_state).returns(table_state).at_least_once
  end

  def mock_dice(mockery={})
    dice = mock('dice', mockery)
    @table.expects(:dice).returns(dice).at_least_once
    dice
  end

  def make_bet_base_validations_pass(player_bet, bet_amount, number=nil)
    player = mock('player')
    player.expects(:has_bet?).with(@bet.short_name, number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    @bet.expects(:min_bet).returns(bet_amount).at_least_once
    @bet.expects(:max_bet).returns(bet_amount*100).at_least_once

    @table_config = mock('table_config')
    @table_config.expects(:payoff_odds).at_least_once.with(@bet, number).returns([1,1])
    @table.expects(:config).at_least_once.returns(@table_config)
  end

end


