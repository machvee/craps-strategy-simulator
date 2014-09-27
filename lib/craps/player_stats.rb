class PlayerStats
  attr_reader   :player
  attr_reader   :start_bank
  attr_reader   :hi_bank
  attr_reader   :lo_bank
  attr_reader   :bet_stats
  attr_reader   :roll_stats # when the player is the shooter

  delegate :table, :money, to: :player

  def initialize(player, start_bank)
    @player = player

    @start_bank = start_bank
    @hi_bank = start_bank
    @lo_bank = start_bank

    @bet_stats = table.player_bet_stats.new_child_instance("#{player.name}'s bet stats")
    @roll_stats = table.shooter.roll_stats.new_child_instance("#{player.name}'s shooter stats")
  end

  def keep_bank_stats
    @hi_bank = money if hi_bank < money
    @lo_bank = money if lo_bank > money
  end

  def up_down
    ud = money - start_bank
    sign = ud == 0 ? '' : (ud < 0 ? '-' : '+')
    "#{sign}$#{ud.abs}"
  end

  def print
    puts "#{player.name} stats for table '#{table.name}' - #{Time.now.to_s(:db)}"
    puts "\n"
    puts "start $: #{start_bank}"
    puts "hi    $: #{hi_bank}"
    puts "low   $: #{lo_bank}"
    puts "\n"
    bet_stats.print
    puts "-"*80
    roll_stats.print
  end

end
