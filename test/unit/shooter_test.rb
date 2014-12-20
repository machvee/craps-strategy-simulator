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
    assert_equal 0, @shooter.num_rolls
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

  def test_roll_needs_shooter
    assert_raises(RuntimeError) do 
      @shooter.roll
    end
  end

  def test_early_done_raises
    assert_raises(RuntimeError) do 
      @shooter.done
    end
  end

  def test_shooter_roll_and_history_across_players
    roll_some(11,7)
    chk_hist = 43
    assert_equal @last_rolls[-chk_hist, chk_hist], @shooter.last_rolls(chk_hist)
  end

  def test_reset
    roll_some(12,8)
    assert_equal 5, @shooter.last_rolls(5).length

    @shooter.reset
    assert_equal 0, @shooter.num_rolls
    assert @shooter.last_rolls(10).empty?
    assert @shooter.dice.nil?
    assert @shooter.player.nil?
  end

  def test_stats_access
    roll_some(5,5)
    assert @shooter.dice_stats.rolled_2.total >= 0
    assert @shooter.dice_stats.rolled_3.total >= 0
    assert @shooter.dice_stats.rolled_7.total >= 0
    assert @shooter.dice_stats.rolled_8.total >= 0
  end

  private

  def roll_some(num_rolls_per_shooter, num_shooters)
    @last_rolls = []
    num_shooters.times do
      @shooter.set
      num_rolls_per_shooter.times {@last_rolls << @shooter.roll}
      @shooter.done
    end
    assert_equal num_rolls_per_shooter * num_shooters, @shooter.total_rolls
  end
end

