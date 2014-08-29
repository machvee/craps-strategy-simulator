require 'dice'
require 'bets/craps_bet'
require 'player'
require 'table_config'
require 'craps_lingo'
require 'roll_stats'
require 'craps_stats'

require 'bets/ce_bet'
require 'bets/come_bet'
require 'bets/come_odds_bet'
require 'bets/come_out_bet'
require 'bets/field_bet'
require 'bets/hardways_bet'
require 'bets/pass_line_bet'
require 'bets/pass_odds_bet'
require 'bets/place_bet'

require 'player_bet'

class Table
  attr_reader    :name
  attr_reader    :play_state
  attr_reader    :table_state
  attr_reader    :craps_bets
  attr_reader    :roll_stats
  attr_reader    :craps_stats
  attr_reader    :config
  attr_reader    :point # off? => nil, on? => 4,5,6,8,9,10
  attr_reader    :tray  # 8 dice
  attr_reader    :dice  # 2 dice the player has selected
  attr_reader    :players
  attr_reader    :shooter      # one of the above players or nil
  attr_reader    :last_shooter # one of the above players or nil
  attr_reader    :house   # dollar amount of chips the house has
  attr_accessor  :quiet_table # not verbose about all actions

  include CrapsLingo

  PLAY_STATES = {:on => true, :off => false}
  NUM_TRAY_DIE=8
  NUM_SHOOTER_DIE=2
  HOUSE_BANK=10000000

  def initialize(name=nil, config=TableConfig.new, seed=nil, quiet_table=false)
    set_table_off
    @name = name
    @quiet_table = quiet_table
    @point = nil
    @tray = Dice.new(NUM_TRAY_DIE, seed)
    @dice = nil
    @players = []
    @last_shooter = @shooter = nil
    @house = HOUSE_BANK
    @config = config
    @roll_stats = RollStats.new(self)
    @craps_stats = CrapsStats.new(self)
    create_craps_bets
  end

  def play(quiet_option=quiet_table)
    quietly(quiet_option) do
      # 1. shooter rolls dice
      # 2. set table state if on
      # 3. table pay players on winning bets, takes losing bets
      # 4. if 7-out, shooter will return_dice
      #
      roll
      settle_bets
      update_table_state
    end
    return
  end

  def play_points(number_of_points, quiet_option=quiet_table)
    start_points = craps_stats.points
    while (craps_stats.points - start_points < number_of_points)
      play(quiet_option)
    end
    #
    # play until points_made or seven_outs
    #
    start_seven_out = craps_stats.seven_outs
    start_points_made = craps_stats.points_made
    while(craps_stats.seven_outs == start_seven_out &&
          craps_stats.points_made == start_points_made)
      play(quiet_option)
    end
    return
  end

  def quietly(option)
    save_state = quiet_table
    @quiet_table = option
    yield
    @quiet_table = save_state
    return
  end

  def new_player(name, start_amount)
    p = Player.new(name, self, start_amount)
    @players << p
    p
  end

  def take_dice(offsets=[0,1])
    @dice = tray.extract(offsets)
  end

  def dice_value_range
    take_dice
    r = dice.value_range
    return_dice
    r
  end

  def return_dice
    tray.join(dice)
    @dice = nil
  end

  def players_ready?
    #
    # return true if one or more @players are at the table and want to bet, else false
    #
    @players.each do |player|
      if player.out?
        player.leave_table
        players.delete(player)
      end
    end
    return !players.empty?
  end

  def settle_bets
    all_bets do |player_bet|
      player = player_bet.player
      craps_bet = player_bet.craps_bet

      outcome = player_bet.determine_outcome

      case outcome
        when CrapsBet::Outcome::RETURN
          #
          # 1. player moves bet amount from wagers to rail
          # 2. player removes bet
          #
          player.wagers_to_rail(player_bet.amount)
          player.remove_bet(player_bet)
          status "#{player.name} returned #{player_bet.amount} for #{player_bet}"
        when CrapsBet::Outcome::WIN
          #
          # 1. table credits player rails with winnings amount
          # 2. bet stays in place
          #
          pay_this, for_every = config.payoff_odds(craps_bet, player_bet.number)
          winnings = (player_bet.amount/for_every) * pay_this
          debit(winnings)
          player.to_rail(winnings)
          status "#{player.name} wins $#{winnings} on #{player_bet}"
          player.take_down(player_bet) unless craps_bet.bet_remains_after_win?
        when CrapsBet::Outcome::LOSE
          #
          # table takes bet amount from player's wagers to house
          # player removes bet
          #
          credit(player_bet.amount)
          player.loses(player_bet)
          status "#{player.name} loses $#{player_bet.amount} on #{player_bet}"
        when CrapsBet::Outcome::NONE
          # bet stays in place
      end
    end
  end

  def all_bets
    players.each do |player|
       player.bets.each do |player_bet|
         yield player_bet
       end
    end
  end

  def find_player(name)
    players.find {|p| p.name == name}
  end

  def credit(amount)
    # the sound of a player losing a bet
    @house += amount
  end

  def debit(amount)
    @house -= amount
  end

  def on?
    play_state == PLAY_STATES[:on]
  end

  def off?
    play_state == PLAY_STATES[:off]
  end

  def last_roll
    dice.value
  end

  def roll
    raise "no shooter" if dice.nil?
    dice.roll
    announce_roll
    roll_stats.update
    craps_stats.update
  end

  def reset_stats
    roll_stats.reset
    craps_stats.reset
  end

  def max_odds(number)
    config.max_odds(number)
  end

  def max_bet
    config.max_bet
  end

  def min_bet
    config.min_bet
  end

  def set_shooter
    #
    # if shooter.nil?, need to set the @shooter using
    # the last_shooter plus one player position, or back to 0
    # if last_shooter is nil or at end of players array
    #
    return unless shooter.nil?
    if players.empty?
      @last_shooter = @shooter = nil
      raise "there are no players"
    else
      if last_shooter.nil?
        ns = 0
      else
        ns = players.index(last_shooter) + 1
        ns = 0 if (ns == players.length)
      end
      @last_shooter = @shooter = players[ns]
      take_dice
    end
    @shooter
  end

  def update_table_state
    if point_established?
      set_table_on
    elsif point_made? || seven_out?
      set_table_off
    end
  end

  def set_table_on
    @play_state = PLAY_STATES[:on]
    @point = last_roll
  end

  def set_table_off
    @play_state = PLAY_STATES[:off]
    @point = nil
  end

  def shooter_done
    @shooter = nil
    return_dice
  end

  def status(str)
    puts(str) unless quiet_table
  end

  def announce_roll
    status 'roll %d: %2d %s %s' %
              [dice.num_rolls, last_roll, dice.inspect, stickman_says]
  end

  def find_craps_bet(bet_class, number)
    craps_bets.find {|bet| bet.class == bet_class && bet.number == number}
  end

  def inspect
    puts name unless name.nil?
    puts "ON (point is #{point})" if on? 
    puts "OFF" if off? 
    puts "total rolls: #{roll_stats.total_rolls}\n"
    craps_stats.print
  end

  private

  def create_craps_bets
    @craps_bets = []
    @craps_bets << PassLineBet.new(self)
    @craps_bets << ComeOutBet.new(self)
    @craps_bets << CeBet.new(self)
    @craps_bets << FieldBet.new(self)
    [PassOddsBet, ComeBet, ComeOddsBet, PlaceBet, HardwaysBet].each do |bet_class|
      @craps_bets += bet_class.gen_number_bets(self)
    end
  end

end
