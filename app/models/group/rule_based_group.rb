class Group
  class RuleBasedGroup < Group


    ####################################
    #
    # Delegation
    #
    ####################################

    delegate :member_ids, to: :memcache_facade

  end
end
