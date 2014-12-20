class PlayerStats
  attr_reader   :player
  attr_reader   :bet_stats
  attr_reader   :dice_stats # keep stats on numbers rolled
  attr_reader   :shooter_stats

  delegate :table, :money, to: :player

  def initialize(player, start_capital)
    @player = player

    @bet_stats = table.player_bet_stats.new_child_instance("#{player.name}'s bet stats")
    @dice_stats = table.shooter.dice_stats.new_child_instance("#{player.name}'s shooter stats")
    @shooter_stats = ShooterStats.new
  end

  def up_down
    ud = player.rail.net
    sign = ud == 0 ? '' : (ud < 0 ? '-' : '+')
    "#{sign}$#{ud.abs}"
  end

  def total_wagers
    bet_stats.counter_sum(:made)
  end

  def total_money_won
    bet_stats.counter_sum(:won)
  end

  def total_money_lost
    bet_stats.counter_sum(:lost)
  end

  def print
    puts "#{player.name} stats for table '#{table.name}' - #{Time.now.to_s(:db)}"
    puts "\n"
    puts player.inspect
    puts "\n"
    puts "start $: #{player.rail.start_balance}"
    puts "hi    $: #{player.rail.hi_balance}"
    puts "low   $: #{player.rail.lo_balance}"
    puts "\n"
    puts "wagers: $#{total_wagers}"
    puts "wins:   $#{total_money_won}"
    puts "losses: $#{total_money_lost}"
    puts "\n"
    bet_stats.print
    puts "-"*80
    dice_stats.print
    puts "-"*80
    shooter_stats.print
    return
  end

  def inspect
    print
  end

  def reset
    bet_stats.reset
    dice_stats.reset
    shooter_stats.reset
  end

end
