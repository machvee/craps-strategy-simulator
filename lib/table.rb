class Table
  attr_reader    :name
  attr_reader    :table_bets
  attr_reader    :bet_stats
  attr_reader    :table_state
  attr_reader    :config
  attr_reader    :dice_tray
  attr_reader    :players
  attr_reader    :shooter # one of the above players or nil
  attr_reader    :house   # dollar amount of chips the house has
  attr_accessor  :quiet_table # not verbose about all actions

  delegate :on?, :off?,        to: :table_state
  delegate :dice,              to: :shooter
  delegate :min_bet, :max_bet, to: :config

  NO_NUMBER_BETS = [
    AceDeuceBet,
    AcesBet,
    AnyCrapsBet,
    AnySevenBet,
    CeBet,
    ComeOutBet,
    ElevenBet,
    FieldBet,
    PassLineBet,
    TwelveBet
  ]

  NUMBER_BETS = [
    ComeBet,
    ComeOddsBet,
    HardwaysBet,
    PassOddsBet,
    PlaceBet
  ]

  DEFAULT_OPTIONS = {
    config:      TableConfig.new,
    die_seeder:  nil,
    quiet_table: false
  }

  BET_STATS_HEADERS = {
    master_count: 'total',
    occurred: 'won',
    consec_occurred: 'consec won',
    did_not_occur: 'lost',
    consec_did_not_occur: 'consec lost'
  }


  def initialize(name="craps table", options = DEFAULT_OPTIONS)
    @name = name
    @config = options[:config]

    @table_state = TableState.new(self)
    table_state.table_off

    @house = config.house_bank
    @quiet_table = options[:quiet_table]

    @dice_tray = DiceTray.new(self, options[:die_seeder])

    @bet_stats = TableStatsCollection.new("bet result", self)
    create_table_bets

    @players = []
    @shooter = Shooter.new(self)
  end

  def last_roll
    shooter.dice.value
  end

  def total_rolls
    shooter.total_rolls
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
      # 2. set table_state if on
      # 3. table pay players on winning bets, takes losing bets
      # 4. if 7-out, shooter will return_dice
      #
      raise "no players" unless players_ready?
      players_make_your_bets
      raise "place your bets" unless at_least_one_bet_made?
      shooter_rolls
      settle_bets
      table_state.update
    end
    return
  end

  def players_make_your_bets
    players.each do |p|
      p.play_strategy
    end
  end

  def play_points(number_of_points, quiet_option=quiet_table)
    #
    # roll as many times from as many shooters as it takes
    # to make and end number_of_points points
    #
    start_points = bet_stats.point_made
    while (bet_stats.point_made - start_points < number_of_points)
      play(quiet_option)
    end
    #
    # play until point_made or seven_outs
    #
    start_seven_out = seven_outs
    start_point_made = bet_stats.point_made
    while(seven_outs == start_seven_out && bet_stats.point_made == start_point_made)
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
    table_bets.each do |table_bet|

      outcome, stats_hash = table_bet.determine_outcome

      bet_stats.update_from_hash(stats_hash)

      table_bet.player_bets.each do |player_bet|
        #
        # if a player can mark a bet off and has it off, its just skipped as if its not there
        #
        next if player_bet.off?

        case outcome
          when TableBet::Outcome::RETURN
            return_was_off(player_bet)

          when TableBet::Outcome::WIN
            pay_winning(player_bet)

          when TableBet::Outcome::LOSE
            take_losing(player_bet)

          when TableBet::Outcome::COME
            player_bet.morph_bet(ComeBet, last_roll)

          when TableBet::Outcome::NONE
            # bet stays in place
        end

        player_bet.update_player_bet_stats_from_hash(stats_hash)

      end
    end
    remove_marked_bets
  end

  def at_least_one_bet_made?
    players.any? {|p| p.bets.length > 0}
  end

  def all_bets
    players.each do |player|
       player.bets.each do |player_bet|
         yield player_bet
       end
    end
  end

  def reset_stats
    shooter.reset_stats
    bet_stats.reset
  end

  def house_credit(amount)
    # the sound of a player losing a bet
    @house += amount
  end

  def house_debit(amount)
    @house -= amount
  end

  def shooter_rolls
    shooter.set
    shooter.roll
    announce_roll
  end

  def status(str)
    puts(str) unless quiet_table
  end

  def announce_roll
    status '%d: %s rolls: %2d %s %s' %
      [shooter.dice.num_rolls,
       shooter.player.name,
       last_roll,
       shooter.dice.inspect,
       table_state.stickman_calls_roll]
  end

  def find_table_bet(bet_class, number)
    table_bets.find {|bet| bet.class == bet_class && bet.number == number} ||
      raise("#{bet_class}%s isn't a valid bet" % (number.nil? ? '' : " #{number}"))
  end

  def inspect
    puts name unless name.nil?
    puts "ON (point is #{table_state.point})" if on? 
    puts "OFF" if off? 
    puts "rolls: #{total_rolls}"
    bet_stats.print(BET_STATS_HEADERS)
  end

  private

  def remove_marked_bets
    players.each do |player|
      player.remove_marked_bets
    end
  end

  def return_was_off(player_bet)
    status "#{player_bet.player.name} returned #{player_bet.amount} for #{player_bet}"
    player_bet.return_bet
  end

  def pay_winning(player_bet)
    #
    # table credits player rail with winning amount
    #
    winnings = player_bet.pay_winning_bet
    status "#{player_bet.player.name} wins $#{winnings} on #{player_bet}"
    house_debit(winnings)
  end

  def take_losing(player_bet)
    #
    # table takes bet amount from player's wagers to house
    # player removes bet
    #
    amount = player_bet.amount
    status "#{player_bet.player.name} loses $#{amount} on #{player_bet}"
    player_bet.losing_bet
    house_credit(amount)
  end

  def create_table_bets
    @table_bets = []
    NO_NUMBER_BETS.each do |bet_class|
      @table_bets << bet_class.new(self)
    end

    NUMBER_BETS.each do |bet_class|
      @table_bets += bet_class.gen_number_bets(self)
    end
  end

  def seven_outs
    bet_stats.point_made(OccurrenceStat::DID_NOT_OCCUR)
  end

  def quietly?(option)
    save_state = quiet_table
    @quiet_table = option
    yield
    @quiet_table = save_state
    return
  end

end
