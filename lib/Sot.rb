require "Ethereum.rb"
require "eth"
require 'duplicate'

require_relative "utils"

class Sot

  attr_reader :contract, :client, :name, :address, :abi, :owner_key, :a, :h, :lk, :k, :history, :errors, :sl
  
  attr_accessor :test_nr

  @@ether = 10**18

  def initialize(h)

    # basic contract info
    @client    = h[:client]
    @name      = h[:name]
    @address   = h[:address]
    @abi       = h[:abi]
    @decimals  = h[:decimals]
    
    # default key for transactions
    @owner_key = h[:own_key]

    # we also need to keep track of key changes
    @last_key = nil

    # initialise @contract
    contract(@owner_key)

    # smart contract variables and mappings
    @vars      = h[:vars]
    @maps      = h[:maps]
    @types     = h[:types]

    # log
    @sl        = h[:sl]     
    
    # maximum  number of accounts used
    @imax = h.has_key?(:imax) ? h[:imax] : 20

    # show change in state after a submit
    @show_changes = h.has_key?(:show_changes) ? h[:show_changes] : true

    # users / addresses
    @acts      = h[:acts]

    @a  = [] # adr
    @h  = [] # hex
    @lk = {} # lookup address => i
    @k  = [] # key

    (1..@imax).each do |i|
      adr = @acts[i]['adr']
      @a[i] = adr
      @k[i] = @acts[i]['hex']
      @lk[adr] = i
      @k[i] = Eth::Key.new priv: @acts[i]['hex']
    end

    @sl.h2 "Contract #{@contract.call.name} initialized" 
    @sl.p  "At address " + @address

    @scale = {
#      'balance_of' => 10**6,
#      'e:get_balance' => 10**18
    }
    
    @E18 = 10 ** 18
    @EXX = 10 ** @decimals
    
    # data structures to hold processing info and current batch information
    
    @batch = {
      :txt => '',
      :actions => [],
      :expect => []
    }

    @history = [ { :batch => duplicate(@batch), :state => get_state(), :diff => [] } ]
    
    # error counter
    
    @test_nr = h[:test_nr]
    @errors = 0
	
  end

  def dump
    @sl.p "\nErrors found: " + @errors.to_s + "\n"
    @sl.p Time.now.utc
    write_to_file @sl.sLog, "sLog_#{@test_nr}.log"
  end

  # ---------------------------------------------------------------------------
  #
  # Create / update contract
  #
  # the contract must be re-initialised when changing keys (reason unknown)
  
  def change_owner_key(key)
    @sl.p "\nChanging owner key to: " + key.to_s + "\n"
    @owner_key = key
    contract()
  end
  
  def contract(key=@owner_key)
    return @contract if key == @last_key
    @contract = Ethereum::Contract.create(client: @client, name: @name, address: @address, abi: @abi)
    @contract.key = key
    @last_key = key
    return @contract
  end

  def contract_refresh(key=@owner_key)
    @contract = Ethereum::Contract.create(client: @client, name: @name, address: @address, abi: @abi)
    @contract.key = key
    @last_key = key
    return @contract
  end

  # ---------------------------------------------------------------------------
  #
  # Utilities
  #

  def strip0x(s)
    s.clone.sub!(/^0x/, '').downcase
  end

  def comma_numbers(number, delimiter = ',')
    res = number.to_i.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1#{delimiter}").reverse
    res += '.' + (number - number.to_i).to_s.split('.')[1] if (number - number.to_i > 0)
    return res
  end

  def type_of(function)

    type = nil
    
    if    @types.has_key?(function) then type = @types[function]
    elsif (function =~ /date/)   then type = :date
    elsif (function =~ /ether/)  then type = :ether
    elsif (function =~ /wallet/) then type = :address     
    elsif (function =~ /token/)  then type = :token
    end
  
    return type

  end

  # ---------------------------------------------------------------------------
  #
  # Utilities to simplify calls
  #

  def bal(i=nil)
    return call [ :get_balance, @address ] if i.nil?
    return call [ :get_balance, @a[i] ]
  end

  def var(f, i=nil)
    return call f.to_sym if i.nil?
    return call [ f.to_sym, @a[i] ]
  end

  # ---------------------------------------------------------------------------
  #
  # Batch functions
  #
  
  def txt(s)
    @batch[:txt] = s
  end
  
  def snd(k, x)
    key = k.is_a?(Integer) ? @k[i] : k
    @batch[:actions] << [:contribute, key, x]
  end
  
  def own(f, *args)
    @batch[:actions] << [f.to_sym, @owner_key] + args
  end  
  
  def add(f, *args)
    key = args[0].is_a?(Eth::Key) ? args.shift : nil
    @batch[:actions] << [f.to_sym, key] + args
  end
  
  def exp(*args)
    # args.insert(1, nil) unless @maps.include?(args[0].to_s)
	  args.insert(1, nil) unless ( (args[1].is_a?(String) && args[1] =~ /^0x/) || args[1].kind_of?(Array) )
    @batch[:expect] << args
  end

  # ---------------------------------------------------------------------------
  #
  # State and difference
  #

  def get_state(fmt=false, imax=@imax)
  
    h = {
      :eth => 0,
      :vars => {},
      :acts => {} 
    }
  
    h[:eth] = call [ :get_balance, @address, fmt ]
    
    @vars.each do |var|
      h[:vars][var] = call [ var, nil, fmt ]
    end
    
    (1..imax).each do |i|
      h[:acts][i] = {}
      # h[:acts][i][:eth] = call [ :get_balance, @a[i], fmt ]
      @maps.each do |map|
        h[:acts][i][map] = call [ map, @a[i], fmt ]
      end
    end
    
    return h
  
  end
    
  def diff_state(h1, h2, imax=@imax)
  
    diff = []
    
    v1, v2 = h1[:eth], h2[:eth]
    if v1 != v2 then
      diff << [ :c, :eth, v1, v2, v2 - v1 ]
    end
    
    @vars.each do |var|
      v1, v2 = h1[:vars][var], h2[:vars][var]
      if v1 != v2 then
        ary = [ :c, var.to_sym, v1, v2 ]
        if (v1.is_a?(Numeric) && v2.is_a?(Numeric)) then
          ary << v2 - v1
        end
        diff << ary
      end
    end    
  
    (1..imax).each do |i|
      @maps.each do |map|
        v1, v2 = h1[:acts][i][map], h2[:acts][i][map]
        if v1 != v2 then
          ary = [ i, map.to_sym, v1, v2 ]
          if (v1.is_a?(Numeric) && v2.is_a?(Numeric)) then
            ary << v2 - v1
          end
          diff << ary
        end
      end
    end
    
    # reformat
    
    diff.each do |a|
      function = a[1].to_s
      if type_of(function) == :ether then
        a[2] = a[2].to_f / @E18
        a[3] = a[3].to_f / @E18
        a[4] = a[4].to_f / @E18
      elsif type_of(function) == :token then
        a[2] = a[2].to_f / @EXX
        a[3] = a[3].to_f / @EXX
        a[4] = a[4].to_f / @EXX
      end
    end
    
    return diff
    
  end

  # ---------------------------------------------------------------------------
  #
  # Submit
  #

  def do()
    contract_refresh()
    do_begin()
    do_end()
  end

  def do_begin()

    vini = []

    # header
    @sl.h2 @batch[:txt]
    
    # load initial values
    @batch[:expect].each { |a| vini << call(a[0..1]) }
	
    # do actions
    @sl.p "\nACTIONS"
    @batch[:actions].each { |a| a[0] == :contribute ? contribute(a) : transact(a) }
    
    @vini = vini
    
  end
  
  def do_end()

    vini, vend = @vini, []
    this_batch = @batch.clone

    # load final values and verify
    @sl.p "\nVERIFY"
    
    @batch[:expect].each_index do |i|
      a = @batch[:expect][i]
      vend << call(a[0..1])
      
      address = a[1]
      address_nr = @lk[address]
      value = a[2]
      diff = a[3]
      comment = a[4]
      
      # normalize
      
      v1, v2 = vini[i], vend[i]
      
      if @scale.has_key?(a[0]) then
        v1 = v1 / @scale[a[0]]
        v2 = v1 / @scale[a[0]]
      end
      
      # readable query
      
      query = "[#{a[0]} acc#{address_nr}]"

      # verify values
      
      if (!value.nil?) then 
        if (v2 == value) then
          @sl.p "ok  val #{query} #{address_nr} is #{value} as expected"
        else
          @sl.p "***ERR*** val #{query} is #{v2} expected #{value}"
          @errors += 1
        end
      end
      
      # verify diff

      if (!diff.nil?) then 
        if (v2.to_i - v1.to_i == diff.to_i) then
          @sl.p "ok  diff #{query} is #{diff} as expected"
        elsif (a[0] == :get_balance && (v2 - v1 - diff).abs < 0.1 * @E18 ) then
          @sl.p "ok  diff #{query} is ≈#{diff} as expected (within 0.1 ether)"
        else 
          @sl.p "***ERR*** diff #{query} is #{v2 - v1} expected #{diff}"
          @errors += 1
        end
      end      
      
    end
    
    # ending state
    
    @sl.p "\nDIFFERENCES"
    
