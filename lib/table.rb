class Table
  attr_reader    :name
  attr_reader    :craps_bets
  attr_reader    :bet_stats
  attr_reader    :state
  attr_reader    :config
  attr_reader    :dice_tray
  attr_reader    :players
  attr_reader    :shooter      # one of the above players or nil
  attr_reader    :last_shooter # one of the above players or nil
  attr_reader    :house   # dollar amount of chips the house has
  attr_accessor  :quiet_table # not verbose about all actions

  delegate :on?, :off?, to: :state
  delegate :dice, to: :shooter
  delegate :min_bet, :max_bet, to: :config

  DEFAULT_OPTIONS = {
    config:      TableConfig.new,
    die_seeder:  nil,
    quiet_table: false
  }

  def initialize(name="craps table", options = DEFAULT_OPTIONS)
    @name = name
    @config = options[:config]

    @state = TableState.new(self)
    state.table_off

    @house = config.house_bank
    @quiet_table = options[:quiet_table]

    @dice_tray = DiceTray.new(self, options[:die_seeder])

    @bet_stats = TableStatsCollection.new("bet result", self)
    create_craps_bets

    @players = []
    @last_shooter = @shooter = nil
  end

  def last_roll
    dice.value
  end

  def max_odds(number)
    config.max_odds(number)
  end

  def play(quiet_option=quiet_table)
    #
    # one roll of the dice, and the outcomes
    #
    quietly?(quiet_option) do
      # 1. shooter rolls dice
      # 2. set table state if on
      # 3. table pay players on winning bets, takes losing bets
      # 4. if 7-out, shooter will return_dice
      #
      shooter_rolls
      settle_bets
      state.update
    end
    return
  end

  def play_points(number_of_points, quiet_option=quiet_table)
    #
    # roll as many times from as many shooters as it takes
    # to make and end number_of_points points
    #
    start_points = bet_stats.points
    while (bet_stats.points - start_points < number_of_points)
      play(quiet_option)
    end
    #
    # play until points_made or seven_outs
    #
    start_seven_out = bet_stats.seven_outs
    start_points_made = bet_stats.points_made
    while(bet_stats.seven_outs == start_seven_out &&
          bet_stats.points_made == start_points_made)
      play(quiet_option)
    end
    return
  end

  def new_player(name, start_amount)
    p = Player.new(name, self, start_amount)
    @players << p
    p # good luck
  end

  def find_player(name)
    players.find {|p| p.name == name}
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

  def reset_stats
    dice_tray.roll_stats.reset
    bet_stats.reset
  end

  def credit(amount)
    # the sound of a player losing a bet
    @house += amount
  end

  def debit(amount)
    @house -= amount
  end

  def shooter_rolls
    set_shooter
    shooter.roll
    announce_roll
    dice_tray.roll_stats.update
  end

  def set_shooter
    #
    # if shooter.nil?, need to set the @shooter using
    # the last_shooter plus one player position, or back to 0
    # if last_shooter is nil or at end of players array
    #
    return unless shooter.nil?
    if !players_ready?
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
      shooter.dice = dice_tray.take_dice
    end
    shooter
  end

  def shooter_done
    shooter.return_dice
    @shooter = nil
  end

  def status(str)
    puts(str) unless quiet_table
  end

  def announce_roll
    status 'roll %d: %2d %s %s' %
              [dice.num_rolls, last_roll, dice.inspect, state.stickman_calls_roll]
  end

  def find_craps_bet(bet_class, number)
    craps_bets.find {|bet| bet.class == bet_class && bet.number == number}
  end

  def inspect
    puts name unless name.nil?
    puts "ON (point is #{point})" if on? 
    puts "OFF" if off? 
    puts "total rolls: #{dice_tray.roll_stats.total_rolls}\n"
    bet_stats.print
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

  def quietly?(option)
    save_state = quiet_table
    @quiet_table = option
    yield
    @quiet_table = save_state
    return
  end

end
