require 'test_helper'

class ShooterTest < ActiveSupport::TestCase
  def setup
    @table = Table.new('test')
    @players = []
    @num_players = 6
    @num_players.times { |i| @players << @table.new_player("player_#{i}", 1000)}
    @shooter = @table.shooter
  end

  def test_table_shooter_attributes
    assert @shooter.present?
    assert @shooter.player.nil?
    assert_equal 0, @shooter.total_rolls
  end

  def test_set_done
    @players.each do |cur_player|
      player = @shooter.set
      assert_equal cur_player, player
      @shooter.done
    end
    player = @shooter.set
    assert_equal @players.first, player
    @shooter.done
  end
end

