class PlayerStats
  attr_reader   :player
  attr_reader   :bet_stats
  attr_reader   :roll_stats # when the player is the shooter

  delegate :table, :money, to: :player

  def initialize(player, start_capital)
    @player = player

    @bet_stats = table.player_bet_stats.new_child_instance("#{player.name}'s bet stats")
    @roll_stats = table.shooter.roll_stats.new_child_instance("#{player.name}'s shooter stats")
  end

  def up_down
    ud = money - player.rail.start_balance
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
    roll_stats.print
    return
  end

  def inspect
    print
  end

  def reset
    @bet_stats.reset
    @roll_stats.reset
  end

end
