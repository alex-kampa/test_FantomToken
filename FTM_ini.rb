require "Ethereum.rb"
require "eth"


require_relative "./lib/utils.rb"


require_relative "./lib/Sot.rb"

##

@contract_address = "0x5d0D003e43d945FaF5F949177760DFb0D94Cd45d"

##

@token = 'FTM'
@name = 'FantomToken'

@wallet_account     = '0xF895b6041f3953B529910bA5EC50eC9a3320DC5a'
@admin_account      = '0xDF8f647384Ed63AA931B3C509cC07c658bD45d00'
@redemption_account = '0x95f928D6DbF46B9aCa73782485fe912e1a9A3bC6'


@admin_key = Eth::Key.new priv: '27006809b24c2d2bc27e2b3fb929830843ac5ead81b3d8d15d83d60934b46025'

# ini variables

# @E6, @E18, @DAY  = 10**6, 10**18, 24 * 60 * 60
@E6, @E18, @DAY  = 10**18, 10**18, 24 * 60 * 60

# ini simple log

@sl = SimpleLog.new({:verbose => true})
@sl.p Time.now.utc

# test accounts

@acts = JSON.parse(File.read("acc/#{@token}.full.json"))

# variables and mappings

@vars = %w[
at_now
wallet
owner
date_main_start
date_main_end
date_limit
tokens_per_eth
token_total_supply
token_main_cap
tokens_tradeable
number_whitelisted
tokens_minted
tokens_main
total_eth_contributed
available_to_mint
first_day_token_limit
is_migration_phase_open
]

@maps = %w[
get_balance
balance_of
balances_minted
balances_main
eth_contributed
whitelist
locked_tokens
unlocked_tokens
]

@types = {
  'get_balance'    => :ether,
  'balance_of'    => :ether,
  'at_now'         => :date,
  'tokens_per_eth' => :ether,
  'minimum_contribution' => :ether,
  'first_day_limit_presale' => :ether,
  'first_day_limit_main' => :ether,
  'token_total_supply' => :ether,
  'token_minting_cap' => :ether,
  'token_presale_cap' => :ether,
  'token_main_cap' => :ether,
  'tokens_minted' => :ether,
  'tokens_presale' => :ether,
  'tokens_main' => :ether,
  'total_eth_contributed' => :ether,
  'available_to_mint' => :ether,
  'tokens_tradeable' => :bool,
  'eth_contributed' => :ether,
  'balances_presale_before_bonus' => :ether,
}

# @types = {}

# ini contract and owner key

@client = Ethereum::HttpClient.new('http://127.0.0.1:8545')
@contract_abi = File.read('abi/abi.txt')
# @contract = Ethereum::Contract.create(client: @client, name: @name, address: @contract_address, abi: @contract_abi)
@owner_key = Eth::Key.new priv: 'b0f1974b7ac16b84be3e1489775ccd76779c9a063121dc5cf6c742cc51fbbf93'

@sot = Sot.new(
  {
  :client  => @client,
  :name    => @name,
  :address => @contract_address,
  :abi     => @contract_abi,
  :own_key => @owner_key,
  :sl      => @sl,
  :acts    => @acts,
  :vars    => @vars,
  :maps    => @maps,
  :types   => @types,
  :test_nr => @test_nr,
  :decimals => 18
  }
)
sot = @sot

@a  = @sot.a
@h  = @sot.h
@lk = @sot.lk
@k  = @sot.k

# sot.get_state
#
# sot.call [ 'e:get_balance', @a[300] ]
# sot.call [ 'balance_of', @a[300] ]
#
#output_pp(@sot.get_state(true), 'state.txt')


###############################################################################

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

def jump_to(epoch, label)
  @sot.txt "Jump to: " + label
  @sot.own :set_test_time, epoch
  @sot.exp :at_now, epoch
  @sot.do
end

@tokens_per_eth = @sot.var :tokens_per_eth
@end = @sot.var :date_main_end

def get_token_amount(eth)
  tokens = eth * @tokens_per_eth * @E6
  return tokens.to_i
end

def t(eth)
  return get_token_amount(eth)
end

def b(eth)
  x = get_token_amount(eth) * 15 / 100
  return x.to_i
end

def tb(eth)
  return t(eth) + b(eth)
end

def d(i)
  return i*24*3600
end

def e(eth)
  return eth*@E18
end