#    puts '---'
#    puts @history.last.inspect
#    puts '---'
    
    h1 = @history.last[:state]
    h2 = get_state()
    sdiff = diff_state(h1, h2)
    if sdiff.length == 0 then
      @sl.p '(no differences found)'
    else
      sdiff.each { |d| @sl.p d }
    end
    
    # update history and reinitialise batch
    
    this_batch[:actions].map! { |a| a[1] = a[1].address; a }
    @history << { :batch => this_batch, :state => h2.clone, :diff => sdiff }
    @batch = { :txt => '', :actions => [], :expect => [] }
    
    
  end

  # ---------------------------------------------------------------------------
  #
  # Contribute (send ether to the contract)
  #

  def contribute(a)
    key = a[1]
    amt = (a[2] * 10**18).to_i
    @sl.p "CONTRIBUTE : @client.transfer(acct_#{a[1]}, #{@address}, #{a[2]})"
    @client.transfer(key, @address, amt)
  end

  # ---------------------------------------------------------------------------
  #
  # Transact (interact with the contract)
  #

  def transact(a)
    begin
      function = a[0].to_s
      contract(a[1])
      parameters = a[2..-1]
      @contract.transact_and_wait.__send__ function, *parameters
    rescue
      puts "===ERROR===411"
      puts function
      puts parameters.inspect
      puts "===ERROR==="
      exit 0
    end
  end
  
  # ---------------------------------------------------------------------------
  #
  # Call (read a value from the contract or the blockchain)
  #

  def call(a)
  
    # puts a.inspect
    
    target = ''
    function = ''
    value = ''
    
    # convert to array
    a = [ a.to_s ] if ( a.is_a?(Symbol) || a.is_a?(String) )
    
    a[0] = a[0].to_s
    
    if a[1].is_a?(String) then
      value = '"' + a[1] + '"'
    elsif a[1].kind_of?(Array) then
	    value = a[1][0]
    else
      value = a[1]
    end
    
    if a[0].to_s =~ /^e_(.*)/ then
      target = 'client'
      function = $1
    elsif a[0].to_s == 'get_balance' then
      target = 'client'
      function = 'get_balance'
    else
      target = 'contract.call'
      function = a[0]
    end
    
    x = nil
    call_type = 0
    
    begin
    
      if a[1] then
        if (target == 'client') then
          call_type = 1
          x = @client.__send__ function, *a[1]
        else
          call_type = 2
          x = @contract.call.__send__ function, *a[1]
        end
      else
        if (target == 'client') then
          call_type = 3
          x = @client.__send__ function
        else
          call_type = 4
          x = @contract.call.__send__ function
        end
      end
    
      #  puts '---'
      #  puts call
      #  puts '---'

      # x = eval call
      
      # return without formatting (default)
      return x unless a[2]
      
      # return with formatting
      type = type_of(function)
    
      x = Time.at(x.to_i).utc          if type == :date
      x = comma_numbers(x.to_f / @E18) if type == :ether
      x = comma_numbers(x.to_f / @EXX) if type == :token
      x += '0x'                        if type == :address
      
      return x

    rescue
      puts "===ERROR==="
      puts call_type
      puts function
      puts a[1].inspect
      puts "===ERROR==="
    end
    
  end

  def call_old(a)
  
    puts a.inspect
    
    target = ''
    function = ''
    value = ''
    
    # convert to array
    a = [ a.to_s ] if ( a.is_a?(Symbol) || a.is_a?(String) )
    
    a[0] = a[0].to_s
    
    if a[1].is_a?(String) then
      value = '"' + a[1] + '"'
    elsif a[1].kind_of?(Array) then
	    value = a[1][0]
    else
      value = a[1]
    end
    
    if a[0].to_s =~ /^e_(.*)/ then
      target = 'client'
      function = $1
    elsif a[0].to_s == 'get_balance' then
      target = 'client'
      function = 'get_balance'
    else
      target = 'contract.call'
      function = a[0]
    end
    
    if a[1] then
      call =  "@#{target}.#{function}(#{value})"
    else
      call =  "@#{target}.#{function}"
    end
    
    #  puts '---'
    #  puts call
    #  puts '---'

    x = eval call
    
    # return without formatting (default)
    return x unless a[2]
    
    # return with formatting
    type = type_of(function)
  
    x = Time.at(x.to_i).utc          if type == :date
    x = comma_numbers(x.to_f / @E18) if type == :ether
    x = comma_numbers(x.to_f / @EXX) if type == :token
    x += '0x'                        if type == :address
    
    return x
    
  end
  
end