ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/setup'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...


  def mock_bet_setup(bet_class, number=nil)
    @table = mock('table')
    @bet_stats = mock('bet_stats')
    @bet_stats.expects(:add).at_least_once
    @table.expects(:bet_stats).at_least_once.returns(@bet_stats)
    bet_class.new(@table, number)
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
    player.expects(:has_bet?).with(@bet.class, number).returns(false).once
    player_bet.expects(:player).at_least_once.returns(player)

    @bet.expects(:min_bet).returns(bet_amount).at_least_once
    @bet.expects(:max_bet).returns(bet_amount*100).at_least_once

    @table_config = mock('table_config')
    @table_config.expects(:payoff_odds).at_least_once.with(@bet, number).returns([1,1])
    @table.expects(:config).at_least_once.returns(@table_config)
  end

end


